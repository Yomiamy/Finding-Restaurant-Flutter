# 功能規格：A-8.10 擴充 Yelp 搜尋進階篩選（`categories`、`radius`、`open_now` 與 1,000 筆分頁邊界防護）

- **日期**：2026-10-31
- **狀態**：草稿（等待 STAGE 0b 計畫與實作）
- **實查基線**：`main` @ `6ed8af32`
- **需求來源**：gen-grill brief Q1–Q5，已由 brainstorm 驗證背書放行
- **相關 brainstorm 項目**：`docs/brainstorm/2026-10-29-features-brainstorm.md` §8.3.2 [A-8.10] (L1757-1772)
- **相關既有規格**：`docs/features/2026-10-23-yelp-places-api-coverage.md`（曾標記明確排除 A-8.10，保留至本期實作）

---

## 1. 背景與問題

### 1.1 現況（實查）

1. **API 定義缺乏進階篩選維度**：
   - [`lib/api/api_clz.dart:18-29`](file:///Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant/lib/api/api_clz.dart#L18-L29) 之 `businessesSearch` 僅支援 `term`、`latitude`、`longitude`、`locale`、`limit`、`offset`、`open_at`、`sort_by`、`price`。
   - 官方 Yelp Fusion API 支援 `categories`（逗號分隔分類別名，如 `"japanese,bars"`）、`radius`（整數公尺，上限 40,000）、以及 `open_now`（布林值）。
2. **Repository 缺乏參數支援與 1,000 筆邊界防護**：
   - [`lib/data_layer/repositories/main_repo.dart:42-88`](file:///Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant/lib/data_layer/repositories/main_repo.dart#L42-L88) 與 [`lib/domain/repositories/main_repository.dart:8-14`](file:///Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant/lib/domain/repositories/main_repository.dart#L8-L14) 之 `fetchYelpSearchInfo` 僅支援舊有參數。
   - 分頁累積時直接執行 `_offset += MainRepo._maxItemsCountInList`。當滑動加載累積達 20 頁（`offset >= 1000`）時，Yelp API 會直接報錯 `400 Bad Request`，導致未處理例外與使用者介面呈現 `Failure` 崩潰。
3. **Model 與 UI 缺乏配置**：
   - [`lib/models/filter_configs.dart`](file:///Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant/lib/models/filter_configs.dart) 僅有 `price`、`openAt`、`sortBy` 三種維度，未包含 `categories`、`radius`、`openNow`。
   - [`lib/flow/main/bloc/main_event.dart`](file:///Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant/lib/flow/main/bloc/main_event.dart) 之 `FetchSearchInfo` 未攜帶新維度。

### 1.2 為什麼是問題

- **搜尋維度貧乏**：使用者無法在附近縮小範圍（如 500 公尺至 5 公里），亦無法直接鎖定營業中或特定菜系（日本料理、義大利麵等）。
- **長列表滑動崩潰風險**：熱門城市（如台北、東京）餐廳極多，使用者一路向下滾動加載超過 1,000 筆時，因 Yelp API 硬性限制 `offset + limit <= 1000`，App 會直接崩潰卡死。

### 1.3 【核心判斷】（Linus 模式）

**✅ 值得做。**
- **資料結構**：
  - 核心資料流向：`FilterConfigs`（UI 選擇狀態） → `MainEvent.FetchSearchInfo` → `MainBloc` → `MainRepository.fetchYelpSearchInfo` → `APIClz.businessesSearch`。
  - 所有新參數採選填（`nullable`）設計，不破壞既有介面呼叫（"Never break userspace"）。
- **消滅邊界情況**：
  - 在 `MainRepo` 加入衛語句（Guard Clause）：當 `_offset >= 1000` 或 `_offset + limit > 1000` 時主動截斷，直接返回既有資料集合，不再對遠端發動無效 400 請求。
- **複雜度控制**：
  - 不引入任何外部套件。
  - 不做過度工程的全量分類樹選擇器（分類樹屬於 A-8.12 範疇），本案專注於參數打通、配置模型擴充與分頁防禦。

---

## 2. 使用者故事

1. 身為**使用者**，我可以在篩選設定中指定搜尋半徑（如 1000m、5000m）、分類別名或勾選「營業中」，從而得到更精確的餐廳搜尋結果。
2. 身為**使用者**，當我在餐廳列表持續下拉載入超過 1,000 筆時，App 不會報錯崩潰，而是平順停在底端。
3. 身為**開發者**，呼叫 `businessesSearch` 或 `fetchYelpSearchInfo` 時，既有代碼呼叫點完全相容不受影響。

---

## 3. 驗收條件 (Acceptance Criteria)

- **AC-1 (API)**：`APIClz.businessesSearch` 新增 `@Query('categories') String? categories`、`@Query('radius') int? radius`、`@Query('open_now') bool? openNow`，並更新產生的 `api_clz.g.dart`。
- **AC-2 (Domain & Data)**：
  - `MainRepository.fetchYelpSearchInfo` 擴充具名選填參數 `{String? categories, int? radius, bool? openNow}`。
  - `MainRepo` 正確將新參數轉發給 `APIClz.businessesSearch`。
- **AC-3 (1,000 筆邊界防護)**：
  - 當 `_offset >= 1000` 時，`fetchYelpSearchInfo` 攔截請求，不再呼叫 `_api.businessesSearch`，回傳既有過濾後列表。
  - 若 `_offset + limit > 1000`，clamp `limit = 1000 - _offset` 或優雅標記底端。
- **AC-4 (Models)**：
  - `FilterConfigs` 擴充 `categories`、`radius`、`openNow` 欄位與相應的 getter / setter / `clearConfig` 支援。
- **AC-5 (BLoC)**：
  - `FetchSearchInfo` event 支援 `categories`、`radius`、`openNow` 參數，並轉發至 `MainRepository`。
- **AC-6 (測試覆蓋)**：
  - 單元測試驗證 `MainRepo` 轉發所有新參數給 `APIClz`。
  - 單元測試驗證 `_offset >= 1000` 時的分頁防護邊界邏輯。
  - 全套既有測試（Unit / Widget / BLoC）全數通過，零 regression。

---

## 4. 明確排除 (Out of Scope)

- **A-8.12 全量分類樹選單**：此規格不建立 Yelp 1,500+ 分類層級樹狀 UI，僅提供 `categories` 別名篩選功能。
- **A-8.9 即時 Autocomplete 聯想 UI**：此規格不變更首頁搜尋列即時聯想機制。
- **既有端點破壞**：不更改既有位置參數順序，新參數一律以 Named Parameters 附加。
