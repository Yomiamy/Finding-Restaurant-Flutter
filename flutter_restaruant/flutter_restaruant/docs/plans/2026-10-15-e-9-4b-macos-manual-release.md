# 實作計畫：E-9.4b macOS 手動發布流程（Developer ID / Notarization / App Store）

- **建立日期**：2026-10-15
- **對應規格**：`docs/features/2026-10-15-e-9-4b-macos-manual-release.md`
- **狀態**：等待確認 (Pending Confirmation)

---

## 1. 簡介與目標 (Overview & Goals)

落實決策 `D-9.8` 與功能項目 `E-9.4b`，為專案建立標準化、自動化且具容錯力的 macOS 手動發布流程，涵蓋：
1. **Developer ID 外部分發**：一鍵建置、完整巢狀簽章（含 Hardened Runtime 與 Release Entitlements）、DMG/ZIP 打包、Apple 公證（`xcrun notarytool`）與票證裝訂（`xcrun stapler`）。
2. **Mac App Store 上架**：提供標準 ExportOptions 配置範本與 Xcode Archive / Transporter 提交手冊。
3. **發布與排錯操作手冊**：提供繁體中文完整指南與驗證指令。

---

## 2. 檔案異動清單 (File Changes)

### 2.1 新增檔案
- `scripts/release_macos.sh`：macOS 手動打包、簽章、公證與裝訂之可執行輔助腳本。
- `macos/ExportOptions-DeveloperID.plist`：Developer ID 外部分發之 Xcode Archive 匯出選項範本。
- `macos/ExportOptions-AppStore.plist`：Mac App Store 上架之 Xcode Archive 匯出選項範本。
- `docs/manuals/macos-release-guide.md`：macOS 雙路徑發布手冊與故障排查指南。

### 2.2 不修改既有組態（向後相容保證）
- `macos/Runner.xcodeproj/project.pbxproj`：維持既有 Release 與 Debug 組態之 `Apple Development` 本機自動簽章，不破壞團隊本機開發建置。

---

## 3. 實作任務拆分 (Tasks)

### 任務 1：建立 macOS 打包與公證輔助腳本 `scripts/release_macos.sh`
- **內容**：
  - 支援 CLI 參數：`--identity`、`--keychain-profile`、`--format` (dmg/zip)、`--skip-notarize`、`--help`。
  - 自動防禦性檢查：檢查 `flutter`、`codesign`、`hdiutil`、`xcrun`。
  - 建置流程：執行 `flutter build macos --release`。
  - 簽章邏輯：自動偵測或使用指定 `Developer ID Application` 憑證，對 `App.framework`、`FlutterMacOS.framework`、外掛動態庫及 `Runner.app` 進行深度簽名（`--options runtime --entitlements macos/Runner/Release.entitlements --timestamp`）。
  - 打包邏輯：支援產生 DMG（包含 `/Applications` 符號連結）或 ZIP。
  - 公證與裝訂：調用 `xcrun notarytool submit ... --wait` 與 `xcrun stapler staple`。
  - 驗證步驟：輸出 `codesign -vvv --deep --strict` 與 `spctl -a -vvv` 結果。
- **驗證**：賦予執行權限 `chmod +x`，執行 `--help` 檢查參數說明；搭配 `--skip-notarize` 驗證本地打包與簽章檢測流程。

### 任務 2：建立 ExportOptions 設定檔範本
- **內容**：
  - `macos/ExportOptions-DeveloperID.plist`：配置 `method: developer-id`、`signingStyle: manual/automatic`。
  - `macos/ExportOptions-AppStore.plist`：配置 `method: app-store`、`uploadSymbols: true`。
- **驗證**：使用 `plutil -lint` 驗證 XML/plist 語法無誤。

### 任務 3：撰寫 macOS 發布完整操作手冊 `docs/manuals/macos-release-guide.md`
- **內容**：
  - Apple 開發者帳號與憑證前置準備（憑證類型差異、Team ID `H2724L9BS5`）。
  - `xcrun notarytool store-credentials` 快速設定說明。
  - 路徑 A：Developer ID 外部分發（腳本一鍵執行 SOP）。
  - 路徑 B：Mac App Store 上架（Xcode GUI 與 CLI 操作 SOP）。
  - 產物驗證指令與 Gatekeeper 規則說明。
  - 常見失敗原因與修復（Hardened Runtime 遺漏、Keychain Access Groups 授權、notarytool 查詢 log 方法）。
- **驗證**：Markdown 格式檢驗、連結正確。

### 任務 4：整合驗收與回歸測試
- **內容**：
  - 執行 `flutter analyze .` 確保專案無靜態分析警告。
  - 執行 `flutter test` 確保 313+ 單元與元件測試完全通過。
  - 執行 `flutter build macos --release` 確保本機既有建置完全不受影響。

---

## 4. 驗收標準 (Acceptance Criteria)

1. `scripts/release_macos.sh` 可順利解析參數，語法正確且具備明確錯誤回饋。
2. `macos/ExportOptions-*.plist` 符合 Apple 規範且通過語法檢查。
3. `docs/manuals/macos-release-guide.md` 提供完整、可實際依循之繁體中文操作指南。
4. 現有程式庫零回歸（測試全過、靜態分析零警告）。
