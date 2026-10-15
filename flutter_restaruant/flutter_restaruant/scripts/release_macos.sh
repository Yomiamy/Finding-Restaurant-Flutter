#!/usr/bin/env bash
#
# release_macos.sh
# macOS 手動發布輔助腳本（Developer ID 簽章、DMG 打包、Notarization 公證與 Stapling 裝訂）
#
set -eo pipefail

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# 取得專案根目錄 (包含 pubspec.yaml 的目錄)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/../pubspec.yaml" ]]; then
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
elif [[ -f "$SCRIPT_DIR/pubspec.yaml" ]]; then
  PROJECT_ROOT="$SCRIPT_DIR"
elif [[ -f "pubspec.yaml" ]]; then
  PROJECT_ROOT="$(pwd)"
else
  log_error "找不到 pubspec.yaml，請在專案目錄下執行此腳本。"
  exit 1
fi

cd "$PROJECT_ROOT"

# 預設參數
IDENTITY=""
KEYCHAIN_PROFILE=""
FORMAT="dmg" # dmg 或 zip
SKIP_BUILD=false
SKIP_CODESIGN=false
SKIP_NOTARIZE=false
OUTPUT_DIR="$PROJECT_ROOT/build/macos/release-dist"
ENTITLEMENTS="$PROJECT_ROOT/macos/Runner/Release.entitlements"

show_help() {
  cat << EOF
使用方式: $(basename "$0") [選項]

選項:
  -i, --identity <身分字串>       代碼簽章身分（如 "Developer ID Application: Your Name (TEAMID)"）
                                若未指定，將自動搜尋鑰匙圈中的 Developer ID Application 憑證。
  -p, --keychain-profile <名稱>  notarytool 的鑰匙圈 Profile 名稱（預先以 xcrun notarytool store-credentials 儲存）
  -f, --format <dmg|zip>         產物封裝格式，預設為 "dmg"
  -o, --output-dir <路徑>        發布產物輸出目錄，預設為 "build/macos/release-dist"
      --skip-build              略過 flutter build macos --release 步驟（直接使用現有 build 產物）
      --skip-codesign           略過 Developer ID 重新簽章步驟
      --skip-notarize           略過 Apple 公證 (notarytool) 步驟
  -h, --help                    顯示此說明訊息

範例:
  # 完整執行：建置、簽章、打包 DMG、公證並裝訂
  $(basename "$0") -p "notary-profile"

  # 指定簽章身分與 Profile
  $(basename "$0") -i "Developer ID Application: Li-Sheng Hsu (H2724L9BS5)" -p "notary-profile"

  # 本機測試打包（略過公證）
  $(basename "$0") --skip-notarize
EOF
}

# 參數解析
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--identity)
      IDENTITY="$2"
      shift 2
      ;;
    -p|--keychain-profile)
      KEYCHAIN_PROFILE="$2"
      shift 2
      ;;
    -f|--format)
      FORMAT="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
      if [[ "$FORMAT" != "dmg" && "$FORMAT" != "zip" ]]; then
        log_error "不支援的封裝格式: $2 (僅支援 dmg 或 zip)"
        exit 1
      fi
      shift 2
      ;;
    -o|--output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    --skip-codesign)
      SKIP_CODESIGN=true
      shift
      ;;
    --skip-notarize)
      SKIP_NOTARIZE=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      log_error "未知參數: $1"
      show_help
      exit 1
      ;;
  esac
done

# 1. 前置檢查
log_info "開始 macOS 發布流程檢查..."
if ! command -v flutter >/dev/null 2>&1; then
  log_error "找不到 flutter 命令，請確保 Flutter SDK 已加入 PATH。"
  exit 1
fi

if ! command -v codesign >/dev/null 2>&1; then
  log_error "找不到 codesign 工具。"
  exit 1
fi

if [[ "$FORMAT" == "dmg" ]] && ! command -v hdiutil >/dev/null 2>&1; then
  log_error "找不到 hdiutil 工具，無法製作 DMG。"
  exit 1
fi

# 2. 自動尋找簽章身分 (若未指定且未略過簽名)
if [[ "$SKIP_CODESIGN" == false && -z "$IDENTITY" ]]; then
  log_info "未指定簽章身分，正在搜尋鑰匙圈中的 Developer ID Application 憑證..."
  FOUND_IDENTITIES=$(security find-identity -p codesigning -v | grep "Developer ID Application:" || true)
  ID_COUNT=$(echo "$FOUND_IDENTITIES" | grep -c "Developer ID Application:" || true)

  if [[ $ID_COUNT -eq 1 ]]; then
    # 提取引號中的名稱
    IDENTITY=$(echo "$FOUND_IDENTITIES" | sed -n 's/.*"\(Developer ID Application: .*\)"/\1/p')
    log_success "自動偵測到唯一簽章身分: $IDENTITY"
  elif [[ $ID_COUNT -gt 1 ]]; then
    log_warn "在鑰匙圈中找到多個 Developer ID Application 憑證:"
    echo "$FOUND_IDENTITIES"
    log_error "請透過 -i 或 --identity 明確指定要使用的簽章身分。"
    exit 1
  else
    log_warn "鑰匙圈中未找到 'Developer ID Application' 憑證。"
    log_warn "若您僅在本機測試，可帶入 --skip-codesign 略過；若要正式發布，請安裝有效的 Developer ID 憑證。"
    if [[ "$SKIP_NOTARIZE" == false ]]; then
      log_error "公證需要 Developer ID Application 簽章，無法繼續。請安裝憑證或加上 --skip-notarize --skip-codesign。"
      exit 1
    fi
  fi
fi

# 3. 建置 Release
if [[ "$SKIP_BUILD" == false ]]; then
  log_info "正在編譯 Release 產物 (flutter build macos --release)..."
  flutter build macos --release
else
  log_info "略過建置步驟，使用既有產物..."
fi

# 尋找產出的 .app
APP_DIR="$PROJECT_ROOT/build/macos/Build/Products/Release"
APP_PATH=$(find "$APP_DIR" -maxdepth 1 -name "*.app" | head -n 1)

if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  log_error "在 $APP_DIR 找不到 .app 產物，請確認建置是否成功。"
  exit 1
fi

APP_NAME=$(basename "$APP_PATH")
log_success "找到 App 產物: $APP_PATH"

mkdir -p "$OUTPUT_DIR"

# 4. 執行代碼簽名 (Inside-Out Deep Sign)
if [[ "$SKIP_CODESIGN" == false && -n "$IDENTITY" ]]; then
  log_info "正在執行深度簽章 (身分: $IDENTITY)..."

  if [[ ! -f "$ENTITLEMENTS" ]]; then
    log_error "找不到 Entitlements 檔案: $ENTITLEMENTS"
    exit 1
  fi

  # 簽署內部 Frameworks, dylibs 與 plugins
  FRAMEWORKS_DIR="$APP_PATH/Contents/Frameworks"
  if [[ -d "$FRAMEWORKS_DIR" ]]; then
    log_info "簽署 Frameworks 與動態庫..."
    find "$FRAMEWORKS_DIR" -depth -type d -name "*.framework" -o -name "*.dylib" | while read -r item; do
      log_info "  -> 簽署: $(basename "$item")"
      codesign --force --options runtime --timestamp --sign "$IDENTITY" "$item"
    done
  fi

  # 簽署主應用程式與其 Entitlements
  log_info "簽署主應用程式 $APP_NAME..."
  codesign --force --options runtime --entitlements "$ENTITLEMENTS" --timestamp --sign "$IDENTITY" "$APP_PATH"

  # 驗證簽章
  log_info "驗證主應用程式簽章..."
  codesign -vvv --deep --strict "$APP_PATH"
  log_success "代碼簽署完成且驗證通過。"
else
  log_info "略過重新簽章步驟。"
fi

# 5. 打包 (DMG 或 ZIP)
DIST_FILE=""
if [[ "$FORMAT" == "dmg" ]]; then
  DMG_NAME="${APP_NAME%.app}.dmg"
  OUTPUT_DMG="$OUTPUT_DIR/$DMG_NAME"
  rm -f "$OUTPUT_DMG"

  log_info "正在建立 DMG 映像檔: $OUTPUT_DMG..."
  TMP_DMG_DIR=$(mktemp -d /tmp/macos_release_dmg.XXXXXX)
  cp -R "$APP_PATH" "$TMP_DMG_DIR/"
  ln -s /Applications "$TMP_DMG_DIR/Applications"

  hdiutil create -volname "${APP_NAME%.app}" -srcfolder "$TMP_DMG_DIR" -ov -format UDZO "$OUTPUT_DMG"
  rm -rf "$TMP_DMG_DIR"

  if [[ "$SKIP_CODESIGN" == false && -n "$IDENTITY" ]]; then
    log_info "對 DMG 映像檔進行簽署..."
    codesign --force --timestamp --sign "$IDENTITY" "$OUTPUT_DMG"
  fi

  DIST_FILE="$OUTPUT_DMG"
  log_success "DMG 打包完成: $DIST_FILE"
else
  ZIP_NAME="${APP_NAME%.app}.zip"
  OUTPUT_ZIP="$OUTPUT_DIR/$ZIP_NAME"
  rm -f "$OUTPUT_ZIP"

  log_info "正在建立 ZIP 壓縮檔: $OUTPUT_ZIP..."
  ditto -c -k --keepParent "$APP_PATH" "$OUTPUT_ZIP"

  DIST_FILE="$OUTPUT_ZIP"
  log_success "ZIP 打包完成: $DIST_FILE"
fi

# 6. Apple Notarization 公證
if [[ "$SKIP_NOTARIZE" == false ]]; then
  if [[ -z "$KEYCHAIN_PROFILE" ]]; then
    log_error "執行公證需要指定 --keychain-profile <名稱>。"
    log_info "提示: 您可以使用以下指令先在系統中設定憑證:"
    log_info "  xcrun notarytool store-credentials \"notary-profile\" \\"
    log_info "    --apple-id \"your-apple-id@example.com\" \\"
    log_info "    --team-id \"H2724L9BS5\" \\"
    log_info "    --password \"app-specific-password\""
    exit 1
  fi

  log_info "正在將 $DIST_FILE 提交至 Apple 公證服務 (profile: $KEYCHAIN_PROFILE)..."
  xcrun notarytool submit "$DIST_FILE" --keychain-profile "$KEYCHAIN_PROFILE" --wait

  # 7. Stapling 裝訂公證票證
  log_info "正在將公證票證裝訂 (staple) 至產物..."
  if [[ "$FORMAT" == "dmg" ]]; then
    xcrun stapler staple "$DIST_FILE"
    log_success "公證票證已成功裝訂至 DMG！"
  else
    xcrun stapler staple "$APP_PATH"
    log_info "重新包裝已裝訂票證的 App 為 ZIP..."
    rm -f "$DIST_FILE"
    ditto -c -k --keepParent "$APP_PATH" "$DIST_FILE"
    log_success "公證票證已裝訂至 App 並重新打包 ZIP！"
  fi

  # 8. Gatekeeper 驗證評估
  log_info "執行 Gatekeeper 評估 (spctl)..."
  if [[ "$FORMAT" == "dmg" ]]; then
    spctl -a -vvv -t open --context context:primary-signature "$DIST_FILE"
  else
    spctl -a -vvv -t exec "$APP_PATH"
  fi
else
  log_info "略過公證步驟 (--skip-notarize)。"
fi

# 9. 完成摘要
log_success "=== 發布產物準備就緒 ==="
echo "產物路徑: $DIST_FILE"
echo "檔案大小: $(du -h "$DIST_FILE" | cut -f1)"
echo "SHA-256 : $(shasum -a 256 "$DIST_FILE" | cut -d ' ' -f 1)"
log_success "macOS 手動發布流程執行成功！"
