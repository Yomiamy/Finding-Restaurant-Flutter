# 功能規格：升級 flutter_inspector_kit 至最新版 2.8.0

- **日期**：2026-10-29
- **狀態**：草稿（STAGE 0a）
- **實查基線**：`main` @ `b78a332e`
- **需求來源**：使用者指令 `/gen-dev-workflow 將flutter_inspector更新至最新版`（依 `gen-grill` 需求短路判定：屬於依賴版本升級之機械性改動，Q1–Q4 短路，Q5 實查通過）

---

## 1. 背景與問題

### 1.1 現況（實查）

- `pubspec.yaml:29` 宣告依賴為：
  ```yaml
  flutter_inspector_kit: ^2.3.0
  ```
- `pubspec.lock:84` 目前鎖定版本為 `2.5.0`。
- 執行 `flutter pub outdated` 實查結果：
  - `flutter_inspector_kit`: Current `2.5.0` | Upgradable `2.8.0` | Resolvable `2.8.0` | Latest `2.8.0`。
- 本專案內目前引用 `flutter_inspector_kit` 之程式碼共有 3 處：
  1. `lib/app/di/inspector.dart:2`：實例化 `FlutterInspector`（以 `kDebugMode` 圍住）。
  2. `lib/main.dart:8,98,157`：使用 `inspector!.navigatorObserver` 與 `FlutterInspectorMagicalTap` 包裹主題。
  3. `lib/api/api_clz.dart:3,180`：在 Dio interceptor 加入 `FlutterInspectorDioInterceptor`。
- 專案所有引用點均已嚴格遵循 `kDebugMode` 防護，release build 恆為 `null` 且被 tree-shaking 移除，不影響 release bundle。

### 1.2 為什麼要升級

`flutter_inspector_kit` 自 `2.5.0` 到 `2.8.0` 帶來了多項核心除錯增強與缺陷修復：
1. **2.6.0**：JSON body 與日誌結構化資料支援可摺疊樹狀視圖（collapsible tree）與關鍵字搜尋。
2. **2.7.0**：路由參數解析（`queryParams` / `argParams`）、RenderFlex overflow 自動解析與定位標籤、畫面邊界檢查切換（layout boundary overlay）。
3. **2.8.0**：凍結幀偵測（Frozen frame capture）、點擊檢查佈局結構（Tap-to-inspect layout）、網路重發結果即時狀態提示、修復 binary payload 記憶體飆高與 Android 背景記憶體警告誤報等問題。

升級至 `2.8.0` 可直接提升本專案開發階段的除錯效率與穩定性。

### 1.3 【核心判斷】

**值得做。**
- **實用性**：單純升級除錯依賴版本，為零業務邏輯侵入、零架構破壞之維護型任務。
- **好品味與相容性**：`flutter_inspector_kit` 2.8.0 完全向後相容 2.5.0 之既有 API（建構子與攔截器簽章一致）。
- **零破壞風險**：既有呼叫端程式碼無需改動；發布版本中依然被 `kDebugMode` 完全隔離。

---

## 2. 使用者故事與驗收條件 (AC)

### 2.1 使用者故事
身為開發者，我希望在開發除錯環境下使用最新版 `flutter_inspector_kit` (v2.8.0)，以便在檢測網路請求、路由切換及 UI 佈局異常時獲得更完整的診斷資訊與流暢體驗。

### 2.2 驗收條件 (Acceptance Criteria)

- **AC-1：版本定義更新**：`pubspec.yaml` 中的 `flutter_inspector_kit` 版本約束更新為 `^2.8.0`。
- **AC-2：依賴解析成功**：執行 `flutter pub get` 能順利解析，`pubspec.lock` 鎖定版本更新為 `2.8.0`，且無任何套件版本衝突。
- **AC-3：型別與靜態分析無誤**：執行 `flutter analyze` 必須為 0 error、0 warning。既有 `lib/app/di/inspector.dart`、`lib/main.dart`、`lib/api/api_clz.dart` 編譯無誤。
- **AC-4：測試回歸通過**：既有單元測試與 Widget 測試（`flutter test`）必須全數通過。
- **AC-5：Release 隔離性不變**：維持 `kDebugMode` 與 `tree-shaking` 防護，不破壞生產環境。

---

## 3. 範圍邊界 (Out of Scope)

1. **不升級其他無關套件**：本次僅針對 `flutter_inspector_kit` 升級，不連帶升級 `pubspec.yaml` 中的其他 30+ 個直接依賴（避免造成不必要的相依性連鎖風險）。
2. **不強制改動既有 UI 程式碼**：2.8.0 的新 opt-in 功能（如 `capturePerformance: true`）留待後續依需求開啟，本次以無痛相容升級為唯一目標。
