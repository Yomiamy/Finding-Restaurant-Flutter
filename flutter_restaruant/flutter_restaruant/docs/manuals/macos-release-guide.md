# macOS 發布與公證完整操作手冊 (macOS Release & Notarization Guide)

本手冊為 Finding Restaurant 專案 macOS 平台的正式發布標準作業流程 (SOP)。依據專案決策 `D-9.8`，目前 CI/CD 暫不自動建置與分發 macOS 版本，所有對外發布皆由開發者依本指南執行手動發布流程。

---

## 1. 發布路徑概觀

macOS 應用程式的發布分為兩種主要路徑：

| 項目 | 路徑 A：外部獨立分發 (Direct Distribution) | 路徑 B：Mac App Store 分發 |
| :--- | :--- | :--- |
| **目標受眾** | 官網下載、內部測試者、直接安裝使用者 | Mac App Store 使用者 |
| **發行格式** | `.dmg` 磁碟映像檔 或 `.zip` 壓縮檔 | `.pkg` 安裝套件（透過 Transporter 上傳） |
| **簽署憑證** | `Developer ID Application` | `Apple Distribution`（或 `Mac App Distribution`） |
| **公證機制** | **強制要求** Apple Notarization（公證）與 Stapling（裝訂） | 由 Apple 於審查期間統一處理 |
| **沙盒限制** | 支援 App Sandbox 與 Hardened Runtime | **強制要求** 完整 App Sandbox |
| **自動化腳本** | 支援專案提供之 `scripts/release_macos.sh` 一鍵完成 | 透過 Xcode Organizer 或 `xcodebuild -exportArchive` |

---

## 2. 前置準備

### 2.1 Apple Developer Program 帳號與憑證
確保已登入具備專案 Team 權限的 Apple 開發者帳號：
- **Team ID**：`H2724L9BS5`
- **Bundle ID**：`com.yomi.find-restaurant.macos`

執行以下指令確認本機鑰匙圈已安裝對應憑證：
```bash
security find-identity -p codesigning -v
```

- 若走**路徑 A (外部獨立分發)**：必須看見 `"Developer ID Application: ... (H2724L9BS5)"`。
- 若走**路徑 B (Mac App Store)**：必須看見 `"Apple Distribution: ... (H2724L9BS5)"`。

### 2.2 設定 Notarytool 鑰匙圈 Profile (路徑 A 必要)
Apple 公證服務（Notarization）推薦使用 `xcrun notarytool` 並搭配儲存於 macOS 鑰匙圈的密鑰設定檔 (Profile)。

#### 方式一：使用 App 專用密碼 (App-Specific Password)
1. 前往 [appleid.apple.com](https://appleid.apple.com) 登入，於「登入與安全性」區塊產生一組專用密碼。
2. 在終端機執行儲存指令（將設定檔命名為 `notary-profile`）：
   ```bash
   xcrun notarytool store-credentials "notary-profile" \
     --apple-id "your-apple-id@example.com" \
     --team-id "H2724L9BS5" \
     --password "xxxx-xxxx-xxxx-xxxx"
   ```

#### 方式二：使用 App Store Connect API Key (團隊推薦)
1. 在 App Store Connect「使用者與存取權」$\rightarrow$「整合」$\rightarrow$「密鑰」下載 `.p8` 密鑰檔案。
2. 執行：
   ```bash
   xcrun notarytool store-credentials "notary-profile" \
     --key "/path/to/AuthKey_XXXXXXXXXX.p8" \
     --key-id "XXXXXXXXXX" \
     --issuer "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
   ```

---

## 3. 路徑 A：Developer ID 外部分發（一鍵腳本）

專案在 `scripts/release_macos.sh` 提供了完整自動化打包、簽章、公證與裝訂流程。

### 3.1 一鍵發布完整指令
```bash
# 於專案根目錄下執行：
./scripts/release_macos.sh -p "notary-profile"
```
腳本將依序自動完成：
1. 執行 `flutter build macos --release` 編譯 release 產物。
2. 自動偵測鑰匙圈中的 `Developer ID Application` 憑證。
3. 對 `Contents/Frameworks/`（FlutterMacOS、動態庫及 Pods）由內而外重新深度簽名，啟用 Hardened Runtime (`--options runtime`) 並掛載 `Release.entitlements`。
4. 打包為 `.dmg` 映像檔（內建 `/Applications` 捷徑）。
5. 簽署 `.dmg` 映像檔本體。
6. 將 `.dmg` 提交至 Apple 公證服務，並等待完成審批 (`--wait`)。
7. 成功後自動將公證票證裝訂至 `.dmg` (`xcrun stapler staple`)。
8. 執行 Gatekeeper 檢驗 (`spctl`) 並產出 SHA-256 校驗碼。

產物將輸出至：`build/macos/release-dist/finding_restaurant.dmg`。

### 3.2 常用命令選項
```bash
# 1. 僅在本機測試打包與簽章（不連線 Apple 進行公證）
./scripts/release_macos.sh --skip-notarize

# 2. 打包為 .zip 而非 .dmg
./scripts/release_macos.sh -p "notary-profile" -f zip

# 3. 指定特定簽章身分（當鑰匙圈中有多個憑證時）
./scripts/release_macos.sh -i "Developer ID Application: Li-Sheng Hsu (H2724L9BS5)" -p "notary-profile"

# 4. 跳過重新編譯（使用既有 build 產物快速重打）
./scripts/release_macos.sh --skip-build -p "notary-profile"
```

### 3.3 產物驗收指令
手動驗證產物是否能通過 macOS Gatekeeper：
```bash
# 檢查 DMG 上的公證票證
xcrun stapler validate build/macos/release-dist/finding_restaurant.dmg

# 檢查 DMG 磁碟映像檔之 Gatekeeper 評估結果（應顯示 accepted）
spctl -a -vvv -t open --context context:primary-signature build/macos/release-dist/finding_restaurant.dmg

# 檢查代碼簽章完整性與 Hardened Runtime (runtime) 旗標
codesign --verify --deep --strict build/macos/Build/Products/Release/finding_restaurant.app
codesign --display --verbose=2 build/macos/Build/Products/Release/finding_restaurant.app 2>&1 | grep 'flags=.*runtime'
```

---

## 4. 路徑 B：Mac App Store 上架指南

若欲將 App 上架至 Mac App Store，可走 Xcode Archive 或 CLI `xcodebuild` 流程。

### 4.1 CLI 打包流程
專案已內建 `macos/ExportOptions-AppStore.plist`。

1. 編譯 Flutter 資源：
   ```bash
   flutter build macos --config-only --release
   ```
2. 建立 Archive 歸檔：
   ```bash
   xcodebuild -workspace macos/Runner.xcworkspace \
     -scheme Runner \
     -configuration Release \
     -archivePath "build/macos/Runner.xcarchive" \
     archive \
     DEVELOPMENT_TEAM=H2724L9BS5
   ```
3. 匯出 Mac App Store 安裝套件 (`.pkg`)：
   ```bash
   xcodebuild -exportArchive \
     -archivePath "build/macos/Runner.xcarchive" \
     -exportPath "build/macos/appstore-dist" \
     -exportOptionsPlist "macos/ExportOptions-AppStore.plist"
   ```
4. 提交至 App Store Connect：
   使用 **Transporter** 應用程式載入匯出的 `.pkg`，或使用 `xcrun altool` 上傳。

### 4.2 Xcode GUI 操作流程
1. 以 Xcode 開啟 `macos/Runner.xcworkspace`。
2. 頂部 Destination 選擇 `Any Mac (Apple Silicon, Intel)`。
3. 點擊選單列 `Product` $\rightarrow$ `Archive`。
4. 歸檔完成後，在 Organizer 視窗點選 `Distribute App`。
5. 選擇 `App Store Connect` $\rightarrow$ `Upload`，依指示完成憑證配置與上傳。

---

## 5. 常見問題與排錯指南 (Troubleshooting)

### Q1：下載安裝後跳出「無法打開，因為無法驗證開發者」或「已損毀」？
- **原因**：外部分發的應用程式未通過 Apple 公證，或公證成功後未執行 `xcrun stapler staple` 裝訂票證，導致離線或無快取時 Gatekeeper 封鎖。
- **解法**：確認發布腳本完整執行了公證與裝訂流程，並以 `spctl -a -vvv -t open --context context:primary-signature <DMG產物>`（或針對 `.app` 執行 `spctl -a -vvv -t exec <App產物>`）檢查是否顯示 `accepted / source=Notarized Developer ID`。

### Q2：公證失敗 (`xcrun notarytool submit` 回傳 Invalid)？
- **檢視日誌**：執行以下指令查詢 Apple 給出的具體錯誤清單：
  ```bash
  xcrun notarytool log <submission-id> --keychain-profile "notary-profile"
  ```
- **常見原因**：
  1. **未啟用 Hardened Runtime**：簽章時遺漏 `--options runtime`。
  2. **缺少時間戳記**：簽章時遺漏 `--timestamp`。
  3. **未簽署內部動態庫**：`Contents/Frameworks/` 內的部分 `.dylib` 未被完整簽名。使用 `scripts/release_macos.sh` 會自動進行深度巢狀簽章。

### Q3：啟動時當機，出現 Keychain -34018 錯誤？
- **原因**：`Release.entitlements` 宣告了 `keychain-access-groups`，但使用的 Provisioning Profile 未授權該 Team ID 的存取群組。
- **解法**：Developer ID 外部分發時，需在 Apple Developer 後台為該 App ID 產生對應之 Developer ID Provisioning Profile，或確認憑證與 Team ID (`H2724L9BS5`) 一致。
