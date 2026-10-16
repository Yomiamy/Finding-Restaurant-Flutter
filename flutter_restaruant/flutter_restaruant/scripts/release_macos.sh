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
PROVISIONING_PROFILE="${MACOS_PROVISIONING_PROFILE:-}"
FORMAT="dmg" # dmg 或 zip
SKIP_BUILD=false
SKIP_CODESIGN=false
SKIP_NOTARIZE=false
OUTPUT_DIR="$PROJECT_ROOT/build/macos/release-dist"
ENTITLEMENTS="$PROJECT_ROOT/macos/Runner/Release.entitlements"

WORK_TMP_DIR=""
cleanup() {
  if [[ -n "$WORK_TMP_DIR" && -d "$WORK_TMP_DIR" ]]; then
    rm -rf "$WORK_TMP_DIR"
  fi
}
trap cleanup EXIT

show_help() {
  cat << EOF
使用方式: $(basename "$0") [選項]

選項:
  -i, --identity <身分字串>              代碼簽章身分（如 "Developer ID Application: Your Name (TEAMID)"）
                                        若未指定，將自動搜尋鑰匙圈中的 Developer ID Application 憑證。
  -p, --keychain-profile <名稱>         notarytool 的鑰匙圈 Profile 名稱（預先以 xcrun notarytool store-credentials 儲存）
  -P, --provisioning-profile <檔案路徑> Developer ID Provisioning Profile (.provisionprofile) 路徑
                                        若未指定，將自動於本機 Xcode Profile 目錄搜尋對應的 Developer ID Profile。
  -f, --format <dmg|zip>                產物封裝格式，預設為 "dmg"
      --dmg                             封裝為 DMG 磁碟映像檔（等同於 --format dmg）
      --zip                             封裝為 ZIP 壓縮檔（等同於 --format zip）
  -o, --output-dir <路徑>               發布產物輸出目錄，預設為 "build/macos/release-dist"
      --skip-build                      略過 flutter build macos --release 步驟（直接使用現有 build 產物）
      --skip-codesign                   略過 Developer ID 重新簽章步驟
      --skip-notarize                   略過 Apple 公證 (notarytool) 步驟
  -h, --help                            顯示此說明訊息

範例:
  # 完整執行：建置、簽章、打包 DMG、公證並裝訂
  $(basename "$0") -p "notary-profile"

  # 指定簽章身分、Provisioning Profile 與公證 Profile
  $(basename "$0") -i "Developer ID Application: Li-Sheng Hsu (H2724L9BS5)" -P "/path/to/Developer_ID.provisionprofile" -p "notary-profile"

  # 本機測試打包（略過公證）
  $(basename "$0") --dmg --skip-notarize
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
    -P|--provisioning-profile)
      PROVISIONING_PROFILE="$2"
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
    --dmg)
      FORMAT="dmg"
      shift
      ;;
    --zip)
      FORMAT="zip"
      shift
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
if [[ "$SKIP_BUILD" == false ]] && ! command -v flutter >/dev/null 2>&1; then
  log_error "找不到 flutter 命令，請確保 Flutter SDK 已加入 PATH（或使用 --skip-build 略過建置）。"
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
  # DEVELOPER_ID_BUILD 讓 App 隱藏 Apple 登入（Developer ID 不支援 Sign in with Apple）
  log_info "正在編譯 Release 產物 (flutter build macos --release --dart-define=DEVELOPER_ID_BUILD=true)..."
  flutter build macos --release --dart-define=DEVELOPER_ID_BUILD=true
else
  log_info "略過建置步驟，使用既有產物..."
fi

# 確定性選擇產出的 .app（檢查 AppInfo.xcconfig 的 PRODUCT_NAME 並拒絕多個候選 .app）
APP_DIR="$PROJECT_ROOT/build/macos/Build/Products/Release"
APP_INFO_XCCONFIG="$PROJECT_ROOT/macos/Runner/Configs/AppInfo.xcconfig"
CONFIGURED_PRODUCT_NAME=""
if [[ -f "$APP_INFO_XCCONFIG" ]]; then
  CONFIGURED_PRODUCT_NAME=$(sed -n 's/^[[:space:]]*PRODUCT_NAME[[:space:]]*=[[:space:]]*\([^[:space:]]*\).*/\1/p' "$APP_INFO_XCCONFIG" | head -n 1)
fi

shopt -s nullglob
APP_CANDIDATES=("$APP_DIR"/*.app)
shopt -u nullglob

if [[ ${#APP_CANDIDATES[@]} -eq 0 ]]; then
  log_error "在 $APP_DIR 找不到 .app 產物，請確認建置是否成功。"
  exit 1
elif [[ ${#APP_CANDIDATES[@]} -gt 1 ]]; then
  log_error "在 $APP_DIR 找到多個 .app 產物，拒絕猜測發布目標:"
  for candidate in "${APP_CANDIDATES[@]}"; do
    log_error "  - $(basename "$candidate")"
  done
  log_error "請先清理舊產物（例如執行 flutter clean）以確保唯一目標。"
  exit 1
fi

APP_PATH="${APP_CANDIDATES[0]}"
APP_NAME=$(basename "$APP_PATH")
if [[ -n "$CONFIGURED_PRODUCT_NAME" && "$APP_NAME" != "${CONFIGURED_PRODUCT_NAME}.app" ]]; then
  log_error "找到的產物 $APP_NAME 與 AppInfo.xcconfig 設定的 ${CONFIGURED_PRODUCT_NAME}.app 不一致。"
  exit 1
fi
log_success "找到唯一目標 App 產物: $APP_PATH"

WORK_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/macos_release.XXXXXX")

# 輔助函式：判斷 Provisioning Profile 是否為符合 Team ID 與 Bundle ID 的 Developer ID Profile
profile_matches() {
  local prof="$1"
  local target_team="$2"
  local target_bundle="$3"
  local decoded
  decoded=$(security cms -D -i "$prof" 2>/dev/null || true)
  [[ -n "$decoded" ]] || return 1
  # 讀具名欄位而非全文 grep：keychain-access-groups 的 `TEAM.*` 會讓任意 Bundle ID 誤判為符合
  local all_devices app_id
  all_devices=$(plutil -extract ProvisionsAllDevices raw -o - - <<< "$decoded" 2>/dev/null || true)
  app_id=$(plutil -extract 'Entitlements.com\.apple\.application-identifier' raw -o - - <<< "$decoded" 2>/dev/null || true)
  [[ "$all_devices" == "true" ]] &&
    [[ "$app_id" == "${target_team}.${target_bundle}" || "$app_id" == "${target_team}.*" ]]
}

# 輔助函式：自動搜尋符合 Team ID 與 Bundle ID 的 Developer ID Provisioning Profile
find_developer_id_profile() {
  local profile_dirs=(
    "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
    "$HOME/Library/MobileDevice/Provisioning Profiles"
  )
  for dir in "${profile_dirs[@]}"; do
    [[ -d "$dir" ]] || continue
    shopt -s nullglob
    local profiles=("$dir"/*.provisionprofile)
    shopt -u nullglob
    for prof in "${profiles[@]}"; do
      if profile_matches "$prof" "$1" "$2"; then
        echo "$prof"
        return 0
      fi
    done
  done
  return 1
}

# 4. 執行代碼簽名 (Inside-Out Deep Sign)
if [[ "$SKIP_CODESIGN" == false && -n "$IDENTITY" ]]; then
  log_info "正在執行深度簽章 (身分: $IDENTITY)..."

  if [[ ! -f "$ENTITLEMENTS" ]]; then
    log_error "找不到 Entitlements 檔案: $ENTITLEMENTS"
    exit 1
  fi

  # 解析 Team ID (AppIdentifierPrefix) 與 Bundle ID，展開 Release.entitlements 中的 Xcode 變數
  TEAM_ID=$(echo "$IDENTITY" | sed -n 's/.*(\([A-Z0-9]\{10\}\)).*/\1/p')
  if [[ -z "$TEAM_ID" && -f "$PROJECT_ROOT/macos/Runner.xcodeproj/project.pbxproj" ]]; then
    TEAM_ID=$(sed -n 's/.*DEVELOPMENT_TEAM = \([A-Z0-9]\{10\}\);.*/\1/p' "$PROJECT_ROOT/macos/Runner.xcodeproj/project.pbxproj" | head -n 1)
  fi
  if [[ -z "$TEAM_ID" ]]; then
    log_error "無法從簽章身分或專案設定解析 Team ID (AppIdentifierPrefix)。"
    exit 1
  fi

  BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Contents/Info.plist" 2>/dev/null || true)
  if [[ -z "$BUNDLE_ID" && -f "$APP_INFO_XCCONFIG" ]]; then
    BUNDLE_ID=$(sed -n 's/^[[:space:]]*PRODUCT_BUNDLE_IDENTIFIER[[:space:]]*=[[:space:]]*\([^[:space:]]*\).*/\1/p' "$APP_INFO_XCCONFIG" | head -n 1)
  fi
  if [[ -z "$BUNDLE_ID" ]]; then
    log_error "無法解析 PRODUCT_BUNDLE_IDENTIFIER。"
    exit 1
  fi

  RESOLVED_ENTITLEMENTS="$WORK_TMP_DIR/ResolvedRelease.entitlements"
  sed -e "s/\$(AppIdentifierPrefix)/${TEAM_ID}./g" \
      -e "s/\$(PRODUCT_BUNDLE_IDENTIFIER)/${BUNDLE_ID}/g" \
      "$ENTITLEMENTS" > "$RESOLVED_ENTITLEMENTS"
  /usr/libexec/PlistBuddy -c "Add :com.apple.application-identifier string ${TEAM_ID}.${BUNDLE_ID}" "$RESOLVED_ENTITLEMENTS" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :com.apple.application-identifier ${TEAM_ID}.${BUNDLE_ID}" "$RESOLVED_ENTITLEMENTS"
  /usr/libexec/PlistBuddy -c "Add :com.apple.developer.team-identifier string ${TEAM_ID}" "$RESOLVED_ENTITLEMENTS" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :com.apple.developer.team-identifier ${TEAM_ID}" "$RESOLVED_ENTITLEMENTS"
  # Developer ID profile 無法授權 Sign in with Apple（僅 Mac App Store 可），保留會導致 App 啟動即被系統終止
  /usr/libexec/PlistBuddy -c "Delete :com.apple.developer.applesignin" "$RESOLVED_ENTITLEMENTS" 2>/dev/null || true

  plutil -lint "$RESOLVED_ENTITLEMENTS" >/dev/null
  if grep -q '\$(' "$RESOLVED_ENTITLEMENTS"; then
    log_error "Entitlements 仍包含未展開的 Xcode 變數: $(grep '\$(' "$RESOLVED_ENTITLEMENTS")"
    exit 1
  fi

  # 嵌入匹配的 Developer ID Provisioning Profile（授權 keychain-access-groups 等受限 Entitlements）
  if [[ -z "$PROVISIONING_PROFILE" ]]; then
    PROVISIONING_PROFILE=$(find_developer_id_profile "$TEAM_ID" "$BUNDLE_ID" || true)
  fi

  # 缺少匹配的 profile 時，帶 keychain-access-groups 簽出的 App 會在執行期失敗，與是否公證無關，故一律中止
  if [[ -z "$PROVISIONING_PROFILE" ]]; then
    log_error "未找到對應 ${TEAM_ID}.${BUNDLE_ID} 的 Developer ID Provisioning Profile。"
    log_error "由於 Release.entitlements 包含受限的 keychain-access-groups，請透過 -P / --provisioning-profile 指定 Developer ID Provisioning Profile。"
    exit 1
  fi
  if [[ ! -f "$PROVISIONING_PROFILE" ]]; then
    log_error "指定的 Provisioning Profile 不存在: $PROVISIONING_PROFILE"
    exit 1
  fi
  if ! profile_matches "$PROVISIONING_PROFILE" "$TEAM_ID" "$BUNDLE_ID"; then
    log_error "Provisioning Profile 不是對應 ${TEAM_ID}.${BUNDLE_ID} 的 Developer ID Profile: $PROVISIONING_PROFILE"
    exit 1
  fi
  cp "$PROVISIONING_PROFILE" "$APP_PATH/Contents/embedded.provisionprofile"
  log_info "已嵌入 Developer ID Provisioning Profile: $PROVISIONING_PROFILE"

  # 簽署內部 Frameworks, dylibs 與 plugins
  FRAMEWORKS_DIR="$APP_PATH/Contents/Frameworks"
  if [[ -d "$FRAMEWORKS_DIR" ]]; then
    log_info "簽署 Frameworks 與動態庫..."
    find "$FRAMEWORKS_DIR" -depth \( -type d -name "*.framework" -o -name "*.dylib" \) | while read -r item; do
      log_info "  -> 簽署: $(basename "$item")"
      codesign --force --options runtime --timestamp --sign "$IDENTITY" "$item"
    done
  fi

  # 簽署主應用程式與已展開的 Entitlements
  log_info "簽署主應用程式 $APP_NAME..."
  codesign --force --options runtime --entitlements "$RESOLVED_ENTITLEMENTS" --timestamp --sign "$IDENTITY" "$APP_PATH"

  # 驗證簽章、Hardened Runtime 與簽入的 Entitlements
  log_info "驗證主應用程式簽章與已展開 Entitlements..."
  codesign --verify --deep --strict --verbose=2 "$APP_PATH"
  # 先存變數再 grep：直接 pipe 給 grep -q 會令 codesign 收到 SIGPIPE，pipefail 下誤判為失敗
  SIGN_INFO=$(codesign --display --verbose=2 "$APP_PATH" 2>&1)
  if ! grep -q 'flags=.*runtime' <<< "$SIGN_INFO"; then
    log_error "主應用程式簽章缺少 Hardened Runtime (runtime) 旗標。"
    exit 1
  fi
  SIGNED_ENTITLEMENTS=$(codesign -d --entitlements :- "$APP_PATH" 2>/dev/null || true)
  if grep -q '\$(' <<< "$SIGNED_ENTITLEMENTS" || ! grep -q "${TEAM_ID}.${BUNDLE_ID}" <<< "$SIGNED_ENTITLEMENTS"; then
    log_error "簽入的 Entitlements 驗證失敗，未包含預期的 ${TEAM_ID}.${BUNDLE_ID}。"
    exit 1
  fi
  log_success "代碼簽署完成且簽章、Hardened Runtime 與 Entitlements 驗證通過。"
else
  log_info "略過重新簽章步驟。"
fi

# 5. 於暫存目錄打包 (DMG 或 ZIP)，待所有步驟成功後才原子替換正式產物
STAGE_OUT_DIR="$WORK_TMP_DIR/stage"
mkdir -p "$STAGE_OUT_DIR"
ARTIFACT_NAME=""
STAGE_DIST_FILE=""

if [[ "$FORMAT" == "dmg" ]]; then
  ARTIFACT_NAME="${APP_NAME%.app}.dmg"
  STAGE_DIST_FILE="$STAGE_OUT_DIR/$ARTIFACT_NAME"

  log_info "正在建立暫存 DMG 映像檔: $STAGE_DIST_FILE..."
  TMP_DMG_DIR="$WORK_TMP_DIR/dmg_src"
  mkdir -p "$TMP_DMG_DIR"
  cp -R "$APP_PATH" "$TMP_DMG_DIR/"
  ln -s /Applications "$TMP_DMG_DIR/Applications"

  hdiutil create -volname "${APP_NAME%.app}" -srcfolder "$TMP_DMG_DIR" -ov -format UDZO "$STAGE_DIST_FILE"
  rm -rf "$TMP_DMG_DIR"

  if [[ "$SKIP_CODESIGN" == false && -n "$IDENTITY" ]]; then
    log_info "對 DMG 映像檔進行簽署..."
    codesign --force --timestamp --sign "$IDENTITY" "$STAGE_DIST_FILE"
  fi

  log_success "DMG 暫存打包完成: $STAGE_DIST_FILE"
else
  ARTIFACT_NAME="${APP_NAME%.app}.zip"
  STAGE_DIST_FILE="$STAGE_OUT_DIR/$ARTIFACT_NAME"

  log_info "正在建立暫存 ZIP 壓縮檔: $STAGE_DIST_FILE..."
  ditto -c -k --keepParent "$APP_PATH" "$STAGE_DIST_FILE"

  log_success "ZIP 暫存打包完成: $STAGE_DIST_FILE"
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

  log_info "正在將 $STAGE_DIST_FILE 提交至 Apple 公證服務 (profile: $KEYCHAIN_PROFILE)..."
  xcrun notarytool submit "$STAGE_DIST_FILE" --keychain-profile "$KEYCHAIN_PROFILE" --wait

  # 7. Stapling 裝訂公證票證
  log_info "正在將公證票證裝訂 (staple) 至產物..."
  if [[ "$FORMAT" == "dmg" ]]; then
    xcrun stapler staple "$STAGE_DIST_FILE"
    log_success "公證票證已成功裝訂至 DMG！"
  else
    xcrun stapler staple "$APP_PATH"
    log_info "重新包裝已裝訂票證的 App 為 ZIP..."
    rm -f "$STAGE_DIST_FILE"
    ditto -c -k --keepParent "$APP_PATH" "$STAGE_DIST_FILE"
    log_success "公證票證已裝訂至 App 並重新打包 ZIP！"
  fi

  # 8. Gatekeeper 驗證評估
  log_info "執行 Gatekeeper 評估 (spctl)..."
  if [[ "$FORMAT" == "dmg" ]]; then
    spctl -a -vvv -t open --context context:primary-signature "$STAGE_DIST_FILE"
  else
    spctl -a -vvv -t exec "$APP_PATH"
  fi
else
  log_info "略過公證步驟 (--skip-notarize)。"
fi

# 所有步驟驗證通過後，原子移動替換目標路徑的正式產物
mkdir -p "$OUTPUT_DIR"
DIST_FILE="$OUTPUT_DIR/$ARTIFACT_NAME"
mv -f "$STAGE_DIST_FILE" "$DIST_FILE"

# 9. 完成摘要
log_success "=== 發布產物準備就緒 ==="
echo "產物路徑: $DIST_FILE"
echo "檔案大小: $(du -h "$DIST_FILE" | cut -f1)"
echo "SHA-256 : $(shasum -a 256 "$DIST_FILE" | cut -d ' ' -f 1)"
log_success "macOS 手動發布流程執行成功！"
