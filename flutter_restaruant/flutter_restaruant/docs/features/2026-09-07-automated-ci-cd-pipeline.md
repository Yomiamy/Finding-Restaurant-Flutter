# Feature: 自動化 CI/CD 發布流水線 (Automated CI/CD Pipeline - GitHub Actions)

> 項目編號：**F-0.1A**  
> 優先級別：**P0（絕對最高優先／基礎設施地基）**  
> 建立日期：2026-09-07  
> 參考架構：`taroko_app/.github/workflows/release.yml`（完全淘汰 Fastlane，純原生 CLI + GitHub Actions）  
> 發布方案：**方案 B（Dev 路線雙平台均走 Firebase App Distribution，Prd 路線走 Google Play + TestFlight）**  
> 狀態：草稿（待確認）

---

## 1. 背景與動機 (Why)

### 1.1 現狀痛點
1. **人工打包繁瑣且脆弱**：
   - 目前 App 發布仰賴本機環境執行打包。本機環境差異（Java、Xcode、Flutter SDK 版本）常導致建置不一致或難以重現的神秘問題。
   - 舊有 Fastlane 腳本相依 Ruby、Bundler 與多個第三方外掛，建置時間長且維護負擔重。
2. **多平台與多管道發布缺乏單一權威流水線**：
   - 專案先前僅有針對 Android 測試版之舊版 workflow（`.github/workflows/android-tag-build.yml`），格式為 `rc/android-**`，未涵蓋 iOS 平台，更缺乏正式版本（Google Play Console / Apple TestFlight）的自動化發布。
   - 缺乏與 `pubspec.yaml` 版號強校驗的 Git 標籤發布標準。

### 1.2 改造目標 (Linus 實用主義模式)
參照 `taroko_app` 的簡潔架構，建立純原生 CLI 的 **GitHub Actions CI/CD 自動化發布流水線**：
- **徹底移除 Fastlane 依賴**：Android 使用原生 `flutter build` + `upload-google-play` / Firebase Action；iOS 使用原生 `flutter build` + `xcodebuild archive` + `xcodebuild -exportArchive` / Firebase Action。零 Ruby、零 Bundler、零 Fastfile。
- **宣告式 Git Tag 觸發與版號守門**：
  - 標籤命名完全對齊 `taroko_app` 標準（`prod-v*`, `dev-android-v*`, `dev-ios-v*`）。
  - 自動驗證 Git Tag 版本號與 `pubspec.yaml` 內之 `version` 完全一致，防範版號漂移。
- **發布路線清晰分離**：
  - **`prod-v*`（正式版雙平台）**：Android 打包 AAB 上傳至 **Google Play Console (Internal Testing)**；iOS 打包 App Store Archive 上傳至 **Apple TestFlight**。
  - **`dev-android-v*`（開發版 Android）**：打包 APK 上傳至 **Firebase App Distribution**。
  - **`dev-ios-v*`（開發版 iOS）**：打包 Ad Hoc IPA 上傳至 **Firebase App Distribution**。
- **機密零洩漏 (Zero-Leak Security)**：簽名金鑰、憑證、Provisioning Profile 與 API Key 全數透過 GitHub Secrets 安全注入。

---

## 2. 規格需求 (What)

### 2.1 觸發條件與 Git Tag 命名規範

流水線由 **Git Tag Push** 觸發：

| 發布類型 (Release Type) | Git Tag 格式範例 | 建置產物 | 簽名模式 (Signing) | 發布目標通道 |
| :--- | :--- | :--- | :--- | :--- |
| **正式版雙平台 (prod)** | `prod-v2.0.1+33` | Android: Release AAB<br>iOS: App Store Archive | Android: Release Keystore<br>iOS: App Store Profile | 🤖 **Google Play Console** (Internal Testing)<br>🍎 **Apple Store Connect** (TestFlight) |
| **開發版 Android (dev-android)** | `dev-android-v2.0.1+33` | Android: Release APK | Android: Release Keystore | 🔥 **Firebase App Distribution**<br>(App ID: `1:35224406241:android:00f352bb5d635a1b924fa0`) |
| **開發版 iOS (dev-ios)** | `dev-ios-v2.0.1+33` | iOS: Ad Hoc IPA | iOS: **Ad Hoc Profile**<br>(包含測試機 UDID) | 🔥 **Firebase App Distribution**<br>(App ID: `1:35224406241:ios:d8eb3d68795bc2d1924fa0`) |

> **版本號解析與守門機制**：
> 1. 由 Tag 提取 `VERSION`（如 `2.0.1+33`），並比對 `pubspec.yaml` 中的 `version`。不一致時立即以 `exit 1` 阻斷。
> 2. 自動切分 `VERSION_NAME`（`2.0.1`）與 `BUILD_NUMBER`（`33`）。

---

### 2.2 流水線架構與執行步驟 (`.github/workflows/release.yml`)

流水線運行於 `macos-14`：

1. **Check out & 環境設置**：
   - `actions/checkout@v4`。
   - 解析 Tag 類型與版號（`parse_tag`）。
   - 驗證 `pubspec.yaml` 版本號是否一致。
   - `actions/setup-java@v4` (Java 17, temurin)。
   - `subosito/flutter-action@v2` (channel: stable, cache: true)。
   - 於 `flutter_restaruant/flutter_restaruant` 執行 `flutter pub get`。

2. **Android 建置與上傳**（僅於 `prod` 或 `dev-android` 執行）：
   - 解碼 Android Keystore 至 `android/app/release.keystore`。
   - 寫入 `android/key.properties`（提供 storePassword, keyPassword, keyAlias, storeFile）。
   - **`prod` 路線**：
     - 執行 `flutter build appbundle --release` 產生 AAB。
     - 使用 `r0adkll/upload-google-play@v1` 上傳至 Google Play Internal Testing（憑證：`secrets.GOOGLE_PLAY_JSON`，套件名：`com.yomi.flutter_restaruant`）。
   - **`dev-android` 路線**：
     - 執行 `flutter build apk --release` 產生 APK。
     - 使用 `wzieba/Firebase-Distribution-Github-Action@v1` 上傳至 Firebase App Distribution（App ID：`1:35224406241:android:00f352bb5d635a1b924fa0`，憑證：`secrets.FIREBASE_SERVICE_ACCOUNT_JSON`）。

3. **iOS 建置與上傳**（僅於 `prod` 或 `dev-ios` 執行）：
   - 解碼憑證 `certificate.p12`。
   - **Profile 解碼分流**：
     - 若為 `prod`：解碼 `IOS_APPSTORE_PROFILE_BASE64` 為 `profile.mobileprovision`。
     - 若為 `dev-ios`：解碼 `IOS_ADHOC_PROFILE_BASE64` 為 `profile.mobileprovision`。
   - 建立臨時鑰匙圈（`temp.keychain`）並匯入憑證。
   - 透過 `/usr/libexec/PlistBuddy` 動態解析 Provisioning Profile 取得 `UUID`、`Name`、`TeamIdentifier`。
   - 安裝描述檔至 `~/Library/MobileDevice/Provisioning Profiles/$PROFILE_UUID.mobileprovision`。
   - 執行 `flutter build ios --release --no-codesign`。
   - 呼叫原生 `xcodebuild` 建立 Archive（`CODE_SIGN_STYLE=Manual`, `CODE_SIGN_IDENTITY="Apple Distribution"`）。
   - **Export 與上傳分流**：
     - **`prod` 路線**：
       - 生成 `ExportOptions.plist`（`method: app-store-connect`）。
       - 注入 App Store Connect API Key（`AuthKey_${APPLE_API_KEY_ID}.p8`）。
       - 呼叫 `xcodebuild -exportArchive` 直連上傳至 TestFlight。
     - **`dev-ios` 路線**：
       - 生成 `ExportOptions.plist`（`method: ad-hoc`, `compileBitcode: false`）。
       - 呼叫 `xcodebuild -exportArchive` 產出 `Runner.ipa`。
       - 使用 `wzieba/Firebase-Distribution-Github-Action@v1` 上傳至 Firebase App Distribution（App ID：`1:35224406241:ios:d8eb3d68795bc2d1924fa0`，憑證：`secrets.FIREBASE_SERVICE_ACCOUNT_JSON`）。

4. **發布摘要 (Release Summary)**：
   - 輸出成功發布資訊與版本詳情。

---

### 2.3 GitHub Secrets 安全矩陣清單（方案 B 共 13 個）

#### 🤖 Android 相關 Secrets（共 6 個）
| # | Secret 名稱 | 適用發布路線 | 內容格式 | 說明與範例 |
| :-: | :--- | :--- | :--- | :--- |
| **1** | `ANDROID_KEYSTORE_BASE64` | `prod`, `dev-android` | Base64 字串 | Android Release Keystore 金鑰檔 base64 |
| **2** | `ANDROID_KEYSTORE_PASSWORD` | `prod`, `dev-android` | 明文字串 | Keystore 金鑰庫儲存密碼 |
| **3** | `ANDROID_KEY_ALIAS` | `prod`, `dev-android` | 明文字串 | Keystore 簽名金鑰別名 |
| **4** | `ANDROID_KEY_PASSWORD` | `prod`, `dev-android` | 明文字串 | Keystore 金鑰別名密碼 |
| **5** | `GOOGLE_PLAY_JSON` | `prod` | JSON 文本 | Google Play Console API 服務帳號 JSON |
| **6** | `FIREBASE_SERVICE_ACCOUNT_JSON` | `dev-android`, `dev-ios` | JSON 文本 | Firebase 服務帳號 JSON（具備 App Distribution 權限） |

#### 🍎 iOS 相關 Secrets（共 7 個）
| # | Secret 名稱 | 適用發布路線 | 內容格式 | 說明與範例 |
| :-: | :--- | :--- | :--- | :--- |
| **7** | `IOS_CERTIFICATE_BASE64` | `prod`, `dev-ios` | Base64 字串 | Apple Distribution 憑證 .p12 檔 base64 |
| **8** | `IOS_CERTIFICATE_PASSWORD` | `prod`, `dev-ios` | 明文字串 | .p12 憑證匯出密碼 |
| **9** | `IOS_APPSTORE_PROFILE_BASE64` | `prod` | Base64 字串 | App Store 類型的 Provisioning Profile（.mobileprovision）base64 |
| **10** | `IOS_ADHOC_PROFILE_BASE64` | `dev-ios` | Base64 字串 | Ad Hoc 類型的 Provisioning Profile（含測試機 UDID）base64 |
| **11** | `APPLE_API_KEY_ID` | `prod` | 明文字串 | App Store Connect API Key ID（例如: `ABCD1234EF`） |
| **12** | `APPLE_API_ISSUER_ID` | `prod` | UUID 字串 | App Store Connect Issuer ID |
| **13** | `APPLE_API_KEY_CONTENTS` | `prod` | PEM 文本 | App Store Connect API 私鑰內容（`AuthKey_*.p8`） |

---

## 3. 驗收條件 (Acceptance Criteria)

- [ ] **Workflow 檔案就緒**：
  - [ ] 於專案根目錄建立 [`.github/workflows/release.yml`](../../../.github/workflows/release.yml)。
  - [ ] 工作目錄正確適應 `flutter_restaruant/flutter_restaruant`。
- [ ] **淘汰 Fastlane**：
  - [ ] 不依賴 Ruby/Bundler/Fastlane，全流程使用純 CLI 與標準 GitHub Actions。
- [ ] **Tag 格式與版號守門**：
  - [ ] 支援 `prod-v*`、`dev-android-v*`、`dev-ios-v*`。
  - [ ] Tag 版本與 `pubspec.yaml` 不符時自動中斷。
- [ ] **各發布路線正確分流執行**：
  - [ ] `prod-v*`：Android 產出 AAB 上傳 Google Play；iOS 使用 App Store Profile 產出 Archive 直連上傳 TestFlight。
  - [ ] `dev-android-v*`：產出 APK 上傳 Firebase App Distribution。
  - [ ] `dev-ios-v*`：使用 Ad Hoc Profile 產出 Ad Hoc IPA 並上傳 Firebase App Distribution。
- [ ] **品質保證**：
  - [ ] `flutter analyze` 保持 `No issues found!`。

---

## 4. 範圍邊界 (Scope Boundary)

- **In-Scope（本次涵蓋）**：
  - `.github/workflows/release.yml` 完整架構實作。
  - 調整 `android/app/build.gradle` 支援 `key.properties` 簽名設定讀取。
  - 更新發布指引文件與 13 個 Secrets 設定清單。
- **Out-of-Scope（本次排除）**：
  - 舊有 `fastlane/` 目錄的歷史檔案刪除（本次零依賴即可，無需主動刪除歷史目錄）。
  - PR 靜態檢查 CI。
  - 業務代碼變更。
