# 功能規格：A-8.6 根治 Yelp 關鍵字假搜尋缺陷：廢除本地記憶體 50 筆過濾，直通遠端 `term` 查詢

- **日期**：2026-10-31
- **狀態**：規劃中（草稿）
- **實查基線**：`main` @ `6ed8af32`
- **需求來源**：gen-grill brief Q1–Q5，已放行（摘要見 §2.2）
- **相關 brainstorm 項目**：`docs/brainstorm/2026-10-29-features-brainstorm.md` §8.3 [A-8.6]（L1608-1623）
- **相關規格**：`docs/features/2026-10-27-repo-constructor-injection.md`（A-8.14，Repository 依賴注入）、`docs/features/2026-10-31-search-location-and-price-filter.md`（A-8.7，Location 與 Price 篩選）

---

## 1. 背景與問題

### 1.1 現況（實查）

目前專案的關鍵字搜尋存在嚴重的「50 筆過濾假象」：
1. **API 查詢硬編碼**：`MainRepo.fetchYelpSearchInfo`（`lib/data_layer/repositories/main_repo.dart:56-57`）將 Yelp 搜尋端點的 `term` 參數硬編碼為 `'Restaurants'`：
   ```dart
   YelpSearchDto searchDto = await _api.businessesSearch(
     term: 'Restaurants',
     ...
   );
   ```
2. **假過濾機制**：`MainRepo.filterByKeyword`（`lib/data_layer/repositories/main_repo.dart:91-108`）在接收到關鍵字時，僅對記憶體中已載入的 `summaryInfoSet`（最多 50 筆）進行字串 `contains` 檢查：
   ```dart
   List<RestaurantEntity> filteredList = summaryInfoSet.where((element) {
     return (element.name?.contains(keyword) ?? false) ||
         (element.categoriesStr.contains(keyword)) ||
         (element.location?.displayAddressStr.contains(keyword) ?? false);
   }).toList();
   ```
3. **分頁與狀態錯亂**：
   - 使用者在關鍵字過濾狀態下載入更多時，`MainRepo.fetchYelpSearchInfo` 依舊以 `'Restaurants'` 撈取下一批 50 筆，然後再跑一次本地記憶體過濾（`:81` `return await filterByKeyword(_keyword, sortByStr);`）。
   - `MainBloc` 為了防止載入中畫面跳動，甚至在 `test/main_bloc_load_more_test.dart:93` 加入保護邏輯「關鍵字過濾中載入更多：LoadMoreInProgress 不得把被過濾掉的項目撈回來」，這是因不良架構所生的修補代碼。
4. **BLoC 與 UI 資料流割裂**：
   - `MainBloc` 中的 `FilterListByKeyword` 事件（`lib/flow/main/bloc/main_bloc.dart:66-77`）僅調用 `_mainRepository.filterByKeyword`，完全不具備取得 GPS 座標並向遠端重新發起搜尋的能力。

### 1.2 為什麼是問題

- **假無結果**：當使用者在搜尋欄輸入「拉麵」、「壽司」、「牛排」或特定店名時，只要該關鍵字不在周邊前 50 筆「泛餐廳」快取中，App 會立即回報查無結果。
- **浪費 Yelp 全文搜尋能力**：Yelp 後端具備強大的全文檢索（涵蓋菜單內容、別名、招牌菜與評價關鍵字），目前完全被閒置。
- **分頁無法正常運作**：在特定關鍵字下，使用者無法分頁查詢全量符合該關鍵字的商家。

### 1.3 【核心判斷】（Linus 模式）

**✅ 值得做。**
- **資料結構**：消除記憶體快取篩選的假狀態。遠端 Yelp API 的 `term` 查詢是唯一的「事實來源（Single Source of Truth）」。
- **可消滅的複雜度**：
  - 徹底刪除 `MainRepo.filterByKeyword` 中的本地記憶體比對邏輯。
  - 搜尋與分頁統一回歸 `fetchYelpSearchInfo` 推進，消除「既有清單 vs 過濾清單」的雙重狀態維護。
- **最大破壞風險**：
  - `MainRepository` 契約調整需向下相容既有呼叫端與測試。
  - 切換關鍵字時的分頁狀態重置（`_offset = 0`）必須精確，避免舊關鍵字資料殘留。

---

## 2. 需求 Brief 與範圍

### 2.1 需求 Brief（gen-grill 產出）

- **Q1 問題定義**：搜尋僅在本地前 50 筆快取做字串過濾，導致大部分有效關鍵字顯示查無結果，且無法向遠端分頁載入。
- **Q2 觸發場景**：使用者在首頁 Drawer 或搜尋 Dialog 輸入「拉麵」等特定關鍵字搜尋。
- **Q3 成功標準**：
  1. 輸入關鍵字能直通 Yelp 遠端 API `term` 參數。
  2. 搜尋特定關鍵字時，若關鍵字變更，重置分頁並重新載入。
  3. 關鍵字下可正常滾動載入更多（Load More）。
  4. 廢除本地記憶體 50 筆字串過濾。
- **Q4 範圍邊界**：
  - 不做：Location 文字地名與 Price 逗號字串篩選（A-8.7，PR #170 範疇）。
  - 不做：Categories 別名、Radius 半徑、Open Now 營業中進階篩選（A-8.10 範疇）。
  - 不做：全量菜系樹 API 整合（A-8.12 範疇）。
- **Q5 既有覆蓋實查**：
  - `lib/data_layer/repositories/main_repo.dart:57` 寫死 `term: 'Restaurants'`。
  - `lib/data_layer/repositories/main_repo.dart:98-102` 存在 `summaryInfoSet.where(...)` 本地字串比對。
  - `lib/domain/repositories/main_repository.dart:8-19` 存在 `filterByKeyword` 介面。
  - 結論：問題真實存在，尚未被修復。

---

## 3. 驗收條件 (Acceptance Criteria)

- **AC-1**：`MainRepository.fetchYelpSearchInfo` 增加具名可選參數 `String? term`。
  - 若 `term` 為非空字串，轉發給 `APIClz.businessesSearch(term: term)`。
  - 若 `term` 為 null 或空字串，且內部無前次查詢詞，回退至預設 `'Restaurants'`。
- **AC-2**：`MainRepo` 負責追蹤當前生效的搜尋詞 `_term`。
  - 當傳入與目前 `_term` 不同的關鍵字時，自動執行重置（`_offset = 0`、`summaryInfoSet.clear()`），並以新關鍵字發起第一頁請求。
  - 呼叫 `MainRepo.reset()` 時，重置 `_offset = 0`、`_term = ''`、`summaryInfoSet.clear()`。
- **AC-3**：支援關鍵字狀態下的分頁加載（Load More）。
  - 在已設定關鍵字的情況下，再次呼叫 `fetchYelpSearchInfo`（不傳 `term` 或傳入相同 `term`），持續以目前關鍵字遞增 `_offset` 載入下一頁。
- **AC-4**：廢除本地記憶體字串過濾。
  - 移除 `summaryInfoSet.where(...)` 比對邏輯。
  - `filterByKeyword` 在 `MainRepository` 中可標記廢除或由 `fetchYelpSearchInfo` 取代；`MainBloc` 在接收 `FilterListByKeyword` 事件時，取得當前定位並透過 `_mainRepository.fetchYelpSearchInfo(..., term: event.keyword)` 發起遠端搜尋。
- **AC-5**：單元測試全數通過，並涵蓋：
  1. `MainRepo` 對 `term` 的參數轉發與預設回退測試。
  2. `MainRepo` 切換 `term` 時重置 `_offset` 與 `summaryInfoSet` 的行為測試。
  3. `MainBloc` 處理關鍵字搜尋並發送 `InProgress` -> `Success` 的狀態測試。
