# 功能規格：A-8.12 串接 Yelp 分類體系 API (`GET /v3/categories`) 建立全量菜系分類樹過濾

- **日期**：2026-10-31
- **狀態**：🟡 規劃中 (STAGE 0a)
- **實查基線**：`new-main/main` @ `6ed8af32`
- **需求來源**：gen-grill brief Q1–Q5（見 §2）
- **相關 brainstorm 項目**：`docs/brainstorm/2026-10-29-features-brainstorm.md` §8.3 [A-8.12]
- **相關規格**：`docs/features/2026-10-23-yelp-places-api-coverage.md`（PR #160，新增 `/v3/categories` 端點與 DTO）

---

## 1. 背景與問題

### 1.1 現況（實查）

1. **底層端點已就緒**：PR #160（Issue #159）已完成 Yelp Places API 的 `/v3/categories` 與 `/v3/categories/{alias}` 宣告 (`APIClz.categories`／`category`)、外殼 DTO (`YelpCategoryListDto`、`YelpCategoryDetailDto`)，以及元素 DTO (`YelpRestaurantCategoryDto`)。
2. **Repository 缺快取與過濾**：`YelpCategoryRepo` 雖實作了 `fetchCategories()`，但每次呼叫皆直接直通遠端 Yelp API，無任何本地快取機制；且 Yelp 回傳全行業分類（汽修、醫療、教育等），缺乏針對餐飲料理（`restaurants` / `food`）的樹狀子分類篩選。
3. **篩選介面缺少菜系維度**：`FilterPage`（`lib/flow/filter/view/filter_page.dart`）目前僅包含價格、營業時間、排序方式 3 個區塊，尚未提供分類 Chip 選單，使用者無法按日式、義式、台灣小吃等料理分類精確過濾。
4. **搜尋參數傳遞斷層**：`FilterConfigs` 在 `main` 基線上尚未包含 `categories` 欄位；`MainPageContentWidget` 與 `businessesSearch` 亦未銜接 `categories` 查詢參數。

### 1.2 為什麼是問題

- **搜尋維度粗糙**：使用者只能透過距離或評分粗暴排序，無法直接挑選想吃的料理類型。
- **無快取導致流量浪費與延遲**：Yelp 分類清單龐大且屬於靜態/半靜態資料（數月甚至數年不變），若每次進入篩選頁都打遠端 API，會造成不必要的頻寬浪費、API 限流風險及等待延遲。
- **無容錯機制**：在離線或 Yelp API 異常情況下，若無預設降級資料，篩選頁將無分類可選或發生 UI 錯誤。

### 1.3 【核心判斷】（Linus 模式）

**值得做。** 

- **資料結構**：以 `YelpRestaurantCategoryDto` 為核心，在 `YelpCategoryRepo` 內部維護記憶體快取（`_cachedCategories`、`_cachedCuisineCategories`）。提供 `fetchCuisineCategories()` 方法提取 `parentAliases` 包含 `restaurants` 或 `food` 的餐飲類子分類。
- **消滅邊界情況**：當網路請求失敗或離線時，自動 fallback 到預設常用熱門菜系（台灣小吃、日式料理、義式料理、中式料理、美式、火鍋、咖啡輕食等），確保 FilterPage 永遠有可用選項，消滅「網路失敗導致畫面空白」的邊界狀態。
- **簡潔與零原生**：堅持 100% 純 Dart，不引入額外本地資料庫（如 Hive / SQLite / Isar），單純在記憶體中持有快取（Lazy Singleton 生命週期），符合 YAGNI 與簡潔原則。
- **絕不破壞既有行為**：`FilterConfigs` 擴充 `categories` 欄位，預設為 null，未選取時搜尋請求維持原樣，舊有流程完全不受影響。

---

## 2. 需求 Brief（gen-grill 產出）

**Q1 問題定義**：目前搜尋僅能依距離、評分、評論數及價格進行粗略過濾，無法讓使用者按特定餐飲料理菜系（如：日式、義式、咖啡輕食、小吃點心、火鍋等）進行分類精準篩選；Yelp 官方提供多達上千種結構化分類層級（`GET /v3/categories`），但若每次開啟篩選頁都重新向 Yelp API 抓取全量分類清單，會造成重複網路請求、延遲與超出配額。  
**Q2 觸發場景**：使用者在主畫面點擊篩選進入 `FilterPage` 時，除了價格、營業時間、排序規則外，可看到「料理菜系分類」區塊；點選分類 Chip（例如「日式料理」`japanese`）後按套用，搜尋能準確帶入 `categories` 參數回傳對應菜系餐廳。  
**Q3 成功標準**：
  - `YelpCategoryRepository` 提供本地記憶體快取支援，初次抓取後快取全量分類，避免每次開頁重抓。
  - `YelpCategoryRepository` 提供餐飲菜系分類過濾方法（篩選父分類為 `restaurants` 或 `food` 者），並具備離線/異常時優雅降級為內建常用推薦菜系之容錯機制。
  - `FilterConfigs` 支援 `categories` 欄位（儲存選取的別名字串，如 `japanese` 或逗號分隔別名），並與 `FilterPage` 雙向綁定。
  - `FilterPage` 新增分類過濾區塊（ChoiceChip / FilterChip 群組），支援預選、單選/切換、清除，套用時正確產出含 `categories` 的 `FilterConfigs`。
  - 主畫面 `MainPageContentWidget`、`MainBloc`、`MainRepo`、`businessesSearch` 串接並傳遞 `categories` 篩選參數至 Yelp 搜尋 API。
  - 單元測試與 Widget 測試 100% 通過，涵蓋快取機制、菜系過濾、`FilterConfigs` 序列化/重置、以及 `FilterPage` Widget 互動。  
**Q4 範圍邊界**：
  - 不引入重量級本機資料庫（如 Hive / Isar / SQLite）來儲存暫態分類樹，遵守 Linus「實用主義」與本專案既有純 Dart / 記憶體快取原則。
  - 不修改非相關的搜尋與地圖邏輯，維持向後相容（Never break userspace）。  
**Q5 既有覆蓋實查**：
  - 查了什麼：`lib/domain/repositories/yelp_category_repository.dart`、`lib/data_layer/repositories/yelp_category_repo.dart`、`lib/flow/filter/view/filter_page.dart`、`lib/models/filter_configs.dart`
  - 結果：底層 `/v3/categories` API 與 DTO 已於 PR #160 完成，但 `YelpCategoryRepo` 尚無快取與菜系樹狀篩選功能；`FilterPage` 尚未提供分類篩選 UI；`FilterConfigs` 在 `main` 分支上尚無 `categories` 欄位。
  - 證據：`lib/domain/repositories/yelp_category_repository.dart:9`（只有純 API 直通 fetchCategories）、`lib/flow/filter/view/filter_page.dart:73-126`（僅有價格、營業時間、排序）。

**放行方式**：五項齊備  
**盤問輪數**：0（需求細節已於 issue/brainstorm 收斂，Q5 實查齊備）

---

## 3. 規格設計

### 3.1 `YelpCategoryRepository` 記憶體快取與菜系過濾

在 `lib/domain/repositories/yelp_category_repository.dart` 擴充介面契約：

```dart
abstract interface class YelpCategoryRepository {
  /// `GET /v3/categories`；帶建構時注入的 locale。
  /// 支援本地記憶體快取，[forceRefresh] 為 true 時才向遠端重新請求。
  Future<YelpCategoryListDto> fetchCategories({bool forceRefresh = false});

  /// 取得餐飲料理分類（篩選 parentAliases 包含 'restaurants' 或 'food' 者）。
  /// 支援本地記憶體快取與異常/離線時優雅降級為內建熱門菜系清單。
  Future<List<YelpRestaurantCategoryDto>> fetchCuisineCategories({bool forceRefresh = false});

  /// `GET /v3/categories/{alias}`；回傳外殼 DTO，不拆出 `category`。
  Future<YelpCategoryDetailDto> fetchCategory(String alias);
}
```

在 `lib/data_layer/repositories/yelp_category_repo.dart` 實作：
- 成員變數：
  - `List<YelpRestaurantCategoryDto>? _cachedCategories;`
  - `List<YelpRestaurantCategoryDto>? _cachedCuisineCategories;`
- 常數清單 `defaultCuisines`：
  - `taiwanese`（台灣小吃）
  - `japanese`（日式料理）
  - `italian`（義式料理）
  - `chinese`（中式料理）
  - `korean`（韓式料理）
  - `tradamerican`（美式料理）
  - `hotpot`（火鍋）
  - `cafes`（咖啡輕食）
  - `desserts`（甜點冰品）
  - `bars`（酒吧餐酒館）
- `fetchCategories({bool forceRefresh = false})`：
  - 若 `!forceRefresh && _cachedCategories != null`，直接以快取封裝為 `YelpCategoryListDto` 返回。
  - 否則呼叫 `_api.categories(_locale)`，寫入 `_cachedCategories` 後返回。
- `fetchCuisineCategories({bool forceRefresh = false})`：
  - 若 `!forceRefresh && _cachedCuisineCategories != null`，直接返回快取。
  - 呼叫 `fetchCategories(forceRefresh: forceRefresh)`，過濾 `e.parentAliases != null && (e.parentAliases!.contains('restaurants') || e.parentAliases!.contains('food'))`。
  - 若過濾結果為空或 API 拋出異常，自動降級為 `defaultCuisines`。

### 3.2 `FilterConfigs` 擴充 `categories` 支援

在 `lib/models/filter_configs.dart`：
- 新增 `FilterConfigType.categories` 列舉項。
- 新增欄位：
  ```dart
  String? categories; // Yelp category alias (e.g. 'japanese' or 'taiwanese,japanese')
  ```
- 更新建構子：
  ```dart
  FilterConfigs({
    this.price,
    this.openAt,
    this.sortBy,
    this.categories,
  });

  FilterConfigs.fromUI({
    required int priceIndex,
    required DateTime openAtDate,
    required int sortingRuleIndex,
    this.categories,
  }) { ... }
  ```
- 更新 `clearConfig(FilterConfigType configType)`：
  ```dart
  case FilterConfigType.categories:
    categories = null;
    break;
  ```

### 3.3 搜尋管線串接 `categories`

1. **`APIClz.businessesSearch`**：
   - 增加具名參數 `@Query('categories') String? categories`。
2. **`MainRepository` & `MainRepo`**：
   - `fetchYelpSearchInfo(lat, lng, price, openAt, sortBy, {String? categories})`。
   - 將 `categories` 傳遞給 `_api.businessesSearch`。
3. **`MainEvent` (`FetchSearchInfo`)**：
   - 新增 `final String? categories;`。
4. **`MainBloc`**：
   - `on<FetchSearchInfo>` 時將 `event.categories` 轉發至 `_mainRepository.fetchYelpSearchInfo`。
5. **`MainPageContentWidget`**：
   - 於 `ResetSuccess` 觸發 `FetchSearchInfo` 時傳入 `categories: widget.filterConfigs.categories`。
6. **`RestaurantInfoListWidget`**：
   - 滾動加載觸發 `FetchSearchInfo` 時傳入 `categories: filterConfigs.categories`。

### 3.4 `FilterPage` UI 擴充餐飲菜系分類 Chip 區塊

1. **建構子注入支援**：
   ```dart
   class FilterPage extends StatefulWidget {
     static const routeName = '/FilterPage';
     final YelpCategoryRepository? categoryRepository;

     const FilterPage({super.key, this.categoryRepository});
     ...
   ```
   若未傳入，內部透過 `GetIt.I<YelpCategoryRepository>()` 取得（若未註冊則以 fallback 降級保護）。
2. **狀態與非同步載入**：
   - `String? _selectedCategory;`（目前選取的別名，null 表示不限）。
   - `List<YelpRestaurantCategoryDto> _cuisineCategories = [];`
   - `bool _isLoadingCategories = true;`
   - 在 `didChangeDependencies()` 讀取傳入之 `FilterConfigs.categories` 初始化 `_selectedCategory`，並觸發 `_loadCuisines()`。
3. **UI 佈局**：
   - 在排序規則上方新增 `SectionCardWidget`：
     - 圖示：`Icons.restaurant_menu`
     - 標題：`S.current.filter_cuisine_category`（餐飲料理分類）
     - 內容：`Wrap(spacing: 8, runSpacing: 8, children: [...])`
     - 提供「全部（不限）」Chip 以及各菜系名稱 Chip。
     - 點擊 Chip 切換選取狀態。
4. **套用結果**：
   - 點擊底部「套用」時，傳入 `categories: _selectedCategory` 建立 `FilterConfigs.fromUI` 並 pop 返回。

---

## 4. 非破壞性與相容性分析 (Never break userspace)

1. **向後相容**：
   - 所有新增參數皆為選填（nullable），舊有未帶 `categories` 的呼叫端行為完全不變。
   - `FilterConfigs` 預設 `categories = null`，既有測試與呼叫無縫兼容。
2. **記憶體快取隔離**：
   - 快取僅存在於 `YelpCategoryRepo` 實例中，不新增任何外部依賴或全域狀態。
   - `forceRefresh: true` 可隨時手動繞過快取。
3. **離線與異常容錯**：
   - 內建 `defaultCuisines` 兜底，即便在網路斷線、未設置 API Key 或 Yelp 服務異常時，UI 仍能正常呈現常見菜系，絕不發生 Unhandled Exception。

---

## 5. 驗收標準 (Acceptance Criteria)

- [ ] **AC-1 (快取功能)**：`YelpCategoryRepo.fetchCategories()` 在初次請求後快取結果；第二次呼叫不再調用 `_api.categories`，除非 `forceRefresh: true`。
- [ ] **AC-2 (菜系過濾)**：`YelpCategoryRepo.fetchCuisineCategories()` 能正確過濾 `parentAliases` 包含 `restaurants` 或 `food` 的項目；當 API 失敗時，返回預設的常用菜系清單。
- [ ] **AC-3 (FilterConfigs 擴充)**：`FilterConfigs` 包含 `categories` 屬性，支援 `fromUI` 初始化及 `clearConfig(FilterConfigType.categories)`。
- [ ] **AC-4 (搜尋管線串接)**：`MainRepo.fetchYelpSearchInfo`、`MainBloc`、`MainPageContentWidget` 均正確轉發 `categories` 參數至 `APIClz.businessesSearch`。
- [ ] **AC-5 (FilterPage UI)**：`FilterPage` 渲染「餐飲料理分類」區塊；點擊分類 Chip 正確切換選取狀態，並於點擊「套用」時將選取的 category alias 封裝進 `FilterConfigs` 回傳。
- [ ] **AC-6 (測試完整性)**：
  - `test/data_layer/yelp_category_repo_test.dart` 覆蓋快取命中、快取刷新、菜系過濾與異常降級測試。
  - `test/flow/filter/filter_page_test.dart` 覆蓋分類 Chip 渲染、選擇切換、預選回填與套用返回測試。
  - `flutter analyze` 零 warning/error，全套測試綠燈。
