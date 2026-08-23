# F-0.3 iOS UIScene Lifecycle 支援遷移

## 背景

Apple 在 WWDC25 宣布：**iOS 26 之後的版本**，使用最新 SDK 構建但未採用 UIScene lifecycle 的 UIKit App 將**無法啟動**。Flutter 3.41 已內建自動遷移支援（`UIScene` 為預設），但因本專案 AppDelegate 有客製化邏輯（GoogleMaps API key、UNUserNotificationCenter delegate），**自動遷移可能不完整，需手動介入**。

## 使用者故事

**作為** iOS 使用者，  
**我希望** App 在 iOS 26 及後續版本上正常啟動，  
**以便** 不因 Apple 的 UIScene lifecycle 強制要求而無法使用 App。

**作為** 開發者，  
**我希望** 完成 UIScene lifecycle 遷移，  
**以便** App 能通過 Xcode 17+ SDK 構建且符合 Apple 最新要求，同時維持 firebase_messaging（FCM）、google_maps_flutter、local_auth、flutter_local_notifications 等既有功能正常運作。

## 現況分析

### 當前 iOS 架構

| 項目 | 現狀 | 問題 |
|------|------|------|
| AppDelegate | 繼承 `FlutterAppDelegate`，於 `didFinishLaunchingWithOptions` 中註冊 plugin、設定 GMSServices API key、設定 `UNUserNotificationCenter.delegate` | **未遵循 UIScene lifecycle**：plugin 註冊不應在此處 |
| Info.plist | 無 `UIApplicationSceneManifest` 區段 | **缺少 Scene manifest 宣告** |
| Info.plist | 有 `UIMainStoryboardFile: Main` | UIScene 模式下 storyboard 入口改由 Scene manifest 控管 |
| SceneDelegate | 不存在 | 需新建或由 Flutter framework 內部處理 |
| Main.storyboard | 存在，含 `FlutterViewController` 作為 `initialViewController` | UIScene 模式下 window 由 `UIWindowScene` 管理 |
| Podfile | `platform :ios, '15.0'` | iOS 15+ 已完整支援 UIScene，無需升版 |

### 涉及 AppDelegate 的關鍵套件

| 套件 | 與 AppDelegate 的交互 | 遷移影響 |
|------|----------------------|---------|
| `firebase_messaging` | 需要 `UNUserNotificationCenter.delegate`、`didRegisterForRemoteNotifications` | **中風險**：delegate 設定屬 process-level 初始化，與 UI lifecycle 無關，應保留於 `didFinishLaunchingWithOptions` 以免破壞推播功能 |
| `google_maps_flutter` | 需要 `GMSServices.provideAPIKey()` | **低風險**：API key 設定與 UI lifecycle 無關，可留在 `didFinishLaunchingWithOptions` |
| `flutter_local_notifications` | 使用 `UNUserNotificationCenter` | 透過 plugin 自動處理，與 AppDelegate 改動相關 |
| `google_mobile_ads` | 需要 AdMob App ID（Info.plist `GADApplicationIdentifier`）| **無影響**：純 plist 設定 |
| `sign_in_with_apple` / `google_sign_in` / `flutter_facebook_auth` | URL scheme 處理 | **低風險**：URL scheme 在 Info.plist `CFBundleURLTypes` 已設定 |

## 驗收條件

1. **App 能在 iOS 15–26+ 上正常啟動**——無 crash、無 console warning 關於 UIScene lifecycle
2. **Info.plist 包含 `UIApplicationSceneManifest`**——正確宣告 Scene Configuration
3. **AppDelegate 遵循 `FlutterImplicitEngineDelegate` protocol**——plugin 註冊移至 `didInitializeImplicitFlutterEngine`
4. **GMSServices API key 仍正確初始化**——Google Maps 功能正常
5. **FCM 推播通知正常運作**——前景/背景推播接收正常
6. **本地推播通知正常運作**——`flutter_local_notifications` 功能正常
7. **所有既有 iOS 功能正常**——相機、Face ID、Google/Apple/Facebook 登入、WebView、AdMob
8. **既有測試全部通過**——`flutter test` 零新增失敗

## 範圍邊界

### 在範圍內

- AppDelegate.swift 重構（`FlutterImplicitEngineDelegate` protocol）
- Info.plist 新增 `UIApplicationSceneManifest` 設定
- 移除或更新 `UIMainStoryboardFile` 設定（若需要）
- 驗證 FCM、Google Maps、Local Notifications 功能正常

### 不在範圍內

- ❌ iPad 多視窗支援（`supportsMultipleScenes`）——超出本次遷移目標
- ❌ Podfile 最低版本升級——iOS 15 已足夠支援 UIScene
- ❌ Main.storyboard 刪除——Flutter framework 可能仍需要它
- ❌ Dart 側程式碼改動——本次遷移純 iOS native 層
- ❌ 新增 SceneDelegate.swift——Flutter 3.41+ 內部自動處理 Scene lifecycle，不需手動新增
