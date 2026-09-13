# Feature: Android Built-in Kotlin 遷移 (移除 app 模組顯式 KGP)

## 1. 背景與動機 (Why)

在 Flutter 構建系統持續演進下，Flutter Gradle Plugin (FGP) 引入了 Built-in Kotlin 支援機制。
在當前 Flutter SDK (3.44.1) 環境下，當 Android 專案建置時，FGP (`FlutterPluginUtils.kt`) 會掃描 `android/app/build.gradle`。若在 `plugins {}` 區塊中檢測到顯式宣告的 `id "kotlin-android"`，建置日誌將出現以下 Deprecation Warning：

```text
WARNING: Your Android app project: app ... applies the Kotlin Gradle Plugin, which will cause build failures in future versions of Flutter.
Please update your project to use Flutter's built-in Kotlin support.
```

官方已明確預告在未來的 Flutter 版本中，此警告將升級為強制建置錯誤 (Build Failure)。
為了確保 Android 建置鏈的長期穩定性與技術債清償，需將應用程式模組遷移至 Flutter 官方推薦的 Built-in Kotlin 架構。

---

## 2. 機制解析與技術洞察 (Mechanism & Technical Insight)

### 2.1. Flutter Built-in Kotlin 機制本質
經研讀 Flutter SDK 源碼（`flutter_tools/gradle/src/main/kotlin/FlutterPluginUtils.kt` 第 600~680 行）：
1. **警告觸發條件**：FGP 使用正則表達式（Groovy / KTS）檢查 `app/build.gradle` 是否包含 `id "kotlin-android"` 或 `id("kotlin-android")`。若 `hasKgpPlugin == true`，則拋出警告。
2. **自動託管行為**：若 app 模組**未顯式宣告** `id "kotlin-android"`，FGP 會自動執行 `pluginManager.apply("kotlin-android")`，為 app 模組安全注入 Kotlin 編譯支援。
3. **根目錄依賴要求**：FGP 明確提示：「若專案包含 Kotlin 原始碼，必須確保根目錄 `settings.gradle` 之 `plugins {}` 區塊宣告了 KGP（`org.jetbrains.kotlin.android ... apply false`）」。

### 2.2. Linus 哲學與最小改動原則 (Minimal Diff & Anti-Breakage)
- **避免過度工程 (YAGNI)**：此遷移與 Google AGP 9 的實驗性 `android.builtInKotlin=true` 無關。我們不需要升級 AGP 9，也不需要改動現有 AGP 8.11.1 或 Gradle 8.14.1。
- **神聖不可侵犯的向後兼容性**：保留 `android/settings.gradle` 中的 `id "org.jetbrains.kotlin.android" version "2.2.20" apply false`，確保編譯器版本嚴格鎖定於 Kotlin 2.2.20，保證所有依賴 Kotlin 2.x 的第三方 Plugin 編譯一致性。

---

## 3. 規格需求 (What)

### 3.1. 移除 app 模組顯式宣告
- 修改 [android/app/build.gradle](file:///Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant/android/app/build.gradle)：
  - 從 `plugins {}` 區塊中安全移除 `id "kotlin-android"`。
  - 保留 `id "com.android.application"` 與 `id "dev.flutter.flutter-gradle-plugin"`。

### 3.2. 維持原始碼目錄與 JVM 目標配置
- 保留 `android/app/build.gradle` 內的 `sourceSets { main.java.srcDirs += 'src/main/kotlin' }`，確保 `MainActivity.kt` 正常被編譯。
- 保留 `kotlinOptions { jvmTarget = 17 }` 與 `compileOptions`（Java 17），確保字節碼目標一致。

### 3.3. 維持根層級 Classpath 宣告
- [android/settings.gradle](file:///Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant/android/settings.gradle) 保持不變：
  - 繼續保留 `id "org.jetbrains.kotlin.android" version "2.2.20" apply false`。

---

## 4. 驗收條件 (Acceptance Criteria)

- [ ] **消滅官方警告**：執行 `./gradlew assembleDebug` 或 `flutter build apk --debug` 時，日誌不再出現 `WARNING: Your Android app project: app ... applies the Kotlin Gradle Plugin`。
- [ ] **Android 原生編譯成功**：Gradle 建置狀態為 `BUILD SUCCESSFUL`，生成目標 APK。
- [ ] **Kotlin 2.2.20 編譯正常**：專案原生代碼（`MainActivity.kt`）及所有 32 個原生 Plugin（如 `google_maps_flutter_android`、`shared_preferences_android` 等）正確完成 Kotlin 任務編譯。
- [ ] **零破壞性回歸**：
  - `flutter analyze` 零錯誤 (`No issues found!`)。
  - 既有單元與 Widget 測試全數通過 (`flutter test`)。

---

## 5. 範圍邊界 (Scope Boundary)

- **In-Scope**:
  - `android/app/build.gradle` 移除 `id "kotlin-android"`。
  - 執行 Android 乾淨編譯驗證（驗證 warning 消失且 build 成功）。
- **Out-of-Scope**:
  - 不更動 `android/settings.gradle`（保留 KGP 2.2.20 與 AGP 8.11.1）。
  - 不強制升級或替換 `fluttertoast` 9.1.0（經審查，其內部雖然有宣告，但作為 subproject 庫模組不阻擋主 app 的 FGP 判定；為避免非必要的回歸風險，保持原樣）。
  - 不修改任何 Flutter / Dart 端業務邏輯。
