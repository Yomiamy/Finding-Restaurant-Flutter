# 實作計畫：升級 flutter_inspector_kit 至最新版 3.1.0

> **給執行者（For agentic workers）：** 本計畫於 STAGE 1 依 `main`（`new-main/main` @ `33b9d93f`）建立的獨立 worktree 內執行。依 `delegation-and-parallel.md` 派發煞車契約，本計畫為單一 `[原地修改]` 微任務（`total_tasks = 1`），須由執行進程在該 worktree 原地完成（或於綁定該 worktree 的乾淨獨立 session 以 `executing-plans` 原地依步驟執行）；**嚴禁派發 `implementer` 或獨立 `verifier` subagent**。步驟以核取方塊（`- [ ]`）追蹤進度。

- **建立日期**：2026-11-21
- **對應規格**：[`docs/features/2026-11-21-upgrade-flutter-inspector-kit.md`](../features/2026-11-21-upgrade-flutter-inspector-kit.md)
- **實查基線**：`main`（`new-main/main` @ `33b9d93f`）
- **狀態**：🟡 修訂版 3（STAGE 0b，依 `plan-verifier` 再審意見修正）

**Goal：** 在 STAGE 1 依 `main`（`33b9d93f`）建立的獨立 worktree 中，將 `flutter_inspector_kit` 由 `^2.9.0`（鎖定 `"2.9.0"`）安全升級至 `^3.1.0`（鎖定 `"3.1.0"`），並於原地驗證 `pubspec.lock` 三層邊界、既有呼叫端、靜態分析與回歸測試全數通過。

**Architecture：** 維持所有既有的除錯接線與 `kDebugMode` 防護不變，僅更新 `pubspec.yaml` 第 77 行版本約束並透過 `flutter pub get` 重新鎖定 `pubspec.lock`；不更動 Dart/Flutter SDK 約束，不修改任何 `lib/` 與 `test/` 程式碼。

**Tech Stack：** Flutter (`pubspec.yaml` `>=3.44.1`), Dart (`pubspec.yaml` `>=3.10.1 <4.0.0`), `flutter_inspector_kit: ^3.1.0`, `dio: ^5.6.0`, `flutter_local_notifications: ^22.1.0`

**Spec：** [`docs/features/2026-11-21-upgrade-flutter-inspector-kit.md`](../features/2026-11-21-upgrade-flutter-inspector-kit.md)

## Global Constraints

- 所有實作與驗證必須在 STAGE 1 從 `main`（`new-main/main` @ `33b9d93f`）建立之新 worktree 內執行。
- `pubspec.yaml` `environment` 維持 `sdk: '>=3.10.1 <4.0.0'` 與 `flutter: '>=3.44.1'`，且 `pubspec.lock` 檔尾 `sdks:` 維持 `main` 基線（`dart: ">=3.13.0 <4.0.0"`、`flutter: ">=3.47.0"`），不得更改 SDK 約束或連帶升級其他無關直接套件。
- 不開啟 `3.0.0` 新增之 opt-in `captureHttpClient: true`，亦不修改 `FlutterInspector(...)` 建構參數或 `FlutterInspectorDioInterceptor` 接線。
- 維持所有呼叫端以 `kDebugMode` 隔離，release build 不受影響。

---

## 1. 設計取捨分析（Approaches & Trade-offs）

| 實作方向 | 作法 | 優點 | 缺點 / 風險 | 結論 |
|---|---|---|---|---|
| **方案 A：純依賴版本升級（維持既有接線）** | 僅修改 `pubspec.yaml:77` 為 `flutter_inspector_kit: ^3.1.0` 並執行 `flutter pub get` 鎖定 `pubspec.lock`；`lib/` 與 `test/` 零改動 | 1. 符合規格 AC-1～AC-5 與 YAGNI 原則<br>2. 零業務與測試程式碼異動，風險極低<br>3. `lib/api/api_clz.dart` 已傳入 `sourceDio: client.dio`，直接享有 `3.0.0` 去重、圖片預覽、payload 長度與 `3.1.0` 落點取色能力<br>4. 一行指令即可完整回滾 | 未啟用 opt-in `captureHttpClient: true`（不攔截非 Dio 的 raw `HttpClient` 請求），但規格 §3 已明定不開啟 | **採用** |
| **方案 B：升級並啟用 `captureHttpClient: true` 或重構接線／調升依賴** | 除更新版號外，同步修改 `lib/features/utils/inspector/inspector.dart` 開啟 `captureHttpClient: true`，或一併調整其他直接依賴／SDK 約束 | 可額外擷取 `dart:io` `HttpClient` 層請求 | 1. 違反規格 §3 Out of Scope 與 YAGNI<br>2. 變更擴散至 `lib/` 與測試行為（`HttpOverrides` 可能干擾既有單元／Widget 測試環境）<br>3. 增加無謂回歸風險與審查成本 | **不採用** |

**決策依據：** `flutter_inspector_kit` `3.1.0` 的 `sdk`/`flutter` 與傳遞依賴約束（`sdk: "^3.10.1"`, `flutter: ">=3.10.0"`, `dio: "^5.2.0"`, `share_plus: "^13.0.0"`, `flutter_local_notifications: "^22.0.0"`, `web: "^1.1.0"`）完全落在本專案 `main` 基線範圍內；且 `3.0.0` 唯一 Breaking Change（`NetworkOrigin.httpClient`）在專案 `lib/` 與 `test/` 引用數為 `0`。因此方案 A 為最簡潔、零破壞且可直接交付驗證的最佳路徑。

---

## 2. 檔案異動清單（File Changes）

於 STAGE 1 建立的 `main`（`33b9d93f`）基準 worktree 中，預期異動範圍嚴格限定如下：

### 2.1 修改檔案

| 檔案 | 異動方式 | 變更內容 |
|---|---|---|
| `pubspec.yaml` | 人工編輯（1 行） | 第 77 行 `flutter_inspector_kit: ^2.9.0` 更新為 `flutter_inspector_kit: ^3.1.0`（保留原有註解 `# App 內除錯儀表板 (網路/導航/日誌)，全數以 kDebugMode 圍住`） |
| `pubspec.lock` | 指令自動更新 | 執行 `flutter pub get` 後更新，以 `flutter_inspector_kit` 段落（由 `"2.9.0"` 更新為 `"3.1.0"` 及對應 `sha256`）為主，且必須通過 Task 1 Step 4 的 `git diff pubspec.lock` 三層邊界檢查（其他 `direct main` / `direct dev` 直接依賴版本完全不變、檔尾 `sdks:` 與 `main` 基線 `dart: ">=3.13.0 <4.0.0"` / `flutter: ">=3.47.0"` 完全一致、任何 `transitive` 傳遞依賴異動須可經 `flutter pub deps --style=compact` 溯源至 `flutter_inspector_kit: 3.1.0` 約束且無無關／大版本連帶升級） |

### 2.2 唯讀驗證清單（禁止修改）

- `lib/features/utils/inspector/inspector.dart:2,23-39`
- `lib/features/utils/inspector/shared_preferences_source.dart:1`
- `lib/main.dart:8,99-101,155-161`
- `lib/api/api_clz.dart:3,178-183`
- `lib/flow/splash/view/splash_page.dart:53`
- `test/di_test.dart:2,231-244`、`test/app_theme_platform_test.dart:25-65`、`test/features/foundation/style/app_scroll_behavior_test.dart:25-60`

---

## 3. 實作任務拆分（Tasks）

> **複雜度與任務收斂說明（`total_tasks = 1`）：** 依 `delegation-and-parallel.md` 派發煞車原則，微任務條件為「單檔 ≤ 20 行且無公共 API 變更」，並配套「微任務驗收例外」（由主進程原地完成修改與測試驗證，不派發 `implementer` 或獨立 `verifier` subagent）。本計畫人工編輯僅觸及 `pubspec.yaml` 單檔 1 行且無任何 Dart 公共 API 變更，`pubspec.lock` 則為 `flutter pub get` 對該單行調整所產生的工具衍生鎖定輸出。為避免在無測試證據前中途暫停，本計畫收斂為**單一 `[原地修改]` 微任務（Task 1）**，於 STAGE 1 新 worktree 內一次閉環完成 Pre-check、版號更新、`flutter pub get`、`git diff pubspec.lock` 三層邊界檢核、呼叫端核對、靜態分析與全案 `flutter test`（預估總耗時 4–5 分鐘）。

---

### Task 1：升級 `flutter_inspector_kit` 至 `^3.1.0` 並完成 `pubspec.lock` 邊界與回歸驗證 `[原地修改]`

**Files:**
- Modify: `pubspec.yaml:77`
- Generated Update: `pubspec.lock`（以 `flutter_inspector_kit` 段落為主，由 `flutter pub get` 自動更新並受 `git diff pubspec.lock` 三層邊界檢查約束）
- Read-only verification targets:
  - `lib/features/utils/inspector/inspector.dart:2,23-39`
  - `lib/features/utils/inspector/shared_preferences_source.dart:1`
  - `lib/main.dart:8,99-101,155-161`
  - `lib/api/api_clz.dart:3,178-183`
  - `lib/flow/splash/view/splash_page.dart:53`
  - `test/di_test.dart:2,231-244`
  - `test/app_theme_platform_test.dart:25-65`
  - `test/features/foundation/style/app_scroll_behavior_test.dart:25-60`

**Interfaces:**
- Consumes: `main`（`33b9d93f`）worktree 既有 `pubspec.yaml`、`pubspec.lock`、`analysis_options.yaml` 與既有 5 處 `lib/` 呼叫端 / 3 處相關測試
- Produces: 解析鎖定 `flutter_inspector_kit: "3.1.0"` 且通過三層 lockfile 邊界、靜態分析（`--no-fatal-infos` 0 error / 0 warning 且無新增 `info`）與全案 `flutter test` 的乾淨工作區狀態

- [ ] **Step 1：確認 worktree 基線狀態、目前 `pubspec.lock` `sdks:`、`NetworkOrigin` 零引用與靜態分析基線（Pre-check）**

於 STAGE 1 新建立的 worktree 根目錄執行：

```bash
git status --short --branch
grep -nE "sdk:|flutter:|flutter_inspector_kit" pubspec.yaml
grep -n -A 7 "flutter_inspector_kit:" pubspec.lock
tail -n 10 pubspec.lock
grep -rn "NetworkOrigin" lib/ test/ || echo "NO_NETWORK_ORIGIN_REF"
flutter analyze --no-fatal-infos
flutter analyze || true
```

**預期輸出與基線紀錄：**
- `git status` 顯示位於 STAGE 1 新分支且工作區乾淨（無未預期變更）。
- `pubspec.yaml` 含 `sdk: '>=3.10.1 <4.0.0'`、`flutter: '>=3.44.1'`，第 77 行爲 `flutter_inspector_kit: ^2.9.0 # App 內除錯儀表板 (網路/導航/日誌)，全數以 kDebugMode 圍住`。
- `pubspec.lock` 中 `flutter_inspector_kit` 目前 `version: "2.9.0"`；檔尾 `sdks:` 區段為 `dart: ">=3.13.0 <4.0.0"` 與 `flutter: ">=3.47.0"`，記錄為 Step 4 嚴格比對基線。
- `grep -rn "NetworkOrigin" lib/ test/` 輸出 `NO_NETWORK_ORIGIN_REF`（0 引用）。
- `flutter analyze --no-fatal-infos` 基線必須 exit code `0`（確認升級前已為 0 error / 0 warning）。
- `flutter analyze || true` 僅用來記錄升級前 `main` worktree 完整的 error / warning / info 清單（供 Step 6 比對），非零 exit code 不擋 Pre-check。

- [ ] **Step 2：修改 `pubspec.yaml` 第 77 行版本約束**

使用編輯工具修改 `pubspec.yaml` 第 77 行：

```yaml
# Before
  flutter_inspector_kit: ^2.9.0 # App 內除錯儀表板 (網路/導航/日誌)，全數以 kDebugMode 圍住

# After
  flutter_inspector_kit: ^3.1.0 # App 內除錯儀表板 (網路/導航/日誌)，全數以 kDebugMode 圍住
```

- [ ] **Step 3：執行 `flutter pub get` 解析與鎖定依賴**

```bash
flutter pub get
```

**預期輸出：**
- 指令 exit code 為 `0`，輸出含 `Got dependencies!`（或顯示 `flutter_inspector_kit 3.1.0` 更新訊息），無 version solving failed 或 SDK mismatch 錯誤。

- [ ] **Step 4：核對 `pubspec.yaml` 與 `pubspec.lock` 三層邊界（AC-1、AC-2 驗證）**

```bash
git diff pubspec.yaml
grep -n -A 7 "flutter_inspector_kit:" pubspec.lock
git diff pubspec.lock
tail -n 10 pubspec.lock
```

若 `git diff pubspec.lock` 出現除 `flutter_inspector_kit` 外的任何 `transitive` 傳遞依賴異動，接續執行溯源指令（必要時搭配檢查 `.dart_tool/package_config.json` 或 pub cache 中 `flutter_inspector_kit` `3.1.0` 的 `pubspec.yaml`）：

```bash
flutter pub deps --style=compact
```

**可證偽驗收標準（Step 4 全部成立才可進入 Step 5）：**
1. **`pubspec.yaml` 與主套件鎖定精準度**：`git diff pubspec.yaml` 僅有第 77 行從 `^2.9.0` 變更為 `^3.1.0`，SDK constraint 與其他套件約束完全未動；`pubspec.lock` 中 `flutter_inspector_kit` 的 `version:` 為 `"3.1.0"`。
2. **其他直接依賴完全不變**：`git diff pubspec.lock` 中，除 `flutter_inspector_kit` 外，所有標記為 `dependency: "direct main"` 或 `dependency: "direct dev"` 的既有直接依賴（含 `dio`、`flutter_local_notifications` 等）版本完全不變（無升級、降級或增刪）。
3. **`sdks:` 區段與 `main` `pubspec.lock` 基線完全一致**：`git diff pubspec.lock` 中檔尾 `sdks:` 區段不得出現任何下限上調或異動，必須與 Step 1 `tail -n 10 pubspec.lock` 記錄的 `main` `pubspec.lock` 基線（`dart: ">=3.13.0 <4.0.0"`、`flutter: ">=3.47.0"`）完全一致。
4. **`transitive` 傳遞依賴溯源受控**：若 `git diff pubspec.lock` 出現標記為 `dependency: transitive` 的傳遞依賴異動（例如 `share_plus`、`web` 及其子依賴），須透過 `flutter pub deps --style=compact`（必要時搭配檢查 `.dart_tool/package_config.json` 或 `flutter_inspector_kit` `3.1.0` 的 `pubspec.yaml`）溯源證明該異動確由 `flutter_inspector_kit: 3.1.0` 約束直接引發，且無無關套件或大版本連帶升級。

**Step 4 失敗／漂移回滾方式：**
只要 `flutter pub get` 失敗，或違反上述任一條（未授權直接依賴變動、`sdks:` 區段偏離 `main` 基線 `dart: ">=3.13.0 <4.0.0"` / `flutter: ">=3.47.0"`、出現無法溯源至 `flutter_inspector_kit: 3.1.0` 的傳遞依賴或大版本連帶升級、或 `flutter_inspector_kit` 未鎖定為 `"3.1.0"`），**立即執行回滾並回報中止**：

```bash
git checkout -- pubspec.yaml pubspec.lock
flutter pub get
```

- [ ] **Step 5：核對既有呼叫端 `kDebugMode` 隔離、`KeyValueBrowserSource` 與 `sourceDio` 接線（AC-5、Out of Scope 確認）**

```bash
grep -nE "kDebugMode|FlutterInspector|flutter_inspector_kit|KeyValueBrowserSource|inspector|sourceDio|captureHttpClient" \
  lib/features/utils/inspector/inspector.dart \
  lib/features/utils/inspector/shared_preferences_source.dart \
  lib/main.dart \
  lib/api/api_clz.dart \
  lib/flow/splash/view/splash_page.dart
```

**預期輸出：**
- `lib/features/utils/inspector/inspector.dart` 維持 `import 'package:flutter_inspector_kit/flutter_inspector_kit.dart';` 與 `kDebugMode ? FlutterInspector(...) : null`，未新增 `captureHttpClient: true`。
- `lib/features/utils/inspector/shared_preferences_source.dart` 命中 `flutter_inspector_kit` import 與 `KeyValueBrowserSource` 實作定義（確保無空掃）。
- `lib/api/api_clz.dart` 維持 `FlutterInspectorDioInterceptor(insp, sourceDio: client.dio)`。
- `lib/main.dart` 與 `lib/flow/splash/view/splash_page.dart` 維持原有接線與 `kDebugMode` 隔離語意不變。

- [ ] **Step 6：執行靜態分析（AC-3 驗證，依 `analysis_options.yaml` 校準）**

```bash
flutter analyze --no-fatal-infos
flutter analyze || true
```

**可證偽驗收標準（對齊規格 AC-3 與 `analysis_options.yaml:14-17`）：**
1. **`--no-fatal-infos` 門檻（0 error / 0 warning）**：`flutter analyze --no-fatal-infos` exit code 必須為 `0`。
2. **零新增 `info` 門檻**：`flutter analyze || true` 輸出與 Step 1 基線清單相比，不得新增任何 `info`（含 `deprecated_member_use`）。唯有當 Step 1 基線為 `No issues found!` 時，才要求裸 `flutter analyze` exit code `0` 且輸出 `No issues found!`；若 Step 1 基線已有既有 `info`，不誤判為本次失敗，但只要因升級新增任何 `error`、`warning` 或 `info`（含 `deprecated_member_use`），立即視為失敗並觸發回滾。

- [ ] **Step 7：優先執行涵蓋 `inspector` 與 `registerSharedPreferencesSource` 的相關測試（快速回饋）**

```bash
flutter test \
  test/di_test.dart \
  test/app_theme_platform_test.dart \
  test/features/foundation/style/app_scroll_behavior_test.dart
```

**預期輸出：**
- 指令 exit code 為 `0`，3 支測試檔案全數通過（`All tests passed!`），無 runtime exception。

- [ ] **Step 8：執行全案單元與 Widget 回歸測試（AC-4 驗證）**

```bash
flutter test
```

**預期輸出：**
- 指令 exit code 為 `0`，全案測試 100% 通過（`All tests passed!`，0 failed）。

- [ ] **Step 9：最終異動邊界與工作區清潔度檢查**

```bash
git status --short
git diff --stat
```

**可證偽驗收標準（Step 9）：**
1. `git status --short` 與 `git diff --stat` 僅包含 `pubspec.yaml` 與 `pubspec.lock`。
2. `lib/`、`test/` 與 SDK constraint 異動數為 `0`。

**Step 6～8 失敗回滾方式：**
若靜態分析或任一測試出現由 `flutter_inspector_kit: 3.1.0` 造成的新增 `info`（含 `deprecated_member_use`）／`warning`／`error` 或測試失敗：
1. 完整保留失敗指令與錯誤訊息作為診斷證據。
2. 執行回滾還原基線，確認 `flutter analyze --no-fatal-infos` 回傳 exit code `0`，且 `flutter analyze || true` 的輸出回到 Step 1 基線清單：
   ```bash
   git checkout -- pubspec.yaml pubspec.lock
   flutter pub get
   flutter analyze --no-fatal-infos
   flutter analyze || true
   ```
3. 嚴禁私自修改 `lib/` 或 `test/` 繞過問題；立即停止並向使用者回報失敗原因與影響檔案。

---

## 4. 執行方式選項（Execution Options）

所有實作與驗證皆須於 **STAGE 1 從 `main`（`33b9d93f`）建立之新 worktree** 內進行；依 `delegation-and-parallel.md` 派發煞車與微任務驗收例外契約，提供以下兩種執行路徑：

1. **選項 A：主進程於 STAGE 1 新 worktree 原地執行（推薦）**
   - **適用原因**：本計畫已收斂為單一 `[原地修改]` 微任務（`total_tasks = 1`，手改 `pubspec.yaml` 1 行＋衍生更新 `pubspec.lock`＋原地完成靜態分析與 `flutter test`），符合派發煞車規則與微任務驗收例外。
   - **執行流程**：主進程切換至 STAGE 1 新 worktree 後，依 Step 1 → Step 9 原地一次完成編輯、邊界檢查與全案回歸驗證；**不派發 `implementer` 或獨立 `verifier` subagent**。
2. **選項 B：於綁定該 worktree 的乾淨獨立 session 原地依步驟執行（`executing-plans`）**
   - **適用原因**：若為隔離對話上下文預算而希望另開全新 session 執行，可於**已切換至 STAGE 1 `main` 基準 worktree** 的獨立 session 中，使用 `executing-plans` 依 Step 1 → Step 9 原地完成。依步驟執行完成後仍須依 `gen-dev-workflow` 進入 STAGE 3 `reviewer` 審查，不得依 `executing-plans` 預設跳轉直接結案。
   - **限制**：同樣嚴格遵守派發煞車硬規則，**不派發 `implementer` 或獨立 `verifier` subagent**。

---

## 5. 最終驗收核對表（對應規格 AC-1 ～ AC-5）

- [ ] **AC-1**：`pubspec.yaml` 第 77 行更新為 `flutter_inspector_kit: ^3.1.0`，SDK constraint 與其他直接依賴未更動。
- [ ] **AC-2**：於 `main`（`33b9d93f`）基準新 worktree 執行 `flutter pub get` 成功，`pubspec.lock` 鎖定 `flutter_inspector_kit` 為 `"3.1.0"`，且通過 `git diff pubspec.lock` 三層邊界檢查（其他 `direct main` / `direct dev` 直接依賴版本完全不變、`sdks:` 與 `main` 基線 `dart: ">=3.13.0 <4.0.0"` / `flutter: ">=3.47.0"` 完全一致、任何 `transitive` 傳遞依賴異動可經 `flutter pub deps --style=compact` 溯源至 `flutter_inspector_kit: 3.1.0` 且無無關／大版本連帶升級）。
- [ ] **AC-3**：既有 5 處 `lib/` 引用點零破壞，同時滿足：(a) `flutter analyze --no-fatal-infos` exit code 為 `0`（0 error / 0 warning），且 (b) `flutter analyze || true` 輸出相對於 Step 1 基線零新增 `info`（含 `deprecated_member_use`；僅當 Step 1 基線為 `No issues found!` 時，才要求裸 `flutter analyze` exit code `0` 且輸出 `No issues found!`）。
- [ ] **AC-4**：`flutter test`（含 `test/di_test.dart`、`test/app_theme_platform_test.dart`、`test/features/foundation/style/app_scroll_behavior_test.dart` 及全案）全數通過。
- [ ] **AC-5**：所有呼叫端維持 `kDebugMode` 隔離，release build 不受影響，且未開啟 `captureHttpClient: true`。
