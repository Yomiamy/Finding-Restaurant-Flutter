# 實作計畫：A-8.6 根治 Yelp 關鍵字假搜尋缺陷：廢除本地記憶體 50 筆過濾，直通遠端 `term` 查詢

- **建立日期**：2026-10-31
- **對應規格**：`docs/features/2026-10-31-a-8-6-yelp-remote-keyword-search.md`
- **預估 Effort**：0.3d
- **狀態**：等待確認 (Pending Confirmation)

---

## 1. 目標 (Goal)

將首頁餐廳關鍵字搜尋從「本地記憶體 50 筆字串比對」重構為「直通遠端 Yelp API `term` 參數查詢」：
1. `MainRepository.fetchYelpSearchInfo` 支援具名選填 `term` 參數。
2. `MainRepo` 廢除 `filterByKeyword` 本地字串比對邏輯，維護當前生效的 `_term`；當關鍵字切換時自動重置分頁並清空舊快取，以新關鍵字向 Yelp API 發起第一頁請求。
3. `MainBloc` 在接收 `FilterListByKeyword` 事件時，取得當前定位並透過 `_mainRepository.fetchYelpSearchInfo(..., term: event.keyword)` 發起遠端搜尋。
4. 支援關鍵字狀態下的後續分頁（Load More）連貫性。
5. 補齊與更新相關單元測試，全案測試通過。

---

## 2. 實作方向與取捨 (Approaches & Trade-offs)

| 方向 | 作法 | 優點 | 缺點 | 結論 |
|---|---|---|---|---|
| A | **單一事實來源 (Single Source of Truth)**：`fetchYelpSearchInfo` 接收 `term`，`MainRepo` 統一管理分頁與遠端調用，廢除 `filterByKeyword` 本地過濾 | 徹底消除邊界情況與假無結果；完全遵循 Linus 模式消滅特殊情況；分頁自然連貫 | `MainRepository` 與 `MainBloc` 介面微調 | **採用** |
| B | 保留 `filterByKeyword`，但在其內部調用 `APIClz.businessesSearch` | 表面保留既有介面名 | `filterByKeyword` 原先無 `lat, lng`，若硬加參數與 `fetchYelpSearchInfo` 職責 100% 重複，破壞單一職責 | 不採用 |
| C | 仍先抓 50 筆泛餐廳，若找不到再向遠端請求 | 節省泛查詢的重打 | 邏輯雙倍複雜、狀態不一致、分頁毀滅 | 嚴重反模式，拒絕 |

---

## 3. 檔案異動清單 (File Changes)

| 檔案 | 變更類型 | 內容描述 |
|---|---|---|
| `lib/domain/repositories/main_repository.dart` | 修改 | `fetchYelpSearchInfo` 增加具名選填參數 `{String? term}`；移除廢棄的 `filterByKeyword` |
| `lib/data_layer/repositories/main_repo.dart` | 修改 | 支援 `term` 參數、記錄當前 `_term`、切換 `term` 時重置分頁與清單；移除 `filterByKeyword` 本地比對邏輯 |
| `lib/flow/main/bloc/main_event.dart` | 修改 | `FetchSearchInfo` 增加 `term` 屬性；`FilterListByKeyword` 增加 `price`、`openAt` 屬性並遵循 Equatable |
| `lib/flow/main/bloc/main_bloc.dart` | 修改 | `FilterListByKeyword` 改為調用 `fetchYelpSearchInfo(..., term: event.keyword)`；`FetchSearchInfo` 轉發 `term` |
| `lib/flow/main/view/main_page.dart` | 修改 | 觸發 `FilterListByKeyword` 時一併帶入當前 `_configs.price` 與 `_configs.openAtInSec` |
| `test/data_layer/main_repo_test.dart` | 修改/新增 | 驗證 `term` 參數轉發、預設回退 `'Restaurants'`、切換關鍵字時重置 `_offset` 與清單 |
| `test/main_bloc_load_more_test.dart` | 修改/新增 | 更新 mock 簽章；新增 `FilterListByKeyword` 觸發遠端查詢之狀態流測試 |
| `test/repository_test.dart` | 修改 | 配合 `MainRepository` 介面微調（若有實作 mock/fake） |

---

## 4. 實作任務拆分 (Tasks)

### 任務 1：Domain 與 Data 層重構（契約更新與 Yelp `term` 直通）
1. 修改 `lib/domain/repositories/main_repository.dart`：
   - `fetchYelpSearchInfo` 新增具名參數 `{String? term}`。
   - 移除 `filterByKeyword`。
2. 修改 `lib/data_layer/repositories/main_repo.dart`：
   - 維護 `_keyword` / `_term` 狀態。
   - 在 `fetchYelpSearchInfo` 中：
     - 若傳入 `term` 且與前次生效詞不同，重置 `_offset = 0`、更新 `_keyword`、清空 `summaryInfoSet`。
     - 傳給 `_api.businessesSearch` 的 `term` 為 `_keyword.isNotEmpty ? _keyword : 'Restaurants'`。
     - 刪除 `filterByKeyword` 方法中的 `summaryInfoSet.where(...)` 邏輯。
   - `reset()` 一併清空 `_keyword = ''`。
3. 更新 `test/data_layer/main_repo_test.dart` 與 `test/repository_test.dart`。

### 任務 2：BLoC 與 UI 層整合（事件驅動遠端搜尋）
1. 修改 `lib/flow/main/bloc/main_event.dart`：
   - `FetchSearchInfo` 補齊具名參數 `term`。
   - `FilterListByKeyword` 補齊 `price`、`openAt`。
2. 修改 `lib/flow/main/bloc/main_bloc.dart`：
   - `FetchSearchInfo` 將 `event.term` 傳遞給 `fetchYelpSearchInfo`。
   - `FilterListByKeyword` 取得定位後呼叫 `_mainRepository.fetchYelpSearchInfo(..., term: event.keyword)`，發出 `InProgress` -> `Success`。
3. 修改 `lib/flow/main/view/main_page.dart`：
   - `_showKeywordDialog` 確認時帶入 `price` 與 `openAt`。
4. 更新 `test/main_bloc_load_more_test.dart`，補齊關鍵字搜尋的 BLoC 測試。

### 任務 3：全案品質與回歸驗證
1. 執行 `flutter analyze` 確保零 warning、零 error。
2. 執行 `flutter test` 確保全部測試通過。
