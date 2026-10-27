# 功能規格：A-8.14 Repository 改以建構子注入 `APIClz` 與 `locale`，解除 data 層對 `app/` 與全域 GetIt 的依賴

- **日期**：2026-10-27
- **狀態**：✅ 已完成（Issue #165）。STAGE 3 審查後依使用者要求追加：Main／Detail 轉發測試、`lib/domain/repositories/yelp_category_repository.dart` 註解改寫（AC-6「`lib/domain` 不動」對此一行註解放寬）、`injection.dart` import 分組空行
- **實查基線**：`new-main/main` @ `b78a332`
- **需求來源**：gen-grill brief Q1–Q5，已放行（摘要見 §2.2）
- **相關 brainstorm 項目**：`docs/brainstorm/2026-10-26-features-brainstorm.md` §8.3 [A-8.14]（L1906-1928）
- **相關規格**：`docs/features/2026-10-23-yelp-places-api-coverage.md`（PR #160，新增 4 個 Yelp Repository 的來源）

---

## 1. 背景與問題

### 1.1 現況（實查）

6 個 Repository 在內部直接取用兩個全域依賴：

| 檔案（`lib/data_layer/repositories/`） | `import get_it` | `import app/constants` | 取得 `APIClz` | 使用 `Constants.locale` |
|---|---|---|---|---|
| `main_repo.dart` | :3 | :8 | :52 每次呼叫 `GetIt.I<APIClz>()` | :56 |
| `restaurant_detail_repo.dart` | :3 | :8 | :21、:30 每次呼叫 `GetIt.I<APIClz>()` | :23、:32 |
| `yelp_autocomplete_repo.dart` | :1 | :4 | :10 `api ?? GetIt.I<APIClz>()` | :19 |
| `yelp_business_repo.dart` | :1 | :4 | :15 `api ?? GetIt.I<APIClz>()` | :19、:86、:95 |
| `yelp_category_repo.dart` | :1 | :4 | :10 `api ?? GetIt.I<APIClz>()` | :14、:18 |
| `yelp_event_repo.dart` | :1 | :4 | :13 `api ?? GetIt.I<APIClz>()` | :31、:49、:57 |

- `Constants.locale` 定義在 `lib/app/constants/constants.dart:39`，值為寫死的 `'zh_TW'`（`static const`）。
- `lib/app/di/injection.dart:24-44` 建構這 6 個 Repository 時都沒有傳 `api` 或 `locale`；`MainRepo`、`RestaurantDetailRepo` 只傳了 `favorDataSource`。`injection.dart` 目前沒有 import `app/constants`。
- `APIClz` 在 `injection.dart:13` 註冊為 lazy singleton。`lib/` 內沒有任何地方 unregister、reset 或重新註冊它；只有 `test/di_test.dart:26` 在 `setUpAll` 呼叫 `GetIt.I.reset()` 後再 `setupInjection()`。
- **建構子呼叫點**（完整清單）：
  - `lib/app/di/injection.dart:25,28,40,41,42,44`
  - `test/repository_test.dart:29`（`MainRepo()`）、`:44`（`RestaurantDetailRepo()`）
  - `test/data_layer/yelp_autocomplete_repo_test.dart:23`、`yelp_business_repo_test.dart:43`、`yelp_category_repo_test.dart:24`、`yelp_event_repo_test.dart:24`（皆為 `XxxRepo(api: api)`）
- 4 個 Yelp Repository 測試以 `Constants.locale` 斷言 locale 轉發（例：`yelp_category_repo_test.dart:29,40`），並因此 import `app/constants`。
- `main_repo.dart` 使用的 `logger` 來自 `lib/api/api_clz.dart:186`（經 `api_barrel`），`SortBy` 來自 `lib/models/`，都不依賴 `app/constants`。移除該 import 不會連帶斷掉其他符號。

### 1.2 為什麼是問題

- **反向依賴**：data 層依賴 `app/`（組裝層）。`app/` 應該是唯一知道 `Constants` 與 GetIt 的地方。
- **無法注入 mock**：`MainRepo`、`RestaurantDetailRepo` 沒有 `api` 參數，測試只能透過全域 GetIt 註冊才能替換 `APIClz`。
- **locale 無法以測試驗證**：測試只能用同一個全域常數 `Constants.locale` 斷言，無法證明 Repository 轉發的是「被給的值」而不是「碰巧相同的常數」。
- **語系來源分散**：日後要改語系來源時，得逐一修改 6 個 Repository。

### 1.3 【核心判斷】

**值得做。** 純重構，改動是機械性的，而且 `required` 參數會讓編譯器列出所有呼叫點，漏改會直接編譯失敗。

- **資料結構**：`locale` 與 `APIClz` 的擁有者從「各 Repository 自己去全域拿」改成「`app/di/injection.dart` 決定、往下傳」。資料流變成單向：`Constants.locale`／`getIt<APIClz>()` → `injection.dart` → Repository 欄位 → `APIClz` 呼叫。
- **可消滅的複雜度**：4 個 Yelp Repository 的 `api ?? GetIt.I<APIClz>()` 退路整個刪除。這個退路只服務「沒傳 api」的情況，而改完之後每個呼叫點都一定會傳。
- **最大破壞風險**：`MainRepo`、`RestaurantDetailRepo` 從「每次呼叫才查 GetIt」改成「建構時取得一次」。因為 `APIClz` 是從不重新註冊的 lazy singleton，兩者拿到的是同一個實例，行為不變（見 R-1）。

---

## 2. 使用者故事

### 2.1 故事

1. 身為**開發者**，寫 `MainRepo`／`RestaurantDetailRepo` 的測試時，可以直接在建構子傳入 mock `APIClz`，不必先在全域 GetIt 註冊。
2. 身為**開發者**，寫 Repository 測試時，可以傳入任意 `locale`（例如 `'en_US'`），確認 Repository 轉發的是注入的值。
3. 身為**維護者**，日後要改語系來源時，只需要改 `injection.dart` 一處。

### 2.2 需求 brief 摘要（gen-grill 已放行）

- **Q1 問題**：6 個 Repository 內部直接取用 `Constants.locale` 與 `GetIt.I<APIClz>()`。data 層反向依賴 `app/`，並且綁死全域 service locator。
- **Q2 場景**：
  - 寫 Repository 測試時，只能用全域常數驗證 locale。
  - `MainRepo`／`RestaurantDetailRepo` 需要全域 GetIt 才能取得 API，無法注入 mock。
  - 日後改語系來源，需要逐檔修改 6 個 Repository。
- **Q3 成功標準**：
  - 6 個 Repository 的建構子改為 `required APIClz api, required String locale`；既有的 `FavorDataSource? favorDataSource` 保留原樣。
  - 6 個檔案不再 import `get_it` 與 `app/constants`。
  - `injection.dart` 統一以 `getIt<APIClz>()` 與 `Constants.locale` 注入。
  - `flutter analyze` 零警告，既有測試全過。
  - 4 個 Yelp Repository 測試改用測試自訂的 locale 值（不是 `Constants.locale`）驗證轉發。
  - `test/repository_test.dart` 的 `MainRepo()`／`RestaurantDetailRepo()` 改為傳入 mock api 與 locale。
- **Q4 不做**：見 §4.2。
- **Q5 實查**：見 §1.1。開啟中的 PR #162、#164 都沒有改到本規格的程式碼與測試檔。

---

## 3. 驗收條件

### 3.1 可機械驗證（必須全數通過）

```bash
flutter analyze
flutter test
rtk proxy grep -rn -E "get_it|GetIt" lib/data_layer
rtk proxy grep -rln "app/constants" lib/data_layer
rtk proxy grep -n "Constants" test/data_layer/yelp_autocomplete_repo_test.dart test/data_layer/yelp_business_repo_test.dart test/data_layer/yelp_category_repo_test.dart test/data_layer/yelp_event_repo_test.dart
git diff new-main/main --stat -- pubspec.yaml pubspec.lock test/di_test.dart lib/domain
```

- **AC-1** `flutter analyze` 輸出 `No issues found!`。
- **AC-2** `flutter test` 全綠。
- **AC-3** 第 3 條指令沒有輸出：`lib/data_layer/` 不再有任何 `get_it` import 或 `GetIt` 呼叫。
- **AC-4** 第 4 條指令只輸出 `settings_repo.dart` 與 `sign_in_repo.dart` 兩個檔案（它們使用 `Constants.prefKey*`，不在範圍）。
- **AC-5** 第 5 條指令沒有輸出：4 個 Yelp Repository 測試不再引用 `Constants`。
- **AC-6** 第 6 條指令沒有輸出：不新增相依，不改 `test/di_test.dart`，不改 domain 介面（建構子不屬於介面）。

### 3.2 建構子與注入

- **AC-7** 6 個 Repository 的建構子都是具名參數 `required APIClz api, required String locale`。`MainRepo`、`RestaurantDetailRepo` 另外保留 `FavorDataSource? favorDataSource`，且 `?? FavorDataSource()` 的退路不變。
- **AC-8** 6 個 Repository 內部只透過注入的欄位呼叫 API 與取得 locale。§1.1 表中列出的每一處 `GetIt.I<APIClz>()` 與 `Constants.locale` 都改為使用欄位。
- **AC-9** `MainRepo` 的建構子 body 仍然呼叫 `reset()`。`test/repository_test.dart` 中 `summaryInfoSet` 為空、`reset()` 之後仍為空的既有斷言原樣通過。
- **AC-10** `lib/app/di/injection.dart` 的 6 個 Repository 註冊一律傳入 `api: getIt<APIClz>()` 與 `locale: Constants.locale`。註冊方式維持 `registerLazySingleton`，註冊的型別與順序不變。

### 3.3 測試

- **AC-11** 4 個 Yelp Repository 測試在 `_Data` 宣告測試專用的 locale（值必須不等於 `'zh_TW'`，例如 `'en_US'`），建構時傳入，並以這個值斷言轉發。既有 test case 的數量與名稱語意不變；名稱中的「Constants.locale」改為「注入的 locale」。
- **AC-12** `test/repository_test.dart` 的 `MainRepo`／`RestaurantDetailRepo` 改為傳入 mock `APIClz` 與 locale。mock 類別命名沿用 E-8.7（PR #164）的 `_MockAPIClz` 慣例，使用既有 dev 相依 `mocktail`。該檔的其他 test 不動。

---

## 4. 範圍邊界

### 4.1 In Scope

- 修改 §5 列出的 6 個 Repository、`injection.dart` 與 5 個測試檔。
- 文件同步：完成後把 brainstorm [A-8.14] 的狀態改為已完成，沿用 PR #160／A-8.8 的慣例。

### 4.2 Out of Scope

- **語系來源**：不改，仍然是 `Constants.locale`（`'zh_TW'`）。跟隨裝置語系屬於另案。
- **`favorDataSource` 的注入方式**：不改，`?? FavorDataSource()` 退路保留。
- **`SettingsRepo`、`SignInRepo`**：它們 import `app/constants` 是為了 `Constants.prefKey*`，不在範圍。
- **`AiFoodieRepo`、`MenuVisionRepo`、`ReviewSummaryRepo`、`FavorRepo`**：不動。
- **api 層對 `app/constants` 的依賴**（`lib/api/dio/dio_client.dart:2`、`lib/api/api_clz.dart` 的 `dioClient`）：不動。
- **新增測試覆蓋**：不為 `MainRepo.fetchYelpSearchInfo`、`RestaurantDetailRepo` 的 API 轉發補新測試。本項只讓它們變得可以注入；補測試另案處理。
- **使用者可見行為**：無任何改變。

---

## 5. 受影響檔案

| 類型 | 檔案 |
|------|------|
| 修改 | `lib/data_layer/repositories/main_repo.dart` |
| 修改 | `lib/data_layer/repositories/restaurant_detail_repo.dart` |
| 修改 | `lib/data_layer/repositories/yelp_autocomplete_repo.dart` |
| 修改 | `lib/data_layer/repositories/yelp_business_repo.dart` |
| 修改 | `lib/data_layer/repositories/yelp_category_repo.dart` |
| 修改 | `lib/data_layer/repositories/yelp_event_repo.dart` |
| 修改 | `lib/app/di/injection.dart`（新增 `../constants/constants_barrel.dart` import） |
| 修改 | `test/repository_test.dart` |
| 修改 | `test/data_layer/yelp_{autocomplete,business,category,event}_repo_test.dart` |
| 文件 | `docs/brainstorm/2026-10-26-features-brainstorm.md`（只改 [A-8.14] 的狀態） |

---

## 6. 風險

| # | 風險 | 影響 | 緩解 |
|---|------|------|------|
| R-1 | `MainRepo`、`RestaurantDetailRepo` 從「每次呼叫查 `GetIt.I<APIClz>()`」改為「建構時取得一次」。如果有人在執行期重新註冊 `APIClz`，Repository 會拿著舊實例 | 理論上會打到舊的 Dio | `lib/` 內沒有任何 unregister、reset 或重新註冊（§1.1），兩種寫法拿到的是同一個 lazy singleton。接受 |
| R-2 | `APIClz`／`DioClient` 的建立時機提前：從「第一次 fetch」提前到「`MainRepository` 第一次被解析」（`routes_table.dart:26` 建立 `MainBloc` 時） | 如果 `DioClient` 建構時讀取了尚未初始化的設定，會帶到錯的值 | 實查不受影響：Authorization header 在 interceptor 內逐次讀取（`api_clz.dart:169`）；`inspector` 是獨立的 lazy global；兩者都在 `main()` 的 `setupInjection()` 之後才會被觸發。接受 |
| R-3 | `MainRepo` 是 lazy singleton，建構子 body 呼叫 `reset()`。改建構子時誤把 body 拿掉 | 初始狀態不再被重設 | AC-9 鎖住 |
| R-4 | 測試用的 locale 剛好等於 `'zh_TW'` | 測試無法區分「轉發注入值」與「仍讀全域常數」 | AC-11 要求不等於 `'zh_TW'` |
| R-5 | PR #162、#164 也修改 brainstorm 文件 | 更新 [A-8.14] 狀態時可能產生文件 merge conflict | 只改 [A-8.14] 段落；衝突僅限文件，手動解即可 |

---

## 7. 設計決策（trade-off）

### D-1 `locale` 注入什麼型別

| 選項 | 內容 | 評估 |
|------|------|------|
| **(a) `String locale`（採用）** | 建構時傳入值 | 最簡單。`Constants.locale` 是 `const`，執行期不會變，注入值等價於現況 |
| (b) `String Function() localeOf` | 每次呼叫時取值 | 為「執行期切換語系」預留，但這是 Out of Scope 的需求，屬於 YAGNI。真的要做時，只需要改 6 個建構子與 `injection.dart` |
| (c) 參數預設值 `locale = Constants.locale` | 呼叫端可以省略 | 仍然要 import `app/constants`，沒有解決問題 |

### D-2 是否保留 `api ?? GetIt.I<APIClz>()` 退路

| 選項 | 內容 | 評估 |
|------|------|------|
| **(a) 刪除，改為 `required`（採用）** | 呼叫端必須傳入 | 這個退路正是要切斷的依賴。`required` 讓編譯器列出所有呼叫點，漏改會直接編譯失敗 |
| (b) 保留 `APIClz? api` 加退路 | 相容舊呼叫 | data 層仍然 import `get_it`，違反 Q3 |

### D-3 `test/repository_test.dart` 傳入的 `APIClz`

| 選項 | 內容 | 評估 |
|------|------|------|
| **(a) `_MockAPIClz extends Mock implements APIClz`（採用）** | mocktail | 與 4 個 Yelp 測試寫法一致；不建立真的 Dio |
| (b) `APIClz(Dio())` | 真實實例 | 該檔要另外 import `dio`；建立了用不到的網路物件 |

---

## 8. 執行方式（交 STAGE 0b 選擇）

每個 Repository 改完建構子之後，`injection.dart` 與對應的測試要在同一個任務裡一起改，否則中間狀態會編譯失敗。任務切分建議為「1 個 Repository + 它在 `injection.dart` 的那一行 + 它的測試」為一組，共 6 組。各組之間沒有依賴，最後再做一次 `flutter analyze`／`flutter test` 與文件同步。

- **Subagent-driven（建議）**：同一個 session，依組派 subagent，每組完成後 review。改動是機械性的，review 成本低。
- **Parallel session**：另開 session，以 `executing-plans` 批次執行。6 組都會改到 `injection.dart`，平行執行時要注意這個檔案的編輯衝突。
