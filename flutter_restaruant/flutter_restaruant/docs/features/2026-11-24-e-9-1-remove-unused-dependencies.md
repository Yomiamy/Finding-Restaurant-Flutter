# 功能規格：E-9.1 移除 4 個零使用相依套件

- **日期**：2026-11-24
- **狀態**：草稿（STAGE 0a）
- **需求來源**：`docs/brainstorm/2026-11-23-features-brainstorm.md` §9.2、§9.5（E-9.1），透過 `/gen-dev-workflow batch` 第 1 項啟動（已通過 `gen-grill` 機械性改動短路與 Q5 實查）

---

## 1. 背景與問題

### 1.1 現況（實查基線）

經實查當前程式碼庫（2026-11-24），`pubspec.yaml` 直接宣告了 4 個**完全未被 `lib/` 與 `test/` import** 的相依套件：

| 套件 | `pubspec.yaml` 宣告行 | `pubspec.lock` 鎖定版本 | `lib/` / `test/` import 數 | 平台相容面影響 |
| :--- | :---: | :---: | :---: | :--- |
| `sqflite` | L35 (`^2.3.0`) | `2.4.4` | 0 | 不支援 Web；原生 iOS/Android/macOS 皆強制註冊 `SqflitePlugin`；並誤導歷史文件記為本地快取 |
| `path_provider` | L37 (`^2.1.3`) | `2.1.6` | 0 | 非直接相依卻由專案鎖定版本約束（若其他套件需要，應由傳遞相依自動解析） |
| `camera` | L42 (`^0.12.0+2`) | `0.12.1` | 0 | 不支援 macOS；拍照功能實際由 `image_picker` 提供（`ImageSource.camera`），`camera` 套件本體零使用，卻拖入 `camera_android_camerax` 與 `camera_avfoundation` 原生插件 |
| `firebase_storage` | L53 (`^13.4.5`) | `13.6.0` | 0 | 無任何 Cloud Storage 讀寫邏輯，卻在 Android / iOS / macOS 註冊 `FlutterFirebaseStoragePlugin` 並打包原生 Firebase Storage SDK |

補充實查確認：
- `lib/` 與 `test/` 中所有 `camera` 關鍵字均屬 `image_picker` 的 `ImageSource.camera`、`platformCapabilities().camera` 能力旗標與 l10n key，與 `package:camera/` 無關。
- `ios/Runner.xcodeproj/project.pbxproj`、`macos/Runner.xcodeproj/project.pbxproj`、`android/app/build.gradle*`、`ios/Podfile.lock`、`macos/Podfile.lock` 均無對此 4 個套件的手動設定或引用；原生端引用僅存在於 Flutter 自動產生的 `GeneratedPluginRegistrant.*` 與 SPM `Package.swift`。

### 1.2 為什麼要做

1. **縮小建置相容面與 App 體積**：移除未使用的原生插件（`camera_android_camerax`、`camera_avfoundation`、`sqflite_android`、`sqflite_darwin`、`firebase_storage` SDK），減少編譯時間、原生相依衝突風險與打包體積。
2. **為跨平台（macOS / Web）掃清無謂阻礙**：`camera` 不支援 macOS、`sqflite` 不支援 Web，兩者都是零使用卻卡住跨平台相依矩陣的歷史遺留。
3. **消除認知與文件誤導**：`pubspec.yaml` 應誠實反映專案實際使用的能力，不再讓人誤以為專案已實作 SQLite 快取或 Cloud Storage 上傳。

### 1.3 【核心判斷】

**值得做。**
- **實用性**：零使用卻持續拖累三平台原生建置與插件註冊，屬於明確的真實技術債。
- **簡潔與零破壞**：僅移除 4 行未被引用的直接宣告並重新執行 `flutter pub get` 同步鎖定檔與自動產生的插件註冊碼；不更動任何業務邏輯、不刪除 `image_picker` 所需的系統相機權限設定。

---

## 2. 使用者故事與驗收條件 (AC)

### 2.1 使用者故事與觸發場景

身為開發者，我希望 `pubspec.yaml` 與原生插件註冊清單不再包含零使用的 `camera`、`sqflite`、`path_provider`、`firebase_storage`，使日常開發、`flutter pub get`、原生建置與跨平台擴展更精簡且無誤導性相依。

### 2.2 驗收條件 (Acceptance Criteria)

- **AC-1：移除直接相依宣告**：`pubspec.yaml` 的 `dependencies` 中不再包含 `sqflite`、`path_provider`、`camera`、`firebase_storage` 4 個條目。
- **AC-2：依賴解析與鎖定同步**：執行 `flutter pub get` 成功無錯誤；`pubspec.lock` 中 `sqflite`、`camera`、`firebase_storage` 及其平台實作子套件（含 `camera_android_camerax`、`camera_avfoundation`、`sqflite_android`、`sqflite_darwin` 等）已移除，且 `path_provider` 不再為 `dependency: "direct main"`（若被其他套件傳遞需要則轉為 `transitive`，否則一併移除）。
- **AC-3：原生插件註冊檔自動更新**：經 `flutter pub get`（或對應建置／套件更新步驟）重新同步後，若有追蹤於 git 中的自動產生檔案（如 `GeneratedPluginRegistrant.*` 等），與 `pubspec.yaml` 保持一致，不殘留已移除套件的無效註冊。
- **AC-4：靜態分析零問題**：`flutter analyze` 通過（0 error / 0 warning）。
- **AC-5：測試全數回歸通過**：`flutter test` 全數通過，且 `MenuVision` 拍照/選圖功能（依賴 `image_picker`）相關測試零回歸。

---

## 3. 範圍邊界 (Out of Scope)

1. **不動原生權限宣告**：不移除 `ios/Runner/Info.plist` 或 `android/app/src/main/AndroidManifest.xml` 中的相機／相簿權限（`image_picker` 的 Menu Vision 拍照功能仍需要）。
2. **不升級或更動其他套件版本**：不執行 `flutter pub upgrade`，不更動其餘無關套件的版本約束與 SDK 約束。
3. **不調整 `firebase_options.dart` 的 `storageBucket` 欄位**：該欄位由 `flutterfire configure` 自動產生，屬 Firebase 專案設定而非 `firebase_storage` Dart 套件相依，維持不變。
4. **不於本 PR 修改 `docs/brainstorm/` 進度狀態**：文件狀態回寫遵循工作流於 PR 合併後的 STAGE 6 統一同步。
