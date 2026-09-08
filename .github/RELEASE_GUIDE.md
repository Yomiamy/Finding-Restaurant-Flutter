# GitHub Actions 自動化 CI/CD 發布與 Secrets 設定手冊

本手冊規範專案使用純原生 CLI（`flutter`、`xcodebuild`）進行自動化建置與分發的流程與設定。全流程不依賴 Fastlane 或 Ruby 環境。

---

## 1. 發布流程概覽 (Overview)

流水線定義於 [`.github/workflows/release.yml`](workflows/release.yml)，支援由 Git Tag 或手動 (`workflow_dispatch`) 觸發。

### 支援的發布類型與分發通道

| 發布類型 | 觸發 Tag 格式範例 | 建置產物 | 發布目標通道 |
|:---|:---|:---|:---|
| **正式版雙平台** (`prod`) | `prod-v2.0.1+33` | Android AAB<br>iOS Archive | 🤖 Google Play Console (Internal Testing)<br>🍎 Apple TestFlight |
| **正式版 Android** (`prod-android`) | `prod-android-v2.0.1+33` | Android AAB | 🤖 Google Play Console (Internal Testing) |
| **正式版 iOS** (`prod-ios`) | `prod-ios-v2.0.1+33` | iOS Archive | 🍎 Apple TestFlight |
| **Android 開發版** (`dev-android`) | `dev-android-v2.0.1+33` | Android Release APK | 🔥 Firebase App Distribution |
| **iOS 開發版** (`dev-ios`) | `dev-ios-v2.0.1+33` | iOS Ad Hoc IPA | 🔥 Firebase App Distribution |

> [!IMPORTANT]
> **版本號強校驗守門**：
> 工作流的第一步會嚴格比對 Tag 中的版本號與 `flutter_restaruant/flutter_restaruant/pubspec.yaml` 內的 `version:` 是否完全一致。若不一致將立即中止發布，防止版號混亂。

---

## 2. GitHub Secrets 配置清單 (共 13 個)

請在 GitHub 儲存庫的 **Settings $\rightarrow$ Secrets and variables $\rightarrow$ Actions** 中配置下列 13 個 Repository Secrets。

### 🤖 Android 相關 Secrets (6 個)

| Secret 名稱 | 說明 | 格式與範例 | 產生指令 / 取得方式 |
|:---|:---|:---|:---|
| `ANDROID_KEYSTORE_BASE64` | Android Release Keystore (`.keystore` 或 `.jks`) 的 Base64 字串 | Base64 單行字串 | `base64 -i release.keystore \| tr -d '\n'` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore 儲存密碼 (`storePassword`) | 明文密碼字串 | 建立 Keystore 時設定之密碼 |
| `ANDROID_KEY_ALIAS` | Key 別名 (`keyAlias`) | 字串 (如 `upload` 或 `key0`) | 建立 Keystore 時設定之別名 |
| `ANDROID_KEY_PASSWORD` | Key 密碼 (`keyPassword`) | 明文密碼字串 | 建立 Key 時設定之密碼 |
| `GOOGLE_PLAY_JSON` | Google Play Console API Service Account 金鑰 JSON 全文 | JSON 純文字 | Google Cloud Console $\rightarrow$ Service Account 金鑰 (具有 Play Console 發布權限) |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Firebase 服務帳號金鑰 JSON 全文 (供 App Distribution 使用) | JSON 純文字 | Firebase Console $\rightarrow$ Project Settings $\rightarrow$ Service Accounts $\rightarrow$ Generate private key |

### 🍎 iOS 相關 Secrets (7 個)

| Secret 名稱 | 說明 | 格式與範例 | 產生指令 / 取得方式 |
|:---|:---|:---|:---|
| `IOS_CERTIFICATE_BASE64` | Apple Distribution 憑證與私鑰匯出檔 (`.p12`) 之 Base64 字串 | Base64 單行字串 | `base64 -i Certificates.p12 \| tr -d '\n'` |
| `IOS_CERTIFICATE_PASSWORD` | `.p12` 憑證的保護密碼 | 明文密碼字串 | 從 macOS 鑰匙圈匯出 `.p12` 時設定之密碼 |
| `IOS_APPSTORE_PROFILE_BASE64` | App Store 類型 Provisioning Profile 之 Base64 字串（供 `prod` 上傳 TestFlight） | Base64 單行字串 | `base64 -i AppStore.mobileprovision \| tr -d '\n'` |
| `IOS_ADHOC_PROFILE_BASE64` | Ad Hoc 類型 Provisioning Profile 之 Base64 字串（供 `dev-ios` 匯出 Ad Hoc IPA 上傳 Firebase） | Base64 單行字串 | `base64 -i AdHoc.mobileprovision \| tr -d '\n'` |
| `APPLE_API_KEY_ID` | App Store Connect API Key ID | 10 碼字串 (如 `2X9R4HXF34`) | App Store Connect $\rightarrow$ 使用者與存取 $\rightarrow$ 整合 $\rightarrow$ 密鑰 |
| `APPLE_API_ISSUER_ID` | App Store Connect API Issuer ID | UUID 字串 (如 `57246542-96fe-1a63-e053-0824d011072a`) | 同上頁面頂部顯示之 Issuer ID |
| `APPLE_API_KEY_CONTENTS` | App Store Connect API 私鑰內容 (`AuthKey_*.p8`) | 純文字（含 BEGIN/END PRIVATE KEY 標籤） | 下載之 `AuthKey_*.p8` 檔案內容全文 |

> [!CAUTION]
> **Ad Hoc Profile 與 App Store Profile 的關鍵差異**：
> - 上傳 Firebase App Distribution 的 IPA **不可使用 App Store Profile**。因為缺少裝置 UDID 白名單，iOS 裝置直接從 Firebase 下載後將因無有效簽名授權而無法啟動。
> - `IOS_ADHOC_PROFILE_BASE64` 必須在 Apple Developer 網站中將團隊內部測試裝置的 UDID 納入 Profile 註冊清單中。

---

## 3. 應用程式 ID 與專案識別資訊

流水線預設配置之識別碼如下：

- **Android Package Name**: `com.yomi.flutter_restaruant`
- **Android Firebase App ID**: `1:35224406241:android:00f352bb5d635a1b924fa0`
- **iOS Bundle Identifier**: `com.yomi.find-restaurant`
- **iOS Firebase App ID**: `1:35224406241:ios:d8eb3d68795bc2d1924fa0`

---

## 4. 發布作業流程 (Step-by-Step Guide)

### 步驟 1: 更新版號

在 `flutter_restaruant/flutter_restaruant/pubspec.yaml` 中確認或遞增版號：

```yaml
version: 2.0.1+33
```

- `2.0.1` 為版本名稱 (`versionName` / `CFBundleShortVersionString`)。
- `33` 為建置號碼 (`versionCode` / `CFBundleVersion`)。每次發布請確保遞增建置號。

### 步驟 2: 提交代碼並推送到遠端

```bash
git add flutter_restaruant/flutter_restaruant/pubspec.yaml
git commit -m "chore: bump version to 2.0.1+33"
git push origin main
```

### 步驟 3: 建立並推送對應 Tag

依欲發布的通道選擇對應的 Tag 指令：

#### 方案 A-1：正式發布雙平台（Google Play Internal + Apple TestFlight）
```bash
git tag prod-v2.0.1+33
git push origin prod-v2.0.1+33
```

#### 方案 A-2：正式發布僅 Android（Google Play Internal）
```bash
git tag prod-android-v2.0.1+33
git push origin prod-android-v2.0.1+33
```

#### 方案 A-3：正式發布僅 iOS（Apple TestFlight）
```bash
git tag prod-ios-v2.0.1+33
git push origin prod-ios-v2.0.1+33
```

#### 方案 B：Android 開發版（Firebase App Distribution）
```bash
git tag dev-android-v2.0.1+33
git push origin dev-android-v2.0.1+33
```

#### 方案 C：iOS 開發版（Firebase App Distribution）
```bash
git tag dev-ios-v2.0.1+33
git push origin dev-ios-v2.0.1+33
```

### 步驟 4: 監看 CI/CD 執行進度

1. 前往 GitHub 儲存庫的 **Actions** 分頁。
2. 點擊進入最新觸發的 **Build and Release** 工作流。
3. 觀察建置、代碼簽章與上傳日誌。
4. 執行成功後可在摘要頁面檢視 Release Summary。

---

## 5. 手動觸發 (workflow_dispatch)

若需針對既有 Commit 重跑特定發布：

1. 前往 GitHub **Actions** $\rightarrow$ **Build and Release**。
2. 點擊 **Run workflow** 下拉選單。
3. 選擇分支（例如 `main`）。
4. 在 `Tag name` 輸入框輸入對應規格的 Tag 名稱（例如 `prod-v2.0.1+33` 或 `dev-android-v2.0.1+33`）。
5. 點擊 **Run workflow** 啟動執行。

---

## 6. 常見錯誤與排查 (Troubleshooting)

### Q1: `❌ 錯誤: Tag (...) 與 pubspec.yaml (...) 版號不一致`
- **原因**：推送的 Tag 版本與 `pubspec.yaml` 內之 `version` 不符。
- **解法**：確認兩者一致後再打 Tag，或修改 `pubspec.yaml` 後重新 push tag。

### Q2: `❌ xcodebuild archive 失敗` 或憑證找不到
- **原因**：`IOS_CERTIFICATE_BASE64` 解碼失敗、密碼錯誤，或 Profile 名稱/Team ID 與憑證不吻合。
- **解法**：確認 `.p12` 匯出時包含私鑰，且密碼與 `IOS_CERTIFICATE_PASSWORD` 一致。工作流中的 `Setup iOS Signing & Profile` 步驟會自動解析 Profile 的 UUID、名稱與 Team ID。

### Q3: iOS 測試人員無法安裝 Firebase 的測試版本
- **原因**：使用了 App Store Profile 匯出，或 Ad Hoc Profile 未將該裝置的 UDID 加入。
- **解法**：確認 `dev-ios` 使用的是 `IOS_ADHOC_PROFILE_BASE64`，並在 Apple Developer 網站中將該裝置的 UDID 註冊並重新下載產生 Ad Hoc Profile。

### Q4: Google Play 上傳失敗 (`Google Api Error: ...`)
- **原因**：`GOOGLE_PLAY_JSON` Service Account 權限不足，或該 App 尚未在 Play Console 建立或未手動上傳過第一次 AAB。
- **解法**：新建立之 App 必須由開發者手動在 Play Console 上傳第一個版本後，Google Play API 方能生效後續的自動化上傳。
