# 功能規格：[A-8.10] 補齊 FilterPage 的搜尋半徑 (`radius`) 與目前營業中 (`open_now`) UI 控制項

- **日期**：2026-11-16
- **狀態**：🟡 規劃中 (STAGE 0a)
- **實查基線**：`main` @ `f8fe7adf`
- **需求來源**：`gen-grill` brief Q1–Q5（由 `docs/brainstorm/2026-11-15-features-brainstorm.md` §8.3.2 [A-8.10] 驗證背書放行）
- **相關既有規格與 PR**：
  - `docs/features/2026-10-31-a-8-10-yelp-search-advanced-filters.md`（PR #174：已完成 API、Repository、`FilterConfigs`、BLoC 搜尋管線與 1,000 筆分頁邊界防護）
  - `docs/features/2026-10-31-a-8-12-yelp-categories-filter.md`（PR #178：已完成 `FilterPage` 菜系分類篩選 UI）

---

## 1. 背景與問題

### 1.1 現況（實查）

1. **底層搜尋管線與模型已就緒（PR #174）**：
   - [`lib/api/api_clz.dart:24-38`](../../lib/api/api_clz.dart#L24-L38) 之 `businessesSearch` 已宣告 `@Query('radius') int? radius`（上限 40,000 公尺）與 `@Query('open_now') bool? openNow`（與 `open_at` 互斥）。
   - [`lib/data_layer/repositories/main_repo.dart:44-98`](../../lib/data_layer/repositories/main_repo.dart#L44-L98) 之 `fetchYelpSearchInfo` 已接收並轉發 `radius` 與 `openNow`，且當 `openNow == true` 時主動將 `effectiveOpenAt` 設為 `null` 以遵守 Yelp API 互斥規則。
   - [`lib/models/filter_configs.dart:70-94`](../../lib/models/filter_configs.dart#L70-L94) 已定義 `radius`、`openNow` 欄位、`FilterConfigs.fromUI(..., this.radius, this.openNow)` 及 `clearConfig`。
   - [`lib/flow/main/view/main_page.dart:52-61`](../../lib/flow/main/view/main_page.dart#L52-L61)、[`main_page_content_widget.dart:41-50`](../../lib/flow/main/view/main_page_content_widget.dart#L41-L50)、[`restaurant_info_list_widget.dart:83-92`](../../lib/flow/main/view/restaurant_info_list_widget.dart#L83-L92) 與 `MainBloc` 均已完整轉發 `radius` 與 `openNow`。
2. **`FilterPage` 仍缺少 UI 控制項與套用傳參**：
   - [`lib/flow/filter/view/filter_page.dart:118-215`](../../lib/flow/filter/view/filter_page.dart#L118-L215) 目前僅提供「消費程度 (`price`)」、「營業時間 (`openAt`)」、「餐飲料理分類 (`categories`)」、「排序依據 (`sortBy`)」四個區塊。
   - `didChangeDependencies()` 未讀取 `configs.radius` 與 `configs.openNow`，底部套用按鈕呼叫 `FilterConfigs.fromUI(...)` 時亦未傳入 `radius` 與 `openNow`。

### 1.2 為什麼是問題

- **高價值搜尋條件無法使用**：底層 API、Repository、BLoC 皆已串通 `radius` 與 `openNow`，但使用者在 UI 上完全沒有入口可設定搜尋半徑或篩選「僅看營業中」的餐廳。
- **`open_now` 與 `open_at` 互斥缺乏介面引導**：Yelp API 規定 `open_now` 與 `open_at` 不可同時使用；UI 必須明確呈現切換「僅看營業中」後對指定營業時間選擇器的互斥行為，且關閉時不得送出 `open_now=false` 干擾 `open_at`。

### 1.3 【核心判斷】（Linus 模式）

**✅ 值得做。**

- **資料結構**：不新增任何全域狀態或外部依賴，直接復用既有的 `FilterConfigs.radius`（`int?`，`null` 代表不限，上限 `40000` 公尺）與 `FilterConfigs.openNow`（`bool?`，開啟時為 `true`、關閉時為 `null`）。
- **消滅邊界情況**：
  1. `openNow` 關閉時回傳 `null` 而非 `false`，使 Retrofit 自動省略 `open_now` query parameter，從資料源頭避免與 `open_at` 同時送出的 API 互斥衝突。
  2. 開啟 `openNow` 時摺疊隱藏 `CupertinoDatePicker`，且 `FilterConfigs.fromUI` 在 `openNow == true` 時將 `openAt` 設為 `null`（與 `MainRepo` `effectiveOpenAt` 語意一致），避免無效的 `openAt` 時間戳記出現在 `FilterTagsWidget` 上誤導使用者。
  3. 搜尋半徑採用預設距離級距 ChoiceChips（不限、`500 m`、`1 km`、`3 km`、`5 km`、`10 km`、`20 km`、`40 km`），值域天然受控於 `[500, 40000]`，不需處理任意字串輸入驗證或小數滑桿精度問題。
- **零破壞**：既有 `FilterConfigs`、`MainRepo`、`MainBloc`、`FilterPage` 既有多項篩選與測試完全相容。

---

## 2. 需求 Brief（gen-grill 產出）

- **Q1 問題定義**：底層已支援 `radius` 與 `openNow`，但 `FilterPage` 缺少對應 UI 控制項與狀態讀寫，導致使用者無法在介面上調整搜尋半徑或篩選目前營業中餐廳。
- **Q2 觸發場景**：
  1. 使用者從主頁 Drawer 開啟 `FilterPage`，選擇搜尋半徑（如 `3 km`）或開啟「僅看營業中 (`openNow`)」開關，點擊「套用」後觸發 `MainPage` 重載列表並帶入對應搜尋參數。
  2. 使用者再次打開 `FilterPage` 時，先前的 `radius` 與 `openNow` 設定能正確預選回填；切換回「不限」或關閉「僅看營業中」後套用，狀態正確還原為 `null`。
- **Q3 成功標準**：
  1. `FilterPage` 新增搜尋半徑 (`radius`) 選擇區塊（含「不限 (`null`)」及 `<= 40,000` 公尺常用級距）與目前營業中 (`openNow`) 開關控制項。
  2. `FilterPage` 於 `didChangeDependencies()` 正確讀取 `configs.radius` 與 `configs.openNow` 初始化 UI 狀態。
  3. 開啟 `openNow` 時隱藏/收合指定營業時間 `CupertinoDatePicker`；關閉 `openNow` 時恢復顯示並保留已選日期時間，且套用時傳入 `openNow: null`。
  4. `FilterConfigs.fromUI` 在 `openNow == true` 時將 `openAt` 置為 `null`；點擊套用正確傳入 `radius` 與 `openNow` 回傳 `FilterConfigs`。
  5. 多語系字串補齊至 `lib/l10n/intl_en.arb` 與 `lib/l10n/intl_zh_TW.arb`，並以 `intl_utils` 重新生成 `lib/generated/`。
  6. `test/flow/filter/filter_page_test.dart`、`test/flow/filter/radius_chips_widget_test.dart`（若抽出元件）及 `test/models/filter_configs_test.dart` 覆蓋上述行為，`flutter analyze` 與 `flutter test` 全數通過。
- **Q4 範圍邊界**：
  - 不變更 `APIClz`、`MainRepo`、`MainBloc`、`MainPage` 搜尋管線（已在 PR #174 完成）。
  - 不實作 `FilterTagsWidget` 的 `categories`/`radius`/`openNow` tag 顯示（比照 PR #178 保持範圍聚焦於 `FilterPage`）。
  - 不修改 `MainPage` 的 `FilterListByKeyword` 呼叫簽章。
  - 不實作自訂文字輸入公尺數或地圖半徑圓圈視覺化。
- **Q5 既有覆蓋實查**：
  - 查了什麼：`lib/flow/filter/view/filter_page.dart`、`lib/models/filter_configs.dart`、`lib/data_layer/repositories/main_repo.dart`、`lib/flow/main/view/filter_tags_widget.dart`、`test/flow/filter/filter_page_test.dart`。
  - 結果：`FilterConfigs`（含 `radius`、`openNow`、`FilterConfigs.fromUI` 具名參數）與搜尋管線已完成；`FilterPage` 尚未加入 `radius` 與 `openNow` 控制項，且 `FilterPage:207-212` 未傳入 `radius`/`openNow`。
  - 證據：`lib/flow/filter/view/filter_page.dart:25-50, 118-215`、`lib/models/filter_configs.dart:70-94`、`lib/data_layer/repositories/main_repo.dart:82-95`。

**放行方式**：短路（已有 `docs/features/2026-10-31-a-8-10-yelp-search-advanced-filters.md` 與 `docs/brainstorm/2026-11-15-features-brainstorm.md` §8.3.2 [A-8.10] 文件背書，且 Q5 實查完成）  
**盤問輪數**：0

---

## 3. 使用者故事與驗收條件 (Acceptance Criteria)

### 3.1 使用者故事

1. **快速設定搜尋距離**：身為餐廳搜尋使用者，我希望在過濾條件頁挑選「不限」或常見距離（500 m ～ 40 km），避免顯示離我過遠的餐廳。
2. **只看現在有營業的店家**：身為即刻用餐的使用者，我希望在過濾條件頁一鍵開啟「僅看營業中」，且系統清楚隱藏「指定時間」選擇器，避免互相衝突或困惑。
3. **篩選條件持久化回填**：身為重複調整條件的使用者，再次進入過濾條件頁時，先前設定的搜尋半徑與「僅看營業中」開關應維持在選取狀態。

### 3.2 驗收條件

- **AC-1 (`open_now` UI 控制與互斥)**：
  - 在 `FilterPage` 的「營業時間 (`filter_business_hour`)」區塊內上方提供 `SwitchListTile` 控制「僅看營業中 (`filter_open_now`)」。
  - 當 `openNow` 為 `true` 時，收合/隱藏下方 `CupertinoDatePicker`；切換回 `false` 時重新顯示 `CupertinoDatePicker`。
- **AC-2 (`radius` UI 控制)**：
  - 在 `FilterPage` 新增「搜尋半徑 (`filter_search_radius`)」`SectionCardWidget` 區塊，提供 `ChoiceChip` 選項：「不限 (`null`)」、「500 m (`500`)」、「1 km (`1000`)」、「3 km (`3000`)」、「5 km (`5000`)」、「10 km (`10000`)」、「20 km (`20000`)」、「40 km (`40000`)」。
  - 點擊已選取的非「不限」距離 Chip 可取消選取並切回「不限 (`null`)」；點擊「不限」直接重設為 `null`。
- **AC-3 (初始化回填與套用返回)**：
  - `FilterPage.didChangeDependencies()` 正確讀取 `configs.radius` 與 `configs.openNow == true`。
  - 點擊底部「套用」按鈕時，回傳 `FilterConfigs.fromUI(..., radius: _selectedRadius, openNow: _openNow)`（由模型建構子統一正規化）。
  - 若初始傳入的 `configs.radius` 為有效非預設值（`1..40000`，例如 `2500`）且使用者未點擊半徑 Chip，套用時仍保留原 `2500`，不靜默覆寫遺失；若越界（`<= 0` 或 `> 40000`），則於模型建構子收斂為 `null` 或 `40000`。
- **AC-4 (`FilterConfigs.fromUI` 互斥與邊界正規化)**：
  - `FilterConfigs.fromUI` 將 `openNow` 正規化為 `(openNow == true) ? true : null`（傳入 `false` 時亦收斂為 `null`，避免與 `open_at` 並發衝突）。
  - 當正規化後 `openNow == true` 時，將 `openAt` 設為 `null`；其餘情境 `openAt` 維持 `openAtDate.millisecondsSinceEpoch`。
  - `radius` 於建構子內收斂：`<= 0` 或 `null` 轉 `null`、`> 40000` clamp 至 `40000`，`1..40000` 原樣保留。
- **AC-5 (多語系與元件結構)**：
  - `intl_en.arb` 與 `intl_zh_TW.arb` 均新增對應 key 並完成 `lib/generated/` 重新生成。
  - 若將半徑 Chip 區塊抽為獨立 Widget 類別，須匯出於 `lib/flow/filter/view/view_barrel.dart`（禁止在 `FilterPage` 新增 `_buildX()` 輔助方法，遵循 `flutter-styles.md`）。
- **AC-6 (測試與靜態分析)**：
  - 新增/擴充 Widget 測試與單元測試覆蓋 AC-1 ～ AC-4。
  - `flutter analyze lib/ test/` 無新增 issue、`dart format` 檢查通過、`flutter test` 全套綠燈。

---

## 4. 明確排除 (Out of Scope)

- **`FilterTagsWidget` 晶片顯示擴充**：主頁上方 `FilterTagsWidget` 目前僅呈現 `sortingRule`、`price`、`openAt`，連既有 `categories` 亦未顯示；本案比照 PR #178 範圍，不擴充 `FilterTagsWidget`。
- **`FilterListByKeyword` 參數擴充**：`MainPage._openSearch` 關鍵字搜尋之進階篩選串接。
- **任意半徑輸入框與地圖半徑圓圈**：不實作自由輸入數值或地圖覆蓋層。
