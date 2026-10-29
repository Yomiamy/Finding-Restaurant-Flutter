# 實作計畫：升級 flutter_inspector_kit 至最新版 2.8.0

- **建立日期**：2026-10-29
- **對應規格**：`docs/features/2026-10-29-upgrade-flutter-inspector-kit.md`
- **狀態**：等待確認 (Pending Confirmation)

---

## 1. 簡介與目標 (Overview & Goals)

落實功能規格 `docs/features/2026-10-29-upgrade-flutter-inspector-kit.md`：
1. **依賴版本升級**：將 `pubspec.yaml` 中的 `flutter_inspector_kit` 由 `^2.3.0` 更新為 `^2.8.0`。
2. **依賴鎖定更新**：執行 `flutter pub get`，更新 `pubspec.lock` 至 2.8.0，確保無衝突。
3. **編譯與回歸驗證**：驗證呼叫端（`lib/app/di/inspector.dart`, `lib/main.dart`, `lib/api/api_clz.dart`）完全相容，執行 `flutter analyze` 與 `flutter test` 確保 100% 通過。

---

## 2. 檔案異動清單 (File Changes)

### 2.1 修改檔案
- `pubspec.yaml`：
  - 更新 `flutter_inspector_kit: ^2.8.0`。
- `pubspec.lock`：
  - 經由 `flutter pub get` 自動更新鎖定版本為 `2.8.0` 及對應 content hash。

---

## 3. 實作任務拆分 (Tasks)

### 任務 1：更新 pubspec.yaml 並執行 flutter pub get
- **內容**：
  - 修改 `pubspec.yaml:29`：`flutter_inspector_kit: ^2.8.0`。
  - 執行 `flutter pub get`，確認依賴順利下載並更新 `pubspec.lock`。
- **驗證**：
  - 檢查 `pubspec.lock` 中 `flutter_inspector_kit` 的 `version` 為 `"2.8.0"`。

### 任務 2：相容性確認、靜態分析與回歸測試
- **內容**：
  - 檢查既有引用點：
    - `lib/app/di/inspector.dart`
    - `lib/main.dart`
    - `lib/api/api_clz.dart`
  - 執行 `flutter analyze` 確保無任何編譯錯誤、deprecation 警告或 lint 違規。
  - 執行 `flutter test` 確保全數既有單元與 Widget 測試通過。
- **驗證**：
  - `flutter analyze` 輸出：`No issues found!`
  - `flutter test` 全綠通過。

---

## 4. 驗收標準 (Acceptance Criteria)

1. `pubspec.yaml` 明確指定 `flutter_inspector_kit: ^2.8.0`。
2. `pubspec.lock` 鎖定在 `2.8.0`。
3. `flutter analyze` 0 error / 0 warning。
4. 全案 `flutter test` 通過。
5. 生產環境建置防護不變（`kDebugMode` 隔離與 tree-shaking 有效）。
