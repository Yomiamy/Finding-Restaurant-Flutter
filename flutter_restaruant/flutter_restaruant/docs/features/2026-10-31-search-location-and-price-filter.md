# 功能規格：A-8.7 解除 GPS 強制綁定：搜尋 API 支援 `location` 文字地名，修正 `price` 為逗號分隔字串

- **日期**：2026-10-31
- **狀態**：草稿（待審查 / STAGE 0a）
- **實查基線**：`main` @ `6ed8af32`
- **需求來源**：gen-grill brief Q1–Q5，已放行（摘要見 §2.2）
- **相關 brainstorm 項目**：`docs/brainstorm/2026-10-29-features-brainstorm.md` §8.3 [A-8.7]（L1624-1640）
- **相關規格**：`docs/features/2026-10-23-yelp-places-api-coverage.md`（PR #160，保留 A-8.7 擴充點）

---

## 1. 背景與問題

### 1.1 現況（實查）

1. `lib/api/api_clz.dart:19-29`:
   `businessesSearch` 宣告中缺少 `@Query('location') String? location`，且 `@Query('price') int? price` 宣告為 `int?`：
   ```dart
   @GET('/v3/businesses/search')
   Future<YelpSearchDto> businessesSearch({
     @Query('term') String? term,
     @Query('latitude') double? latitude,
     @Query('longitude') double? longitude,
     @Query('locale') String? locale,
     @Query('limit') int? limit,
     @Query('offset') int? offset,
     @Query('open_at') int? openAt,
     @Query('sort_by') String? sortBy,
     @Query('price') int? price,
   });
   ```
2. 根據 Yelp Fusion API `/v3/businesses/search` 官方規格：
   - 搜尋必須具備座標 `(latitude, longitude)` 或地名 `location`（兩者二擇一）。
   - `price` 為可選字串，支援單一價位（如 `"1"`）或逗號分隔多選價位（如 `"1,2"`）。
3. `lib/flow/main/bloc/main_bloc.dart:21-58`:
   - `MainBloc` 在 `FetchSearchInfo` 處理常式中，無條件呼叫 `Utils.getCurrentPosition()`。
   - `Utils.getCurrentPosition()` 在使用者拒絕 GPS 定位權限或權限永久停用時會直接拋出 `Exception`（`utils.dart:56, 62`）。
   - `MainBloc` 捕捉到 `Exception` 後直接 emit `Failure()`，導致 App 進入失敗畫面，使用者完全無法搜尋或瀏覽餐廳列表。
4. `lib/domain/repositories/main_repository.dart:8-14` 與 `lib/data_layer/repositories/main_repo.dart:42-88`:
   - `fetchYelpSearchInfo` 介面目前採 5 個位置參數：`(double lat, double lng, int? price, int? openAt, String? sortByStr)`。
   - 強制傳入 `lat` 與 `lng`，不支援以文字地名搜尋，也不支援無座標時的回退。
   - `price` 亦為 `int?`。
5. `lib/models/filter_configs.dart:23` 與 `lib/flow/filter/view/filter_page.dart`:
   - `FilterConfigs.price` 為 `int?`。
   - `FilterConfigs.getPriceDispStr(int price)` 只接收 `int`，且 `FilterTagsWidget` 依賴 `_filterConfigs.price! > 0` 進行顯示。

### 1.2 為什麼是問題

- **核心可用性阻擋**：拒絕定位權限是常見使用者行為。目前直接癱瘓整個主畫面，違反核心可用性。
- **異地搜尋受限**：無法搜尋指定城市或地點（如 "Taipei", "Tokyo", "San Francisco"）。
- **價位篩選規格錯誤**：Yelp API 規格支援字串及逗號分隔（多選價位），舊宣告 `int?` 限制了擴充性並與官方規格脫節。

### 1.3 【核心判斷】

**值得做。**

- **資料結構**：
  - `APIClz.businessesSearch`: 補齊 `@Query('location') String? location`，修正 `@Query('price') String? price`。
  - `MainRepository.fetchYelpSearchInfo`: 轉為具名參數 `{double? lat, double? lng, String? location, String? price, int? openAt, String? sortByStr}`（符合 Style Guide §2.8 參數 ≥ 3 強制 named parameters）。
  - `MainBloc` / `FetchSearchInfo`: `FetchSearchInfo` 支援 `final String? location` 與 `final String? price`。
  - `FilterConfigs`: `price` 改為 `String?`，支援單一與逗號分隔多選；`getPriceDispStr` 支援字串與數值轉換。
- **可消滅的複雜度**：
  - 消除 GPS 權限被拒直接崩潰的特殊分支。
  - 統一位置解析邏輯：有 GPS 座標用 GPS，無 GPS 或有指定地名時使用 location（預設回退至 "Taipei"）。
- **最大破壞風險**：
  - `fetchYelpSearchInfo` 簽章變更（改為 named parameters），需同步更新呼叫端：`main_bloc.dart`、`main_repo_test.dart`、`main_bloc_load_more_test.dart`。

---

## 2. 使用者故事與需求 Brief

### 2.1 使用者故事

1. 身為**使用者**，當我未開啟或拒絕手機 GPS 定位權限時，App 仍能以預設地名（如台北市 "Taipei"）順利載入熱門餐廳列表，而不是直接顯示錯誤畫面。
2. 身為**使用者**，當我在搜尋或設定位置時，App 能夠向 Yelp API 傳送 `location` 參數以獲取指定地區的餐廳。
3. 身為**開發者**，呼叫 Yelp API 時能夠傳遞逗號分隔的價格區間字串（如 `"1,2"`），符合官方 API 規格。

### 2.2 需求 brief 摘要（gen-grill 已放行）

- **Q1 問題**：`businessesSearch` 缺乏 `location` 參數且強制要求手機 GPS；GPS 被拒絕即整個主畫面崩潰；`price` 誤告為 `int?` 無法傳遞逗號分隔價格字串。
- **Q2 場景**：
  - 使用者在隱私設定關閉定位權限後啟動 App。
  - 未來擴充輸入地名搜尋。
  - 價位篩選送出價格區間字串。
- **Q3 成功標準**：
  - 補齊 `location` 參數，`price` 改為 `String?`。
  - GPS 失敗時平滑回退至 default location `"Taipei"`，主畫面正常展示資料。
  - 既有單元與 Widget 測試全數通過，新增 GPS 回退與 named parameter 轉發測試。
- **Q4 範圍邊界**：
  - 不包含 A-8.6（關鍵字直通遠端 Yelp 查詢，該項由下個工作項目處理）。
  - 不包含 A-8.10（進階篩選 categories/radius/open_now）。
  - 不改動 FilterPage 的 UI 選擇器型態（維持單選 SegmentControlWidget，但底層 FilterConfigs 改存 String?）。
- **Q5 既有測試覆蓋**：
  - `test/data_layer/main_repo_test.dart`
  - `test/main_bloc_load_more_test.dart`
  - `test/filter_tags_widget_test.dart`
  - `test/flow/filter/filter_page_test.dart`

---

## 3. 需求與驗收標準（AC）

### 3.1 AC-1: `APIClz` 規格對齊
- `businessesSearch` 增加可選具名參數 `@Query('location') String? location`。
- `businessesSearch` 的 `price` 參數型別由 `int?` 改為 `@Query('price') String? price`。
- 執行 `make build_runner` 成功更新 `lib/api/api_clz.g.dart`，無分析錯誤。

### 3.2 AC-2: `MainRepository` 與 `MainRepo` 實作
- `MainRepository.fetchYelpSearchInfo` 改為具名參數形式：
  ```dart
  Future<List<RestaurantEntity>> fetchYelpSearchInfo({
    double? lat,
    double? lng,
    String? location,
    String? price,
    int? openAt,
    String? sortByStr,
  });
  ```
- `MainRepo.fetchYelpSearchInfo` 實作：
  - 判斷座標是否齊全：`final bool hasCoordinates = lat != null && lng != null;`。
  - 若 `hasCoordinates` 為 true，呼叫 `_api.businessesSearch` 時帶入 `latitude: lat, longitude: lng, location: null`。
  - 若 `hasCoordinates` 為 false，帶入 `latitude: null, longitude: null, location: (location != null && location.isNotEmpty) ? location : 'Taipei'`。
  - `price` 字串直接轉發至 API。

### 3.3 AC-3: `FetchSearchInfo` 事件與 `MainBloc` 容錯回退
- `FetchSearchInfo` 增加 `final String? location`，並將 `price` 型別由 `int?` 改為 `final String? price;`。
- `MainBloc` 處理 `FetchSearchInfo` 時：
  - 若 `event.location` 為非空字串，直接使用 `location = event.location`，不需嘗試取得 GPS。
  - 若 `event.location` 為 null 或空字串，嘗試呼叫 `Utils.getCurrentPosition()`。
  - 若 `Utils.getCurrentPosition()` 成功，取得 `lat` 與 `lng`。
  - 若 `Utils.getCurrentPosition()` 拋出例外（權限被拒或定位關閉），捕捉例外並記錄，回退至 `location = 'Taipei'`，`lat = null`，`lng = null`。
  - 呼叫 `_mainRepository.fetchYelpSearchInfo(...)` 繼續載入流程，不發出 `Failure()`，主頁面正常展示資料。

### 3.4 AC-4: `FilterConfigs` 與 UI 相容性
- `FilterConfigs.price` 型別改為 `String?`。
- `FilterConfigs.fromUI` 設值為 `price = '${priceIndex + 1}'`。
- `FilterConfigs.priceIndex` 正確解析單一數字或逗號分隔的首個數字。
- `FilterConfigs.getPriceDispStr(Object price)` 支援傳入 `int` 或 `String`（含逗號分隔多選如 `"1,2"` 顯示 `"\$, \$\$"`）。
- `FilterTagsWidget` 正確判斷 `_filterConfigs.price != null && _filterConfigs.price!.isNotEmpty` 並正常顯示。

### 3.5 AC-5: 測試覆蓋與品質保證
- `test/data_layer/main_repo_test.dart`：
  - 驗證座標存在時，正確帶入 `latitude` 與 `longitude`，`location` 為 `null`，`price` 為字串。
  - 新增測試：座標為 null 時，正確帶入 `location: 'Taipei'`（或傳入的 location），且 `latitude` 與 `longitude` 為 `null`。
- `test/main_bloc_load_more_test.dart`：
  - 更新 `mockRepo.fetchYelpSearchInfo` 為具名參數 mock。
  - 新增測試：當 GPS platform channel 回傳錯誤或拒絕時，`MainBloc` 不發出 `Failure()`，而是發出 `InProgress → Success`，且 `fetchYelpSearchInfo` 接收到 `location: 'Taipei'`。
- `test/filter_tags_widget_test.dart`：更新價格設定為字串，測試通過。
- `flutter analyze` 零錯誤、零警告。
- 全量 `flutter test` 通過。

---

## 4. 邊界與非目標（Out of Scope）

- 不在此 issue 中實作完整關鍵字直通 Yelp 查詢（這是 A-8.6 的工作範疇）。
- 不在此 issue 中實作進階篩選 categories / radius / open_now（這是 A-8.10 的工作範疇）。
- 不在此 issue 中改動 FilterPage 的 UI 選擇器（目前仍保留 SegmentControlWidget 單選，但底層支援逗號分隔字串）。
