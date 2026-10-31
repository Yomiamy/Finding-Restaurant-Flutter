# 實作計畫：A-8.10 擴充 Yelp 搜尋進階篩選（`categories`、`radius`、`open_now` 與 1,000 筆分頁邊界防護）

> 項目編號：**A-8.10**  
> 建立日期：2026-10-31  
> 關聯規格：[`docs/features/2026-10-31-a-8-10-yelp-search-advanced-filters.md`](../features/2026-10-31-a-8-10-yelp-search-advanced-filters.md)  
> 實查基線：`main` @ `6ed8af32`  
> 狀態：草稿（等待 STAGE 0b plan-verifier 初審）

---

## 1. 目標

為 Yelp 餐廳搜尋擴充三大篩選維度（`categories`、`radius`、`open_now`），並在 `MainRepo` 建立 1,000 筆分頁硬邊界防護（避免觸發 Yelp API 400 Bad Request 導致 App 拋錯崩潰）。

資料流遵循單向資料流：
`FilterConfigs` / UI → `MainEvent.FetchSearchInfo` → `MainBloc` → `MainRepository` (`MainRepo`) → `APIClz` (`_api.businessesSearch`) → Yelp Fusion API。

---

## 2. 實作方向與 Trade-off

### 2.1 任務切分與依賴關係

| 任務編號 | 負責範圍 | 異動檔案 | 執行方式 |
|:---|:---|:---|:---:|
| **T1** | API 定義與 Retrofit 代碼生成 | `lib/api/api_clz.dart`<br>`lib/api/api_clz.g.dart` | 序列第一步 |
| **T2** | Repository 介面、實作與 1,000 筆邊界防護 | `lib/domain/repositories/main_repository.dart`<br>`lib/data_layer/repositories/main_repo.dart`<br>`test/data_layer/main_repo_test.dart` | 序列第二步（依賴 T1 API 變更） |
| **T3** | Model 配置與 BLoC 事件轉發 | `lib/models/filter_configs.dart`<br>`lib/flow/main/bloc/main_event.dart`<br>`lib/flow/main/bloc/main_bloc.dart`<br>`test/main_bloc_load_more_test.dart` | 序列第三步（依賴 T2 Repo 簽章） |

**說明**：
- T1 是底層資料契約，需先變更並跑 build_runner 生成 `api_clz.g.dart`。
- T2 接續實作資料層與邊界衛語句，並補齊單元測試。
- T3 將上層 BLoC 與配置物件打通，並保證既有 BLoC 測試不被破壞。

---

## 3. 詳細設計與具體程式碼

### 3.1 T1：API 介面定義 (`lib/api/api_clz.dart`)

在 `APIClz.businessesSearch` 新增選填查詢參數：

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
    @Query('categories') String? categories,
    @Query('radius') int? radius,
    @Query('open_now') bool? openNow,
  });
```

生成指令：
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3.2 T2：Domain 與 Data 層 (`MainRepository` & `MainRepo`)

#### 3.2.1 `lib/domain/repositories/main_repository.dart`
擴充具名選填參數：
```dart
  Future<List<RestaurantEntity>> fetchYelpSearchInfo(
    double lat,
    double lng,
    int? price,
    int? openAt,
    String? sortByStr, {
    String? categories,
    int? radius,
    bool? openNow,
  });
```

#### 3.2.2 `lib/data_layer/repositories/main_repo.dart`
加入 1,000 筆衛語句與參數轉發：
```dart
  @override
  Future<List<RestaurantEntity>> fetchYelpSearchInfo(
    double lat,
    double lng,
    int? price,
    int? openAt,
    String? sortByStr, {
    String? categories,
    int? radius,
    bool? openNow,
  }) async {
    if (_isLoading) {
      return await filterByKeyword(_keyword, sortByStr);
    }

    // Yelp Fusion API: offset + limit <= 1000. 超出時 Yelp 回傳 400 Bad Request。
    // 當 offset 達到 1000 時主動停發，直接返回既有資料，消滅 400 崩潰邊界。
    if (_offset >= 1000) {
      return await filterByKeyword(_keyword, sortByStr);
    }

    _isLoading = true;
    try {
      YelpSearchDto searchDto = await _api.businessesSearch(
        term: 'Restaurants',
        latitude: lat,
        longitude: lng,
        locale: _locale,
        price: price,
        openAt: openAt,
        sortBy: sortByStr,
        categories: categories,
        radius: radius,
        openNow: openNow,
        limit: MainRepo._maxItemsCountInList,
        offset: _offset,
      );

      Set<String> favorIds = await _favorDataSource.fetchFavorIds();

      List<RestaurantEntity> fetchedEntities = (searchDto.businesses ?? []).map(
        (dto) {
          bool isFavor = favorIds.contains(dto.id);
          return RestaurantEntity.fromDto(dto).copyWith(favor: isFavor);
        },
      ).toList();

      summaryInfoSet.addAll(fetchedEntities);

      _offset += MainRepo._maxItemsCountInList;

      return await filterByKeyword(_keyword, sortByStr);
    } on Exception catch (e, st) {
      logger.e('fetchYelpSearchInfo 發生異常', error: e, stackTrace: st);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }
```

#### 3.2.3 單元測試 (`test/data_layer/main_repo_test.dart`)
1. 驗證 `fetchYelpSearchInfo` 正確轉發 `categories`, `radius`, `openNow`。
2. 驗證當 `_offset >= 1000` 時，不再發送 `_api.businessesSearch`。

### 3.3 T3：Model 與 BLoC 層

#### 3.3.1 `lib/models/filter_configs.dart`
擴充欄位與 `clearConfig`：
```dart
enum FilterConfigType { price, openAt, sortingRule, categories, radius, openNow }

class FilterConfigs {
  // 既有欄位...
  String? categories;
  int? radius;
  bool? openNow;

  void clearConfig(FilterConfigType configType) {
    switch (configType) {
      case FilterConfigType.price:
        price = null;
        break;
      case FilterConfigType.openAt:
        openAt = null;
        break;
      case FilterConfigType.sortingRule:
        sortBy = null;
        break;
      case FilterConfigType.categories:
        categories = null;
        break;
      case FilterConfigType.radius:
        radius = null;
        break;
      case FilterConfigType.openNow:
        openNow = null;
        break;
    }
  }
}
```

#### 3.3.2 `lib/flow/main/bloc/main_event.dart`
```dart
class FetchSearchInfo extends MainEvent {
  final int? price;
  final int? openAt;
  final String? sortBy;
  final String? categories;
  final int? radius;
  final bool? openNow;

  const FetchSearchInfo({
    this.price,
    this.openAt,
    this.sortBy,
    this.categories,
    this.radius,
    this.openNow,
  });

  @override
  List<Object?> get props => [price, openAt, sortBy, categories, radius, openNow];
}
```

#### 3.3.3 `lib/flow/main/bloc/main_bloc.dart`
轉發 `event.categories`、`event.radius`、`event.openNow` 給 `_mainRepository.fetchYelpSearchInfo`。

---

## 4. 驗證標準與退回邊界

1. **靜態分析**：`flutter analyze lib/ test/` 保持 0 warning / 0 error。
2. **格式化**：`dart format .` 零變更。
3. **單元與整合測試**：全套單元測試全數通過（`flutter test`）。
4. **向後相容**：不傳入新參數時，原有呼叫與搜尋完全不受影響。
