# 實作計畫：iOS UIScene Lifecycle 支援遷移

> 對應功能規格：`docs/features/2026-08-23-ios-uiscene-lifecycle.md`

## 資料結構分析

本次遷移**不涉及 Dart 側資料結構**。核心改動發生在 iOS native 層的兩個檔案：

| 檔案 | 角色 | 改動性質 |
|------|------|---------|
| `ios/Runner/AppDelegate.swift` | App lifecycle 入口 | Protocol conformance + plugin 註冊位置搬移 |
| `ios/Runner/Info.plist` | App 設定宣告 | 新增 `UIApplicationSceneManifest` 區段 |

## 任務拆分

### T1：更新 Info.plist — 新增 UIApplicationSceneManifest（機械性）

**寫入檔案**：`ios/Runner/Info.plist`

**具體操作**：

在 `Info.plist` 的 `<dict>` 頂層新增 `UIApplicationSceneManifest` 區段：

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
    <key>UISceneConfigurations</key>
    <dict>
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneClassName</key>
                <string>UIWindowScene</string>
                <key>UISceneConfigurationName</key>
                <string>Default Configuration</string>
                <key>UISceneDelegateClassName</key>
                <string>FlutterSceneDelegate</string>
                <key>UISceneStoryboardFile</key>
                <string>Main</string>
            </dict>
        </array>
    </dict>
</dict>
```

**要點**：
- `UIApplicationSupportsMultipleScenes` 設為 `false`（不支援 iPad 多視窗，與現有行為一致）
- `UISceneClassName` 設定為 `UIWindowScene`
- `UISceneDelegateClassName` 直接使用 Flutter 內建的 `FlutterSceneDelegate`（⚠️ 切勿加上 `$(PRODUCT_MODULE_NAME).` 前綴，否則系統會去 Runner module 找不到該類別）
- `UISceneStoryboardFile` 指向既有 `Main`（保留現有 storyboard 入口）
- 保留 `UIMainStoryboardFile` key（向後兼容 iOS 15 以下場景，雖然 Podfile 已設 15.0）

**複雜度**：機械性（1 檔、純 XML 插入）

### T2：重構 AppDelegate.swift — 遷移至 FlutterImplicitEngineDelegate（需整合協調）

**寫入檔案**：`ios/Runner/AppDelegate.swift`

**具體操作**：

將現有 AppDelegate 從：
```swift
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey("AIzaSyAfe5kOHB_-GPPNovB8iCDimCBnTsW6OYQ")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

改為：
```swift
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    GMSServices.provideAPIKey("AIzaSyAfe5kOHB_-GPPNovB8iCDimCBnTsW6OYQ")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
      completionHandler([.alert, .sound, .badge])
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
```

**關鍵變更說明**：

1. **新增 `FlutterImplicitEngineDelegate` protocol conformance**
2. **`GeneratedPluginRegistrant.register(with:)` 搬至 `didInitializeImplicitFlutterEngine`**——從 `self` 改為 `engineBridge.pluginRegistry`
3. **`GMSServices.provideAPIKey()` 留在 `didFinishLaunchingWithOptions`**——這是 process-level 初始化，不依賴 UI lifecycle，留原處正確
4. **保留 `UNUserNotificationCenter` delegate 的設定與實作**——推播設定屬於 App 啟動級別的服務，與 Scene 無關。**嚴禁移除**，否則會破壞前景推播與 `flutter_local_notifications` 依賴的行為。

**複雜度**：需整合協調（涉及 plugin 註冊時序）

### T3：驗證構建與功能（機械性）

**不寫入新檔案**——純驗證步驟

1. `flutter clean && flutter pub get`
2. `flutter build ios --no-codesign`——確認構建成功、無 warning
3. `flutter test`——確認既有測試全部通過
4. 檢查構建 log 中無 `UIScene` 相關 deprecation warning

**複雜度**：機械性

## 任務依賴

```
T1 (Info.plist) ──┐
                   ├──→ T3 (驗證)
T2 (AppDelegate) ─┘
```

T1 與 T2 **可並行**（寫入路徑不重疊），T3 依賴兩者都完成。

## 風險與緩解

| 風險 | 機率 | 緩解 |
|------|------|------|
| `FlutterImplicitEngineDelegate` 不存在（Flutter SDK 版本不夠新） | 低（SDK ≥3.10.1 對應 Flutter 3.41+） | T3 構建時立即發現，降級為手動 Scene manifest + 保留原 plugin 註冊方式 |
| FCM 前景通知失效 | 極低 | `UNUserNotificationCenter.delegate = self` 已正確保留，理論上不受影響 |
| Google Maps 初始化失敗 | 極低 | `GMSServices.provideAPIKey` 留在 `didFinishLaunchingWithOptions`，與 UIScene 無關 |
