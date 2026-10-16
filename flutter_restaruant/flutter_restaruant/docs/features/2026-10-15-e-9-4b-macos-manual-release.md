# 功能規格：E-9.4b macOS 手動發布流程（Developer ID / Notarization / App Store）

- **建立日期**：2026-10-15
- **負責角色**：DevOps / macOS 平台專家
- **狀態**：規劃中 (Draft)
- **關聯**：
  - 決策：`D-9.8`（CI 暫不涵蓋 macOS，macOS 發布先採手動）
  - 前置：`A-9.6`（macOS 適配已完成）、`E-9.4a`（本機開發簽章與 Sign in with Apple 已齊備）
  - 需求來源：`docs/brainstorm/2026-10-12-features-brainstorm.md` §9.6 `E-9.4b`

---

## 1. 需求與背景 (Problem & Background)

### 1.1 現況與痛點
- 在完成 A-9.6 與 E-9.4a 後，macOS 平台的程式碼與基本 capabilities（Keychain Access Groups、Sign in with Apple）已在本地 Debug/Release 建置驗證通過。
- 目前 `macos/Runner.xcodeproj` 的 Release 組態使用 `Apple Development` 憑證進行本機簽章（以利開發時測試 Keychain 與 Auth）。此種憑證簽出的產物**無法分發給外部使用者**（會觸發 macOS Gatekeeper 警告或無法在未註冊設備上啟動）。
- 依據決策 `D-9.8`，目前 GitHub Actions CI 不涵蓋 macOS 建置與部署。因此，外部發布（不論是透過 Developer ID 進行獨立外部分發，或是上架 Mac App Store）必須有一套**標準化、防呆且可重複執行的手動發布流程與輔助工具**。
- 若缺少腳本化輔助工具與清晰 SOP，手動執行時極易在 Hardened Runtime、Entitlements 覆寫、Deep Signing（巢狀 Frameworks 簽章）、Notarization 票證裝訂 (Stapling) 或 DMG 建立時出錯。

### 1.2 目標 (Goals)
1. **Developer ID 外部分發路徑 (Direct Distribution)**：
   - 提供自動化打包與公證輔助腳本 `scripts/release_macos.sh`。
   - 支援自動編譯 Release app、以指定憑證或 Developer ID Application 進行完整巢狀代碼簽名（含 Hardened Runtime 與 `Release.entitlements`）。
   - 支援將產物打包為 DMG 映像檔或 ZIP，呼叫 Apple `xcrun notarytool` 進行公證 (Notarization)。
   - 公證成功後自動執行 `xcrun stapler staple` 裝訂公證票證。
2. **Mac App Store 上架路徑 (App Store Submission)**：
   - 定義 Xcode Archive 與 `productbuild` 打包 `.pkg` 的標準操作步驟。
   - 提供對應的 `ExportOptions.plist` 範本（App Store 與 Developer ID 各一）。
3. **完整 SOP 與憑證設定手冊**：
   - 在 `docs/manuals/macos-release-guide.md` 詳細說明：
     - Apple Developer 憑證申請與安裝（Developer ID Application vs Apple Distribution）。
     - `xcrun notarytool store-credentials` 密鑰鏈設定指南。
     - 逐步執行命令與排錯指南（如 Keychain 權限、Bundle ID 驗證、公證失敗日誌讀取）。
4. **零破壞性保證**：
   - 不修改現有日常開發所用的 `Apple Development` 本機自動簽章設定，確保日常 `flutter run -d macos` 與 `flutter test` 維持最順暢體驗。

---

## 2. 需求 Brief (gen-grill 審核)

- **Q1 問題定義**：macOS 目前僅有本機開發簽章，缺乏外部分發（Developer ID + Notarization）與 Mac App Store 發布的標準腳本與操作手冊。
- **Q2 觸發場景**：專案需要對外提供 macOS 獨立安裝檔（DMG）或提交 Mac App Store 審查時，開發者需要按照標準流程簽章、公證與打包。
- **Q3 成功標準**：
  1. 提供 `scripts/release_macos.sh`，可由指令參數驅動完成建置、簽名檢查、DMG/ZIP 打包、notarytool 提交與 stapler 票證裝訂。
  2. 提供 `macos/ExportOptions-DeveloperID.plist` 與 `macos/ExportOptions-AppStore.plist` 設定範本。
  3. 提供完整繁體中文發布指南 `docs/manuals/macos-release-guide.md`。
  4. 既有 313+ tests 全綠、`flutter analyze` 零錯誤、本機 `flutter build macos` 不受任何破壞。
- **Q4 範圍邊界**：
  - 不修改 CI/CD（遵守 D-9.8，CI 暫不納入 macOS）。
  - 不更動 Android、iOS、Web 的發布機制。
- **Q5 既有覆蓋實查**：
  - 現況 codebase 零發布腳本、零 ExportOptions plist、零手冊。

---

## 3. 驗收條件 (Acceptance Criteria)

- **AC-1**：腳本功能健全
  - `scripts/release_macos.sh` 具備清楚的 `--help` 說明與參數解析（支援 `--identity`、`--keychain-profile`、`--dmg` 等）。
  - 若環境缺少必要工具或憑證，具備清楚的防禦性提示，不會產生破損產物。
- **AC-2**：設定檔範本完備
  - `macos/` 下包含可直接配合 Xcode 或 `xcodebuild` 使用的 ExportOptions 範本。
- **AC-3**：發布指南完整
  - `docs/manuals/macos-release-guide.md` 包含環境前置、憑證儲存、兩種發布路徑之逐步操作指引與驗證命令（`spctl --assess`、`codesign -dvvv`）。
- **AC-4**：向後相容與本機健全
  - 所有新增腳本與文件均不破壞現有 `flutter build macos --debug` 與 `flutter build macos`（本機 Release 開發版）。
