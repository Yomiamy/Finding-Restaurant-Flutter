# AGP 9 Built-in Kotlin 遷移評估報告

**日期：** 2026-08-23
**狀態：** 🔴 擱置 (Blocked by Ecosystem)

## 背景

隨著 Android Gradle Plugin (AGP) 9.0+ 的演進，Kotlin 支援已被直接內建於 AGP 中 (`android.builtInKotlin=true`)。Flutter 開發環境建議移除專案內 `settings.gradle` 及 `app/build.gradle` 顯式的 `kotlin-android` 宣告，以符合未來規範並減少編譯衝突。

然而，在嘗試遷移時，專案遇到了與第三方套件（Plugins）依賴機制的嚴重衝突。

## 調研發現

我們盤點了本專案的 11 個第三方 Flutter 套件（針對其 Pub 上的**最新版本**原始碼進行分析），發現生態系統目前針對 AGP 9 的相容性處於混亂的過渡期。依據實作方式可分為三類：

### 1. 條件式相容（正確實作）
✅ **代表套件：** `firebase_storage` (13.4.6), `firebase_analytics` (12.4.6)
✅ **現況：** 已感知 `android.builtInKotlin` 旗標。只有在 Flutter 專案主動宣告 `android.builtInKotlin=false`（或 AGP 版本低於 9）時，才會 apply KGP。這提供了最穩健的向後與向前相容性。
```groovy
def builtInKotlin = providers.gradleProperty("android.builtInKotlin")
if (!builtInKotlin) {
    apply plugin: 'kotlin-android'
}
```

### 2. 獨立宣告（潛在風險）
⚠️ **代表套件：** `camera_android_camerax`, `google_maps_flutter_android`, `url_launcher_android` 等 Flutter 官方維護套件。
⚠️ **現況：** 這些套件最新版本不再依賴專案根目錄的 `settings.gradle` 提供 KGP，而是改為在自己的 `build.gradle.kts` 中硬編碼並依賴特定版本的 Kotlin Gradle Plugin。
雖然不會因為我們移除專案層級的 KGP 而直接編譯失敗，但這可能導致 AGP 內建的 Kotlin 版本與套件私自下載的 KGP 發生衝突。

### 3. 未遷移且無相容邏輯（致命阻礙）
❌ **代表套件：** `fluttertoast` (10.0.0), `sign_in_with_apple` (8.1.0)
❌ **現況：** 原始碼中依然無條件寫死 `apply plugin: 'kotlin-android'`，完全無視 AGP 9 的變化。
**影響：** 只要我們在專案根目錄的 `settings.gradle` 移除 KGP 宣告，編譯到這些套件時就會立刻因為找不到 `kotlin-android` plugin 而崩潰（拋出 `Could not find method kotlinOptions()` 或 plugin not found 錯誤）。

## 決策與建議

基於「Never break userspace」的實用主義原則，我們**不應該**在此刻強行推進遷移。

1. **維持現狀：** 
   - 保持 `android/gradle.properties` 中的 `android.builtInKotlin=false`。
   - 保留 `android/settings.gradle` 與 `android/app/build.gradle` 中顯式的 KGP 宣告 (`org.jetbrains.kotlin.android`)。
   - 這正是 Flutter 官方提供 `builtInKotlin=false` 這個逃生艙 (Escape hatch) 的目的。
2. **後續追蹤：**
   - 關注 `fluttertoast` 與 `sign_in_with_apple` 兩個阻礙套件的版本更新。
   - 定期執行 `flutter pub outdated`。當社群全面捨棄無條件的 `apply plugin: 'kotlin-android'` 後，再一次性完成專案的 Kotlin 遷移。
   - 預計在 AGP 10.0 釋出前（屆時 `builtInKotlin=false` 的相容模式可能被拔除），必須完成此技術債的清理。
