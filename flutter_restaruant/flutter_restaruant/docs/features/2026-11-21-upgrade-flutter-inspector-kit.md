# 功能規格：升級 flutter_inspector_kit 至最新版 3.1.0

- **日期**：2026-11-21
- **狀態**：草稿（STAGE 0a）
- **實查基線**：`main`（`new-main/main` @ `33b9d93f`）
- **需求來源**：使用者需求（已通過 `gen-grill` 盤問與確認；原詢問之 `flutter_inspect_kit` 於 pub.dev 無此套件，專案實際使用與升級目標為 `flutter_inspector_kit`）

---

## 1. 背景與問題

### 1.1 現況（`main` 基線實查）

- `pubspec.yaml`（於 `main`）：
  - `environment`：`sdk: '>=3.10.1 <4.0.0'`、`flutter: '>=3.44.1'`
  - 第 77 行宣告依賴為：
    ```yaml
    flutter_inspector_kit: ^2.9.0 # App 內除錯儀表板 (網路/導航/日誌)，全數以 kDebugMode 圍住
    ```
  - 相關依賴（已於 `main` 存在）：`dio: ^5.6.0`、`flutter_local_notifications: ^22.1.0`
- `pubspec.lock`（於 `main` 第 710–717 行）目前鎖定版本為 `"2.9.0"`（`sha256: bb1e9992bd8e6c0a9fcf5b72dd0598e985b39edb41b5d5630434dc4475496510`）。
- 本專案於 `main` 引用 `flutter_inspector_kit` / `inspector` 的檔案共有 5 處程式檔與 3 處相關測試檔：
  1. `lib/features/utils/inspector/inspector.dart:2,23-39`：以 `kDebugMode ? FlutterInspector(slowRequestThreshold: const Duration(seconds: 2), showNetworkNotification: true, navigatorKey: navigatorKey, captureUncaughtErrors: true, captureLifecycleEvents: true, redactSensitiveData: false) : null` 建立實例，並提供 `registerSharedPreferencesSource([SharedPreferences? prefs])`。
  2. `lib/features/utils/inspector/shared_preferences_source.dart:1`：`KeyValueBrowserSource` 實作 `SharedPreferencesSource`。
  3. `lib/main.dart:8,99-101,155-161`：註冊 `inspector!.navigatorObserver`，並於 `appRootBuilder` 內以 `FlutterInspectorMagicalTap(onTap: () => ins.openDashboard(), child: theme)` 包裹主題。
  4. `lib/api/api_clz.dart:3,178-183`：加入 `FlutterInspectorDioInterceptor(insp, sourceDio: client.dio)`（已傳入 `sourceDio`，與 `3.0.0` 去重機制對齊）。
  5. `lib/flow/splash/view/splash_page.dart:53`：呼叫 `inspector?.attach(context: context)`。
  6. 相關測試：`test/di_test.dart:2,231-244`、`test/app_theme_platform_test.dart:25-65`、`test/features/foundation/style/app_scroll_behavior_test.dart:25-60`。
- 所有呼叫端皆嚴格遵循 `kDebugMode` 防護，release build 不受影響。

### 1.2 為什麼要升級

`flutter_inspector_kit` 於 pub.dev 最新版為 `3.1.0`（發布時間 `2026-11-17T18:10:22.507065Z`；`3.0.0` 發布時間 `2026-11-14T19:38:31.624406Z`），自 `2.9.0` 升級至 `3.1.0` 可帶來下列除錯能力增強，且與 `main` 基線完全相容：

1. **3.0.0 網路除錯增強**：
   - 新增圖片回應預覽（`NetworkEntry.responseImageBytes`）。
   - 新增 multipart body 遮罩摘要。
   - 顯示真實 payload 長度（`NetworkEntry.requestBodyLength` / `responseBodyLength`）。
   - 支援 Dio `sourceDio` 去重與 opt-in `captureHttpClient`（預設關閉）。
2. **3.1.0 UI Layout 檢查增強**：
   - Layout Inspect 支援落點取色（settled-point color sampling `#RRGGBB` swatch 與匯出，搭配 `LayoutProbeShield`）。
3. **依賴與 API 相容性實查**：
   - `3.1.0` 的 pubspec 約束為 `sdk: "^3.10.1"`、`flutter: ">=3.10.0"`，傳遞依賴為 `dio: "^5.2.0"`、`share_plus: "^13.0.0"`、`flutter_local_notifications: "^22.0.0"`、`web: "^1.1.0"`，完全相容於 `main` 基線，無需更動 SDK 或其餘直接依賴。
   - `3.0.0` 唯一 Breaking Change 為 `NetworkOrigin` enum 新增 `NetworkOrigin.httpClient`；經實查專案 `lib/` 與 `test/` 對 `NetworkOrigin` 引用數為 `0`，不構成破壞。

### 1.3 【核心判斷】

**值得做。**
- **實用性**：單純升級除錯依賴版本，零業務邏輯侵入、無需更動 SDK 約束，即可取得圖片回應預覽、真實 payload 長度與 Layout 落點取色等除錯能力。
- **好品味與相容性**：`flutter_inspector_kit` `3.1.0` 與 `main` 基線環境及既有依賴完全相容；`NetworkOrigin` 新增成員對專案影響為 `0`，且 `FlutterInspectorDioInterceptor` 已傳入 `sourceDio`。
- **零破壞風險**：不修改既有呼叫端建構參數與接線；所有入口維持 `kDebugMode` 隔離，release build 不受影響。

---

## 2. 使用者故事與驗收條件 (AC)

### 2.1 使用者故事與觸發場景

身為開發者，我希望於除錯建置（debug build）透過 `FlutterInspectorMagicalTap` 或 dashboard 檢視網路（圖片預覽、payload 長度、multipart 遮罩摘要）與 UI Layout（`3.1.0` Layout Inspect 落點取色）資訊，以提升網路與畫面佈局問題的除錯效率。

### 2.2 驗收條件 (Acceptance Criteria)

- **AC-1：版本約束更新**：`pubspec.yaml` 第 77 行 `flutter_inspector_kit` 版本約束更新為 `^3.1.0`。
- **AC-2：依賴解析與鎖定**：於以 `main` 為基底的新 worktree 執行 `flutter pub get` 成功，且無需更改 SDK 或其餘直接依賴即可解析，使 `pubspec.lock` 鎖定 `flutter_inspector_kit: "3.1.0"`。
- **AC-3：既有引用點與靜態分析無誤**：既有引用點零破壞且 `flutter analyze` 為 0 error / 0 warning。
- **AC-4：測試回歸通過**：既有單元與 Widget 測試（`flutter test`）全數通過（含會觸發 `inspector` 初始化或驗證 `registerSharedPreferencesSource` 的測試）。
- **AC-5：Release 隔離性不變**：維持所有呼叫端以 `kDebugMode` 隔離，release build 不受影響。

---

## 3. 範圍邊界 (Out of Scope)

1. **不開啟 `captureHttpClient` 與不改動既有接線**：不開啟 `3.0.0` 新增之 opt-in `captureHttpClient: true`，亦不修改 `FlutterInspector(...)` 建構參數或 `FlutterInspectorDioInterceptor` 接線。
2. **不連帶升級其他無關套件**：僅升級 `flutter_inspector_kit`，不連帶更動 `pubspec.yaml` 中其他無關套件版本。
3. **不更動 SDK constraint**：不改變 `pubspec.yaml` 的 Dart / Flutter SDK 版本約束，嚴格基於 `main`（`33b9d93f`）基線進行升級。
