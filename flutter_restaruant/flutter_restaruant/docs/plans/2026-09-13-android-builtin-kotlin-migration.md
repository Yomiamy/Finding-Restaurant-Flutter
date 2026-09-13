# Implementation Plan: Android Built-in Kotlin 遷移 (移除顯式 KGP)

## 1. 簡介與架構考量 (Overview & Architectural Rationale)

本實作計畫旨在落實功能規格 [2026-09-13-android-builtin-kotlin-migration.md](file:///Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant/docs/features/2026-09-13-android-builtin-kotlin-migration.md)，將專案 Android 構建系統遷移至 Flutter 官方託管的 Built-in Kotlin 模式，消滅構建時的棄用警告，並預防未來 Flutter SDK 升級時產生的編譯阻斷。

### Linus 模式架構原則
- **消除特殊情況**：不再由 app 模組各自手動宣告 `kotlin-android`，統一交由 Flutter Gradle Plugin (FGP) 的內建機制管理。
- **向後兼容性 (Never break userspace)**：
  - 專案根目錄 [android/settings.gradle](file:///Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant/android/settings.gradle) 必須維持 `id "org.jetbrains.kotlin.android" version "2.2.20" apply false`，以提供 Kotlin 2.2.20 編譯器到 root classpath。
  - [android/app/build.gradle](file:///Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant/android/app/build.gradle) 內的 `kotlinOptions { jvmTarget = 17 }` 與 `sourceSets` 保持不變，確保字節碼相容性與原始碼路徑正常。
- **最短 Diff (YAGNI)**：
  - 本次改動僅修改 `android/app/build.gradle` 移除 1 行宣告。
  - 不對 Gradle 或 AGP 進行非必要升級，不改動 Dart 業務代碼。

---

## 2. 檔案異動清單 (File Changes)

- **`android/app/build.gradle`**：
  - 移除 `plugins` 區塊中的 `id "kotlin-android"`。
  - 保留：
    ```groovy
    plugins {
        id "com.android.application"
        id "dev.flutter.flutter-gradle-plugin"
        //id "com.google.gms.google-services"
    }
    ```

---

## 3. 任務拆分 (Tasks Breakdown)

- [ ] **Task 1: 移除 `android/app/build.gradle` 中的顯式 `id "kotlin-android"`**
  - 編輯 `android/app/build.gradle`，刪除第 3 行的 `id "kotlin-android"`。
  - 確認其他 Gradle 配置（`compileOptions`、`kotlinOptions`、`sourceSets`）完整保留。

- [ ] **Task 2: 執行 Android 乾淨編譯與 FGP 警告驗證**
  - 在 `android/` 目錄執行 `./gradlew clean` 清理快取。
  - 執行 `./gradlew assembleDebug`（或在根目錄執行 `flutter build apk --debug`）。
  - 檢視構建輸出日誌，確認完全不存在 `WARNING: Your Android app project: app ... applies the Kotlin Gradle Plugin`。
  - 確認構建產物 `app-debug.apk` 成功生成，狀態為 `BUILD SUCCESSFUL`。

- [ ] **Task 3: 靜態分析與自動化測試驗證**
  - 執行 `flutter analyze`，確認保持 `No issues found!`。
  - 執行 `flutter test`，確認現有測試全數通過。

---

## 4. 驗收標準 (Verification)

- [ ] **警告消除**：建置日誌中無任何 `applies the Kotlin Gradle Plugin` 相關 Deprecation Warning。
- [ ] **建置成功**：`./gradlew assembleDebug` 返回 exit code 0，`BUILD SUCCESSFUL`。
- [ ] **無回歸**：
  - `flutter analyze` 零錯誤與警告。
  - `flutter test` 全數通過。
