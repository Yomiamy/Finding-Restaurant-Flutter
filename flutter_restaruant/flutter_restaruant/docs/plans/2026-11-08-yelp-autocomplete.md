# 實作計畫：[A-8.9] 串接 Yelp Autocomplete 實現搜尋即時補全與聯想 (UI / Debounce / BLoC)

> 項目編號：**A-8.9**  
> 建立日期：2026-11-08  
> 關聯規格：[`docs/features/2026-11-08-yelp-autocomplete.md`](../features/2026-11-08-yelp-autocomplete.md)  
> 實查基線：`main` @ `44abb540`  
> 狀態：🟡 規劃中 (STAGE 0b)  

---

## 1. 目標

在現有 `YelpAutocompleteRepository`（已由 PR #160 完成並註冊於 GetIt）基礎上：
1. 建立 `AutocompleteBloc` 負責即時查詢狀態機，利用 `rxdart` 的 `debounceTime(300ms)` 與 `switchMap` 進行輸入防抖與取消過期請求，消除網路競態。
2. 建立 Flutter Material 原生 `RestaurantSearchDelegate`，提供流暢的搜尋建議展示（熱門關鍵詞 `terms`、精準推薦店家 `businesses`、分類標籤 `categories`）。
3. 支援點擊店家直接導航至 `RestaurantDetailPage`，點擊熱門詞或分類則帶回關鍵字觸發 `MainBloc.FilterListByKeyword`。
4. 在 `MainPage` 的 AppBar 串接搜尋入口，並移除 `DrawerWidget` 中重複的關鍵字搜尋項目與舊有 `PlatformTextField` 對話框。
5. 補齊中英文多語系字串與完整的單元/Widget 測試（`blocTest`），達成 `flutter analyze` 零警告。

---

## 2. 任務拆分 (Task Breakdown)

本次實作拆分為 3 個高內聚、邊界清晰的序列任務：

| 任務 | 核心職責 | 預估異動檔案 |
|---|---|---|
| **T1** | 多語系字串擴充與 `AutocompleteBloc` (含 300ms Debounce 與 `blocTest`) | `lib/l10n/intl_zh_TW.arb`<br>`lib/l10n/intl_en.arb`<br>`lib/generated/`<br>`lib/flow/autocomplete/bloc/autocomplete_event.dart`<br>`lib/flow/autocomplete/bloc/autocomplete_state.dart`<br>`lib/flow/autocomplete/bloc/autocomplete_bloc.dart`<br>`lib/flow/autocomplete/bloc/autocomplete_barrel.dart`<br>`test/flow/autocomplete/autocomplete_bloc_test.dart` |
| **T2** | `RestaurantSearchDelegate` 建議清單 UI 與跳轉邏輯 (含 Widget 測試) | `lib/flow/autocomplete/view/restaurant_search_delegate.dart`<br>`lib/flow/autocomplete/autocomplete_barrel.dart`<br>`test/flow/autocomplete/restaurant_search_delegate_test.dart` |
| **T3** | `MainPage` AppBar 搜尋按鈕與 `DrawerWidget` 入口串接整合 | `lib/flow/main/view/main_page.dart`<br>`lib/flow/main/view/drawer_widget.dart`<br>`test/flow/main/main_page_test.dart` |

---

## 3. 詳細任務實作步驟

### 3.1 Task 1: 多語系與 `AutocompleteBloc` (T1)

1. **ARB 檔案更新**：
   - 在 `lib/l10n/intl_zh_TW.arb` 新增：
     - `"autocomplete_suggestions_title": "熱門搜尋"`
     - `"autocomplete_businesses_title": "推薦店家"`
     - `"autocomplete_categories_title": "相關分類"`
     - `"autocomplete_no_results": "找不到相符建議"`
     - `"autocomplete_search_hint": "搜尋餐廳、料理或關鍵字..."`
   - 在 `lib/l10n/intl_en.arb` 新增對應英文鍵值。
   - 執行 `flutter pub run intl_utils:generate` 重新產出多語系類別。
2. **BLoC 狀態機設計**：
   - `AutocompleteEvent`：
     - `AutocompleteQueryChanged(final String query)`
     - `AutocompleteCleared()`
   - `AutocompleteState` (以 sealed class 實作，遵循專案風格規範)：
     - `AutocompleteInitial`
     - `AutocompleteLoading`
     - `AutocompleteSuccess({required List<YelpAutocompleteTermDto> terms, required List<YelpRestaurantSummaryDto> businesses, required List<YelpRestaurantCategoryDto> categories})`
     - `AutocompleteEmpty`
     - `AutocompleteFailure({required String message})`
   - `AutocompleteBloc`：
     - 建構子注入 `YelpAutocompleteRepository`。
     - 事件轉換器使用 RxDart：
       ```dart
       EventTransformer<AutocompleteQueryChanged> debounceRestartable<AutocompleteQueryChanged>() {
         return (events, mapper) => events
             .debounceTime(const Duration(milliseconds: 300))
             .switchMap(mapper);
       }
       ```
     - 邏輯規則：若 `query.trim().isEmpty`，直接 `emit(const AutocompleteInitial())`，不發送網路請求；若有內容，調用 `repository.autocomplete(query)`；若返回的 lists 全為空則 emit `AutocompleteEmpty`，否則 emit `AutocompleteSuccess`；例外捕捉記錄 logger 並 emit `AutocompleteFailure`。
3. **測試驗證** (`test/flow/autocomplete/autocomplete_bloc_test.dart`)：
   - 採用 `mocktail` 與 `blocTest`。
   - 驗證：空字串即時 emit `AutocompleteInitial`。
   - 驗證：連續輸入時 300ms 內只打出最後一次 API 請求（防抖測試）。
   - 驗證：API 回傳成功時發布 `AutocompleteSuccess`。
   - 驗證：API 回傳空值時發布 `AutocompleteEmpty`。
   - 驗證：API 拋出例外時發布 `AutocompleteFailure`。

### 3.2 Task 2: `RestaurantSearchDelegate` 建議清單 UI 與跳轉邏輯 (T2)

1. **實作 `RestaurantSearchDelegate`** (`lib/flow/autocomplete/view/restaurant_search_delegate.dart`)：
   - 繼承 `SearchDelegate<String?>`。
   - 透過建構子注入 `AutocompleteBloc`（或於內部管理其生命週期）。
   - 覆寫 `searchFieldLabel`: `S.current.autocomplete_search_hint`。
   - 覆寫 `buildLeading`: 返回 `IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null))`。
   - 覆寫 `buildActions`: 當 `query.isNotEmpty` 時顯示清除按鈕 `IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')`。
   - 覆寫 `buildResults`: 當按下鍵盤搜尋/Enter 時，直接 `close(context, query)` 將目前 query 回傳。
   - 覆寫 `buildSuggestions`:
     - 每次 query 變動，發送 `AutocompleteQueryChanged(query)`。
     - 透過 `BlocBuilder<AutocompleteBloc, AutocompleteState>` 渲染：
       - `AutocompleteInitial`: 顯示簡潔引導提示。
       - `AutocompleteLoading`: 顯示置中進度指示器。
       - `AutocompleteEmpty`: 顯示無建議提示。
       - `AutocompleteSuccess`:
         - 區塊 1 (熱門詞彙): `ListTile(leading: Icon(Icons.search), title: Text(term.text), onTap: () => close(context, term.text))`。
         - 區塊 2 (推薦店家): `ListTile(leading: Icon(Icons.storefront), title: Text(business.name), subtitle: Text(business.location?.displayAddressStr ?? ''), onTap: () => Navigator.pushNamed(context, RestaurantDetailPage.routeName, arguments: Tuple2(RestaurantEntity.fromDto(business), null)))`。
         - 區塊 3 (分類標籤): `ListTile(leading: Icon(Icons.category_outlined), title: Text(category.title), onTap: () => close(context, category.title))`。
2. **測試驗證** (`test/flow/autocomplete/restaurant_search_delegate_test.dart`)：
   - 透過 `WidgetTester` 驗證建議項正確渲染與點擊行為。

### 3.3 Task 3: `MainPage` 與 `DrawerWidget` 搜尋入口串接 (T3)

1. **`MainPage` 改造** (`lib/flow/main/view/main_page.dart`)：
   - 在 AppBar actions 最前方新增搜尋圖示按鈕：
     ```dart
     IconButton(
       key: const Key('main_page_search_button'),
       icon: const Icon(Icons.search, color: ThemeColor.colorffffff),
       tooltip: S.current.keyword_search,
       onPressed: _openSearch,
     ),
     ```
   - 實作 `Future<void> _openSearch()`：
     ```dart
     final selectedKeyword = await showSearch<String?>(
       context: context,
       delegate: RestaurantSearchDelegate(
         bloc: AutocompleteBloc(repository: getIt<YelpAutocompleteRepository>()),
       ),
     );
     if (selectedKeyword != null && selectedKeyword.trim().isNotEmpty) {
       _mainBloc.add(
         FilterListByKeyword(
           keyword: selectedKeyword.trim(),
           sortByStr: _configs.sortBy,
           price: _configs.price,
           openAt: _configs.openAtInSec,
         ),
       );
     }
     ```
   - 移除 `DrawerWidget` 側邊欄中重複的「關鍵字過濾」項目，統一由 `MainPage` AppBar 搜尋按鈕觸發 `_openSearch`。
   - 移除 `_showKeywordDialog` 中已無用的舊代碼。
2. **測試驗證**：
   - 跑全專案單元與 Widget 測試：`make test` 或 `flutter test`。
   - 跑代碼靜態分析：`flutter analyze`，保證 0 warning / 0 error。

---

## 4. 驗證標準與退回條件

- **驗收標準**：
  1. `AutocompleteBloc` 100% 通過單元測試，無任何未捕獲之非同步 race condition。
  2. 搜尋列即時聯想流暢，輸入 $\ge 1$ 字元於 300ms 內顯示三種維度的建議。
  3. 點擊關鍵詞正確刷新餐廳列表；點擊店家直接開起詳情頁。
  4. 全專案 `flutter analyze` 零警告。
- **退回條件**：
  - 遺漏防抖或引入額外未經審核的肥大第三方套件。
  - 破壞既有 `MainBloc` 或 `businessesSearch` 搜尋邏輯。
