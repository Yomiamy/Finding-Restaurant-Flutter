# 實作計畫：A-8.12 串接 Yelp 分類體系 API (`GET /v3/categories`) 建立全量菜系分類樹過濾

> 項目編號：**A-8.12**  
> 建立日期：2026-10-31  
> 關聯規格：[`docs/features/2026-10-31-a-8-12-yelp-categories-filter.md`](../features/2026-10-31-a-8-12-yelp-categories-filter.md)  
> 實查基線：`new-main/main` @ `6ed8af32`  
> 狀態：🟡 規劃中 (STAGE 0b)  

---

## 1. 目標

在現有 `YelpCategoryRepository` 底層端點基礎上：
1. 建立記憶體長週期快取機制，消滅重複 API 請求開銷與延遲。
2. 實作餐飲料理分類過濾（`fetchCuisineCategories`），並具備離線/網路異常時自動 fallback 至內建常用推薦菜系的容錯能力。
3. 擴充 `FilterConfigs` 與搜尋管線，支援 `categories` 查詢參數。
4. 升級 `FilterPage` 介面，新增餐飲料理分類 Chip 選擇區塊，支援單選切換、預選回填與條件套用。

---

## 2. 實作架構與切分 (Task Breakdown)

本次實作分為 3 個序列任務：

| 任務 | 核心範圍 | 影響檔案 |
|---|---|---|
| **T1** | `YelpCategoryRepository` 記憶體快取、菜系分類過濾與降級容錯 | `lib/domain/repositories/yelp_category_repository.dart`<br>`lib/data_layer/repositories/yelp_category_repo.dart`<br>`test/data_layer/yelp_category_repo_test.dart` |
| **T2** | `FilterConfigs` 擴充 categories 支援與搜尋管線串接 | `lib/models/filter_configs.dart`<br>`lib/api/api_clz.dart`<br>`lib/api/api_clz.g.dart`<br>`lib/domain/repositories/main_repository.dart`<br>`lib/data_layer/repositories/main_repo.dart`<br>`lib/flow/main/bloc/main_event.dart`<br>`lib/flow/main/bloc/main_bloc.dart`<br>`lib/flow/main/view/main_page_content_widget.dart`<br>`lib/flow/main/view/restaurant_info_list_widget.dart`<br>`test/models/filter_configs_test.dart` |
| **T3** | `FilterPage` 介面擴充餐飲料理分類 Chip 區塊與多語系 | `lib/l10n/intl_*.arb`<br>`lib/generated/l10n.dart`<br>`lib/flow/filter/view/filter_page.dart`<br>`test/flow/filter/filter_page_test.dart` |

---

## 3. 詳細任務步驟

### 3.1 Task 1: Repository 記憶體快取與餐飲菜系過濾 (T1)

1. **介面擴充** (`lib/domain/repositories/yelp_category_repository.dart`)：
   - `fetchCategories({bool forceRefresh = false})`
   - `fetchCuisineCategories({bool forceRefresh = false})`
2. **實作** (`lib/data_layer/repositories/yelp_category_repo.dart`)：
   - 增加內部快取 `_cachedCategories` 與 `_cachedCuisineCategories`。
   - 增加靜態常數 `defaultCuisines`（包含台灣小吃、日式料理、義式料理、中式料理、美式、火鍋、咖啡輕食等）。
   - `fetchCategories({bool forceRefresh = false})` 支援快取命中直接返回，未命中才向 `_api.categories(_locale)` 抓取。
   - `fetchCuisineCategories({bool forceRefresh = false})` 篩選 `parentAliases` 包含 `'restaurants'` 或 `'food'` 者；若遠端拋出例外或無資料，安全 fallback 至 `defaultCuisines`。
3. **單元測試** (`test/data_layer/yelp_category_repo_test.dart`)：
   - 測試初次呼叫調用 API，第二次呼叫命中快取不調用 API。
   - 測試 `forceRefresh: true` 強制重打 API 並更新快取。
   - 測試 `fetchCuisineCategories` 能正確篩選出餐飲分類。
   - 測試 API 拋出 `DioException` 時，`fetchCuisineCategories` 優雅降級返回 `defaultCuisines`，不拋出未捕捉例外。

### 3.2 Task 2: FilterConfigs 擴充 categories 支援與搜尋管線串接 (T2)

1. **FilterConfigs** (`lib/models/filter_configs.dart`)：
   - 新增 `FilterConfigType.categories`。
   - 新增 `String? categories` 欄位。
   - 建構子 `FilterConfigs` 與 `FilterConfigs.fromUI` 支援具名選填參數 `this.categories`。
   - `clearConfig(FilterConfigType.categories)` 重置 `categories = null`。
2. **搜尋管線串接**：
   - `lib/api/api_clz.dart`: `businessesSearch` 增加具名選填 `@Query('categories') String? categories`。
   - `lib/domain/repositories/main_repository.dart` & `lib/data_layer/repositories/main_repo.dart`: `fetchYelpSearchInfo` 增加 `{String? categories}` 具名選填參數並透傳至 API。
   - `lib/flow/main/bloc/main_event.dart`: `FetchSearchInfo` 增加 `this.categories` 欄位與 `props` 比對。
   - `lib/flow/main/bloc/main_bloc.dart`: 轉發 `event.categories` 至 `_mainRepository.fetchYelpSearchInfo`。
   - `lib/flow/main/view/main_page_content_widget.dart` & `lib/flow/main/view/restaurant_info_list_widget.dart`: 觸發 `FetchSearchInfo` 時傳遞 `widget.filterConfigs.categories`。
3. **單元測試** (`test/models/filter_configs_test.dart`)：
   - 驗證 `categories` 在 `FilterConfigs.fromUI` 的賦值、讀取、清空行為。

### 3.3 Task 3: FilterPage UI 擴充餐飲料理分類 Chip 區塊 (T3)

1. **多語系支援** (`lib/l10n/intl_en.arb`, `lib/l10n/intl_zh_TW.arb`)：
   - `filter_cuisine_category`: "Cuisine Category" / "餐飲料理分類"
   - `filter_cuisine_all`: "All" / "全部"
   - 執行 `make intl`（`dart run intl_utils:generate`）更新 `lib/generated/l10n.dart`。
2. **FilterPage 元件升級** (`lib/flow/filter/view/filter_page.dart`)：
   - 建構子支援 `final YelpCategoryRepository? categoryRepository;` 依賴注入（若無則從 GetIt 取得或容錯保護）。
   - 在 `didChangeDependencies()` 讀取傳入之 `configs.categories`，並呼叫 `fetchCuisineCategories()` 載入分類。
   - 新增 `SectionCardWidget` 呈現分類 Chips（`ActionChip` / `FilterChip` / `ChoiceChip`），提供「全部」與各料理分類標籤。
   - 點擊 Chip 切換選取狀態，選中時凸顯樣式；點擊「套用」時傳入 `categories: _selectedCategory`。
3. **Widget 測試** (`test/flow/filter/filter_page_test.dart`)：
   - 注入假 `YelpCategoryRepository`，驗證「餐飲料理分類」區塊與 Chips 渲染。
   - 測試點擊分類 Chip 後點擊「套用」，回傳的 `FilterConfigs` 具備選取的 `categories`。
   - 測試初始 `FilterConfigs` 帶有分類別名時，對應 Chip 正確處於選取狀態。

---

## 4. 驗證與退場標準 (Verification)

1. **靜態分析**：`flutter analyze lib/ test/` 零警告零錯誤。
2. **程式碼格式**：`dart format .` 符合專案風格規範。
3. **自動化測試**：`flutter test` 全數通過，包含既有 600+ 測試與本次新增的各層單元測試、Widget 測試。
