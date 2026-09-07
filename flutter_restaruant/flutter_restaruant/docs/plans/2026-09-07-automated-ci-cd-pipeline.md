# Implementation Plan: 自動化 CI/CD 發布流水線 (Automated CI/CD Pipeline - GitHub Actions)

> 項目編號：**F-0.1A**  
> 優先級別：**P0（基礎設施地基）**  
> 關聯規格：[`docs/features/2026-09-07-automated-ci-cd-pipeline.md`](../features/2026-09-07-automated-ci-cd-pipeline.md)  
> 參考架構：`taroko_app/.github/workflows/release.yml`  
> 發布方案：**方案 B（Dev 路線雙平台皆走 Firebase App Distribution，Prd 路線走 Google Play + TestFlight）**  
> 建立日期：2026-09-07  
> 狀態：草稿（待確認）

---

## 1. 簡介與目標 (Overview)

本實作計畫旨在為本專案建立一套標準化、完全淘汰 Fastlane、純原生 CLI 與 GitHub Actions 驅動之 **CI/CD 自動化發布流水線**：
1. **宣告式 Tag 觸發與強版號守門**：
   - 支援 `prod-v*`、`dev-android-v*`、`dev-ios-v*` 標籤。
   - 自動提取版本號並強制比對 `pubspec.yaml`，防止版號漂移。
2. **多通道自動化分發**：
   - **`prod-v*`**：Android 打包 AAB 並透過 `r0adkll/upload-google-play@v1` 上傳至 Google Play 內部測試軌；iOS 使用 `IOS_APPSTORE_PROFILE_BASE64` 打包 Archive 並透過原生 `xcodebuild -exportArchive` 直連上傳至 Apple TestFlight。
   - **`dev-android-v*`**：打包 APK 並透過 `wzieba/Firebase-App-Distribution-Github-Action@v1` 上傳至 Firebase App Distribution。
   - **`dev-ios-v*`**：使用 `IOS_ADHOC_PROFILE_BASE64` 匯出 Ad Hoc IPA，並透過 `wzieba/Firebase-App-Distribution-Github-Action@v1` 上傳至 Firebase App Distribution。
3. **零機密洩漏與極簡環境依賴**：
   - 移除 Ruby、Bundler 與 Fastlane 等厚重依賴，建置環境極致輕量化。
   - 所有 Keystore、P12、Profiles、API Keys 透過 GitHub Secrets（共 13 個）安全注入。

---

## 2. 架構設計與 Trade-off 分析 (Design & Trade-offs)

### 2.1 Runner 選型分析
- 採用單一 `macos-14` Runner，同時具備 Android SDK、Java 17 與 Xcode 15+ 環境，雙平台發布無需跨 Runner 傳遞建置產物。

### 2.2 iOS 雙 Profile 分流機制 (方案 B 核心)
- **`prod` 路線**：
  - 解碼 `IOS_APPSTORE_PROFILE_BASE64`
  - `ExportOptions.plist` 設定 `method: app-store-connect`, `destination: upload`
  - 注入 `APPLE_API_KEY_*` 並由 `xcodebuild -exportArchive` 直連上傳 TestFlight。
- **`dev-ios` 路線**：
  - 解碼 `IOS_ADHOC_PROFILE_BASE64`（包含測試機 UDID 清單）
  - `ExportOptions.plist` 設定 `method: ad-hoc`, `compileBitcode: false`
  - 呼叫 `xcodebuild -exportArchive` 匯出 `Runner.ipa`，再由 `wzieba/Firebase-App-Distribution-Github-Action@v1` 上傳至 Firebase App Distribution。

### 2.3 Android 簽名設定整合
- 透過 CI 動態建立 `android/key.properties`，並在 `android/app/build.gradle` 補充 `key.properties` 讀取支援，與環境變數 fallback 並存。

---

## 3. 檔案異動清單 (File Changes)

### 3.1 既有檔案修改
- **[`flutter_restaruant/flutter_restaruant/android/app/build.gradle`](file:///Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant/android/app/build.gradle)**：
  - 增強簽名設定讀取邏輯：優先讀取 `android/key.properties`（若存在），次優先讀取 `System.getenv(...)`，最後 fallback 至 `local.properties`。

### 3.2 新增檔案
- **[`.github/workflows/release.yml`](file:///Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/.github/workflows/release.yml)**：
  - 配置於 Git 根目錄 `.github/workflows/` 下。
  - 實現 Tag 格式解析、Pubspec 驗證、Java/Flutter/Xcode 環境初始化。
  - 實現 Android Keystore 解碼、AAB/APK 打包、Google Play 上傳與 Firebase App Distribution 上傳。
  - 實現 iOS 憑證匯入、雙 Profile 分流（App Store vs Ad Hoc）、Archive 建置、TestFlight 上傳與 Firebase App Distribution 上傳。
- **[`.github/RELEASE_GUIDE.md`](file:///Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/.github/RELEASE_GUIDE.md)**：
  - 完整的 Tag 發布操作指引與 13 個 GitHub Secrets 的配置說明清單（特別標註 Ad Hoc UDID 需求）。

---

## 4. 任務拆分 (Tasks Breakdown)

- [ ] **Task 1: 增強 Android Gradle 簽名支援 (`key.properties`)**（複雜度：快/便宜）
  - 調整 `android/app/build.gradle` 加入標準 `key.properties` 讀取邏輯。
  - 驗證本地能正常解析簽名檔路徑。

- [ ] **Task 2: 建立核心發布流水線 `.github/workflows/release.yml`**（複雜度：標準）
  - 宣告 Tag 觸發規則：`prod-v*`、`dev-android-v*`、`dev-ios-v*`。
  - 實作 Step 1~3：Tag 解析、版本比對守門、Java 17 與 Flutter 3.44.1 環境配置。
  - 實作 Step 4：Android Keystore 解碼、`key.properties` 產出、AAB (`prod`) 與 APK (`dev-android`) 建置。
  - 實作 Step 5：Android 分發（Google Play Internal Testing 透過 `r0adkll/upload-google-play@v1`；Firebase 透過 `wzieba/Firebase-App-Distribution-Github-Action@v1`）。
  - 實作 Step 6：iOS 臨時 Keychain、P12 匯入、Profile 依類型分流（`IOS_APPSTORE_PROFILE_BASE64` vs `IOS_ADHOC_PROFILE_BASE64`）解析與安裝。
  - 實作 Step 7：iOS `flutter build ios --no-codesign` 與原生 `xcodebuild archive`。
  - 實作 Step 8：iOS 匯出與分發分流：
    - `prod`：生成 `ExportOptions.plist`（`app-store-connect`），注入 AuthKey p8，由 `xcodebuild -exportArchive` 直連上傳 TestFlight。
    - `dev-ios`：生成 `ExportOptions.plist`（`ad-hoc`），匯出 `Runner.ipa`，由 Firebase Action 上傳至 Firebase App Distribution。
  - 實作 Step 9：Release Summary 輸出。

- [ ] **Task 3: 建立發布與 Secrets 設定手冊 `.github/RELEASE_GUIDE.md`**（複雜度：快/便宜）
  - 詳細記錄 13 個 Secrets 的命名、用途與取得/編碼方式（base64）。
  - 提供語意化 Tag 範例（如 `prod-v2.0.1+33`）與 Ad Hoc UDID 注意事項。

- [ ] **Task 4: 流水線靜態校驗與回歸測試**（複雜度：標準）
  - 使用 Python / bash 驗證 `release.yml` 語法有效性與正則表達式。
  - 執行 `flutter analyze` 確保專案維持 `No issues found!`。
  - 執行 `flutter test` 確保既有 102 筆測試全數通過。

---

## 5. 驗收標準 (Verification)

- [ ] **架構對齊**：
  - [ ] 完全無 Fastlane 依賴，無 Ruby/Bundler 設定。
  - [ ] `.github/workflows/release.yml` 語法正確無誤，工作目錄正確指向 `flutter_restaruant/flutter_restaruant`。
- [ ] **功能完整**：
  - [ ] `prod-v*`：Android 產出 AAB 上傳 Google Play；iOS 使用 App Store Profile 產出 Archive 上傳 TestFlight。
  - [ ] `dev-android-v*`：產出 APK 上傳 Firebase App Distribution。
  - [ ] `dev-ios-v*`：使用 Ad Hoc Profile 產出 Ad Hoc IPA 上傳 Firebase App Distribution。
- [ ] **品質與相容**：
  - [ ] `flutter analyze` 零警告 (`No issues found!`)。
  - [ ] `flutter test` 保持 102 測試全綠。

---

## 6. 執行方式 (Execution Options)

- **方式一（標準模式）**：依序執行 Task 1 $\rightarrow$ Task 2 $\rightarrow$ Task 3 $\rightarrow$ Task 4。
- **方式二（Subagent 平行加速）**：Task 1（Gradle 調整）與 Task 3（手冊文檔）可並行進行，再收斂至 Task 2（Workflow 建立）與 Task 4（全量校驗）。
