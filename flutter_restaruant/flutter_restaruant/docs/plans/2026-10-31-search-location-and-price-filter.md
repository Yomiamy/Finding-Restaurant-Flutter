# 實作計畫：A-8.7 解除 GPS 強制綁定：搜尋 API 支援 `location` 文字地名，修正 `price` 為逗號分隔字串

> 項目編號：**A-8.7**
> 建立日期：2026-10-31
> 關聯規格：[`docs/features/2026-10-31-search-location-and-price-filter.md`](../features/2026-10-31-search-location-and-price-filter.md)
> 實查基線：`main` @ `6ed8af32`
> 狀態：草稿（待審查 / STAGE 0b）

---

## 1. 目標

1. 擴充 `APIClz.businessesSearch`：加入 `@Query('location') String? location`，並修正 `@Query('price') String? price`。
2. 重構 `MainRepository.fetchYelpSearchInfo` 為具名參數形式，解除對雙座標的強制要求，支援地名回退與字串價位。
3. 在 `MainBloc` 與 `MainRepo` 建立 GPS 容錯回退機制：定位被拒或取不到經緯度時，回退至地名 `"Taipei"`，消滅直接 emit `Failure()` 造成的畫面癱瘓。
4. 升級 `FilterConfigs` 的 `price` 為 `String?`，相容既有單選與未來的逗號分隔字串。

---

## 2. 實作任務劃分

| 任務 | 範圍 | 核心變更檔案 | 產出與驗證 |
|---|---|---|---|
| **T1: API 層規格與生成** | Retrofit 介面與代碼生成 | `lib/api/api_clz.dart`<br>`lib/api/api_clz.g.dart` | `make build_runner`<br>`flutter analyze lib/api/` |
| **T2: Data & Domain 層** | Repository 介面、實作與轉發測試 | `lib/domain/repositories/main_repository.dart`<br>`lib/data_layer/repositories/main_repo.dart`<br>`test/data_layer/main_repo_test.dart` | 具名參數轉發、座標/地名 fallback 測試通過 |
| **T3: Event、Bloc 與 UI 模型** | BLoC 容錯、事件欄位、FilterConfigs | `lib/flow/main/bloc/main_event.dart`<br>`lib/flow/main/bloc/main_bloc.dart`<br>`lib/models/filter_configs.dart`<br>`lib/flow/main/view/filter_tags_widget.dart`<br>`lib/flow/main/view/restaurant_info_list_widget.dart`<br>`test/main_bloc_load_more_test.dart`<br>`test/filter_tags_widget_test.dart` | GPS 拋錯回退測試、FilterTags 測試通過 |
| **T4: 全量驗收與整合** | 靜態分析與回歸驗證 | 專案全體 | `flutter analyze` 0 warnings<br>`flutter test` 全數通過 |

---

## 3. 詳細任務步驟

### Task 1: API 層規格與生成 (T1)
- **檔案**：`lib/api/api_clz.dart`
- **變更**：
  ```dart
  @GET('/v3/businesses/search')
  Future<YelpSearchDto> businessesSearch({
    @Query('term') String? term,
    @Query('location') String? location,
    @Query('latitude') double? latitude,
    @Query('longitude') double? longitude,
    @Query('locale') String? locale,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('open_at') int? openAt,
    @Query('sort_by') String? sortBy,
    @Query('price') String? price,
  });
  ```
- **代碼生成**：執行 `dart run build_runner build --delete-conflicting-outputs` 更新 `lib/api/api_clz.g.dart`。
- **檢查點**：`flutter analyze lib/api/` 無錯誤。

### Task 2: Data & Domain 層介面與實作 (T2)
- **檔案**：
  - `lib/domain/repositories/main_repository.dart`
  - `lib/data_layer/repositories/main_repo.dart`
  - `test/data_layer/main_repo_test.dart`
- **變更**：
  1. `MainRepository` 介面改為具名參數：
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
  2. `MainRepo.fetchYelpSearchInfo` 實作：
     ```dart
     final bool hasCoordinates = lat != null && lng != null;
     final String? resolvedLocation = hasCoordinates
         ? null
         : (location != null && location.isNotEmpty ? location : 'Taipei');

     YelpSearchDto searchDto = await _api.businessesSearch(
       term: 'Restaurants',
       latitude: hasCoordinates ? lat : null,
       longitude: hasCoordinates ? lng : null,
       location: resolvedLocation,
       locale: _locale,
       price: price,
       openAt: openAt,
       sortBy: sortByStr,
       limit: MainRepo._maxItemsCountInList,
       offset: _offset,
     );
     ```
  3. `test/data_layer/main_repo_test.dart`：
     - `_Data.price` 由 `2` 改為 `'2'`。
     - 既有測試更新為具名參數呼叫，驗證 `latitude`, `longitude`, `location: null`, `price: '2'` 轉發。
     - 新增測試：當 `lat: null, lng: null` 時，驗證呼叫 `businessesSearch(..., location: 'Taipei', latitude: null, longitude: null)`。

### Task 3: Event、Bloc 與 UI 模型相容 (T3)
- **檔案**：
  - `lib/flow/main/bloc/main_event.dart`
  - `lib/flow/main/bloc/main_bloc.dart`
  - `lib/models/filter_configs.dart`
  - `lib/flow/main/view/filter_tags_widget.dart`
  - `lib/flow/main/view/restaurant_info_list_widget.dart`
  - `test/filter_tags_widget_test.dart`
  - `test/main_bloc_load_more_test.dart`
- **變更**：
  1. `FetchSearchInfo` 事件：
     ```dart
     class FetchSearchInfo extends MainEvent {
       final String? location;
       final String? price;
       final int? openAt;
       final String? sortBy;

       const FetchSearchInfo({this.location, this.price, this.openAt, this.sortBy});
     }
     ```
  2. `MainBloc` 容錯邏輯：
     ```dart
     double? lat;
     double? lng;
     String? location = event.location;

     if (location == null || location.isEmpty) {
       try {
         final Position currentPos = await Utils.getCurrentPosition();
         lat = currentPos.latitude;
         lng = currentPos.longitude;
       } catch (e, st) {
         logger.w('GPS 定位失敗，回退使用預設地點 Taipei', error: e, stackTrace: st);
         location = 'Taipei';
       }
     }

     final List<RestaurantEntity> summaryInfos = await _mainRepository
         .fetchYelpSearchInfo(
           lat: lat,
           lng: lng,
           location: location,
           price: event.price,
           openAt: event.openAt,
           sortByStr: event.sortBy,
         );
     ```
  3. `FilterConfigs`：
     - `String? price;`
     - `int get priceIndex`：安全解析首個價格索引。
     - `FilterConfigs.fromUI`：`price = '${priceIndex + 1}';`
     - `String getPriceDispStr(Object price)`：支援 `int` 或 `String`（含多選逗號字串如 `"1,2"`）。
  4. `FilterTagsWidget` 與 `restaurant_info_list_widget.dart`：
     - 型別與非空判斷對齊 `String? price`。
  5. 測試更新：
     - `test/filter_tags_widget_test.dart`：更新為 `price = '2'`。
     - `test/main_bloc_load_more_test.dart`：
       - 更新 `mockRepo.fetchYelpSearchInfo` 相關 mock 為具名參數。
       - 新增測試：當 `geolocator` 拋出權限拒絕例外時，`MainBloc` 不發出 `Failure()`，而發出 `InProgress → Success`，並將 `location: 'Taipei'` 傳予 Repository。

### Task 4: 全量驗收與整合 (T4)
- 執行 `flutter analyze` 確保 0 warning / 0 error。
- 執行 `flutter test` 確保既有 460 個測試與新增測試全部綠燈。
- 審查 Git diff，確保無不必要的格式更動或遺留 debug 代碼。

---

## 4. 破壞性與相容性檢查

- **APIClz**: `@Query('location')` 與 `@Query('price') String?` 是完全向前相容的 Retrofit 查詢參數更新。
- **MainRepository**: 由位置參數改為具名參數。由於只在 `MainBloc`、`main_repo_test.dart`、`main_bloc_load_more_test.dart` 三處呼叫，透過編譯器靜態型別安全檢查，呼叫端同步更新後零 runtime 破壞風險。
- **FilterConfigs**: 保留 `getPriceDispStr(Object price)` 簽章相容性，`price` 改為 `String?` 讓未來的逗號分隔字串可平滑銜接。
