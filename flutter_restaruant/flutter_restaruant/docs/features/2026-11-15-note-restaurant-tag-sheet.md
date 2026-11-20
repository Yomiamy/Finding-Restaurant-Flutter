# 功能規格：F-2.4 筆記地點打卡 Tag 點擊彈出輕量餐廳摘要 BottomSheet

- **日期**：2026-11-15
- **狀態**：已實作（採 `NoteRestaurantSheetBloc` 單向資料流架構）
- **實查基線**：`main`
- **需求來源**：`gen-grill` 結構化 brief（Q1–Q5 五項齊備，2 輪問答收斂）
- **相關 brainstorm 項目**：[`docs/brainstorm/2026-11-21-features-brainstorm.md`](../brainstorm/2026-11-21-features-brainstorm.md) §2.2 [F-2.4] (L373-379, L682)

---

## 1. 背景與問題

### 1.1 現況（Q5 程式碼實查）

1. **打卡地點標籤僅為純靜態文字，缺乏轉化鏈路**：
   - 在 [`lib/flow/notes/view/note_detail_page.dart`](../../lib/flow/notes/view/note_detail_page.dart) 中，`NoteRestaurantTag` 僅渲染 `Icons.place` 與 `restaurantName` 膠囊文字，無任何點擊事件。
   - 在 [`lib/flow/notes/view/notes_feed_page.dart`](../../lib/flow/notes/view/notes_feed_page.dart) 中，`NoteMasonryCard` 底部的餐廳地點列亦僅為純文字，點擊只會觸發整張卡片進入 `NoteDetailPage`。
2. **資料模型缺漏 `restaurantId`（文件與實況落差）**：
   - 雖然 brainstorm 文件原記載「`UgcNoteEntity.restaurantId` 已隨 F-2.3 實作」，但實查 [`lib/api/dto/ugc_note_dto.dart`](../../lib/api/dto/ugc_note_dto.dart) 與 [`lib/domain/entities/ugc_note_entity.dart`](../../lib/domain/entities/ugc_note_entity.dart) 後確認：目前僅有 `@JsonKey(name: 'restaurant_name') final String? restaurantName;`，**尚未定義 `restaurant_id` / `restaurantId` 欄位**。

### 1.2 為什麼是問題

- 使用者在瀏覽美食探店筆記（種草）被菜色吸引後，最核心的下一步行動是「查看這家餐廳的評分／營業時間／評價」或「直接導航前往」。
- 現況下使用者只能記住餐廳名稱，退出筆記頁面再回首頁手動搜尋，轉化鏈路斷裂且體驗繁瑣。

### 1.3 【核心判斷】（Linus 模式）

**✅ 值得做。**

- **資料結構**：
  - 在 `UgcNoteDto` 新增選填 `@JsonKey(name: 'restaurant_id') final String? restaurantId;`，並於 `UgcNoteEntity` 新增 `final String restaurantId`（建構子預設為 `''`，`UgcNoteEntity.fromDto` 以 `(dto.restaurantId ?? '').trim()` 正規化）。
  - 點擊地點標籤時彈出 `NoteRestaurantSummarySheet`，由專屬 `NoteRestaurantSheetBloc` 驗證 `restaurantId` 並複用既有 `RestaurantDetailRepository.fetchYelpRestaurantDetailInfo(note.restaurantId)` 與 `FavorRepository.isFavor` 拉取 `RestaurantDetailEntity` 與收藏狀態（View 層不直接依賴 Repository），不另造冗餘 API 或重複資料模型。
- **消滅特殊情況**：
  - **舊種子資料向後相容（無 `restaurant_id`）**：當 `note.restaurantId.isEmpty` 時，BottomSheet 不發起無效的 API 請求，直接以降級摘要模式顯示 `note.restaurantName` 與「Google Maps 導航」按鈕。
  - **導航參數統一化（避免雙重 URL 編碼）**：以單一純函式 `buildGoogleMapsQuery` 決定 Google Maps 查詢原始字串——若 `RestaurantDetailEntity.coordinates` 具備有效經緯度則回傳 `sprintf('%f,%f', [lat, lng])`，否則自動回退為去空白後的餐廳名稱純文字（因 `Utils.openUrl` 內部的 `Utils.encodeQueryParameters` 已統一執行 `Uri.encodeComponent`，故不在外層重複編碼），再以 `Constants.googleMapHost` 與 `Constants.googleMapNavigationPath` 呼叫 `Utils.openUrl`，消滅 UI 層對座標有無的分支判斷。
- **零破壞性（Never break userspace）**：
  - `UgcNoteEntity` 的 `restaurantId` 提供預設值 `''`，所有既有測試與呼叫端無須修改即可編譯通過。
  - 不引入任何新第三方相依套件，完全複用既有 `RestaurantDetailRepository`、`RatingStars`、`Utils.openUrl` 與 `RestaurantDetailPage`。

---

## 2. 使用者故事

1. **從筆記詳情頁快速預覽餐廳摘要**：身為**正在閱讀探店筆記的使用者**，我可以點擊筆記中的橘色地點打卡膠囊（`NoteRestaurantTag`），立即在底部彈出輕量餐廳摘要 BottomSheet，查看餐廳縮圖、星級評分、評論數、價位與分類、營業狀態及地址，無須離開當前閱讀脈絡。
2. **從瀑布流卡片直接喚起餐廳摘要**：身為**在探店筆記瀑布流快速滑動的使用者**，我可以點擊 `NoteMasonryCard` 上的地點列直接彈出餐廳摘要 BottomSheet，而不會誤觸進入筆記詳情頁。
3. **一鍵前往餐廳詳情或 Google Maps 導航**：身為**被食記種草的使用者**，我可以在餐廳摘要 BottomSheet 點選「查看餐廳詳情」進入完整 `RestaurantDetailPage`（支援收藏、評論摘要與拍菜單），或點選「Google Maps 導航」直接喚起外部地圖導航。

---

## 3. 驗收條件 (Acceptance Criteria)

- **AC-1 (`UgcNoteDto` 與 `UgcNoteEntity` 欄位擴充)**：
  - `UgcNoteDto` 新增 `@JsonKey(name: 'restaurant_id') final String? restaurantId;`，並更新 `ugc_note_dto.g.dart` 與 `props`。
  - `UgcNoteEntity` 新增 `final String restaurantId`（建構子預設 `this.restaurantId = ''`），`UgcNoteEntity.fromDto` 將 `dto.restaurantId` 去頭尾空白後映射（`null` 轉為 `''`）。
- **AC-2 (雙觸發入口：`NoteDetailPage` 與 `NotesFeedPage`)**：
  - `NoteDetailPage` 的 `NoteRestaurantTag` 支援點擊並彈出 `NoteRestaurantSummarySheet`。
  - `NotesFeedPage` 的 `NoteMasonryCard` 地點列（`Key('note_card_restaurant_tag_${note.id}')`）支援獨立點擊並彈出 `NoteRestaurantSummarySheet`，且不觸發外層卡片跳轉 `NoteDetailPage`。
- **AC-3 (`NoteRestaurantSheetBloc` 與 `NoteRestaurantSummarySheet` 完整餐廳摘要展示)**：
  - 由 `NoteRestaurantSheetBloc` 管理單向資料流狀態；當 `note.restaurantId.isNotEmpty`（且通過 ID 格式驗證）時，透過 `RestaurantDetailRepository.fetchYelpRestaurantDetailInfo(note.restaurantId)` 載入餐廳詳情，並搭配 `FavorRepository.isFavor`（2 秒逾時降級為 `false`）解析收藏狀態：
    - 載入中顯示餐廳名稱標題與 `LoadingWidget`。
    - 載入成功（回傳有效 `detail`，即 `detail.id` 或 `detail.name` 非空）顯示：餐廳封面縮圖（空 URL 或失敗回退 `Assets.images.empty`）、餐廳名稱、`RatingStars` 與評分／評論數（複用 `S.current.review_count_suffix`）、價位與分類列（如 `$$ · 日本料理`）、營業中／已打烊狀態標籤（僅在 `detail.hours != null && detail.hours!.isNotEmpty && detail.hours!.first.isOpenNow != null` 時渲染，複用 `S.current.business_status_open` / `S.current.business_status_closed`）、地址列（若有 `location.displayAddress`）。
- **AC-4 (雙核心轉化行動按鈕)**：
  - **「查看餐廳詳情」**（`Key('note_restaurant_sheet_detail_btn')`）：僅在 `detail` 載入成功時顯示；點擊後關閉 BottomSheet 並以 `Navigator.of(context).pushNamed(RestaurantDetailPage.routeName, arguments: Tuple2(restaurantEntity, null))` 導航至餐廳詳情頁，其中 `restaurantEntity` 映射 `RestaurantEntity` 實際欄位（`id`、`name`、`imageUrl`、`rating`、`reviewCount`、`price`、`categories`、`coordinates`、`location`、`phone`），且 `id` 以 `note.restaurantId` 保底非空以確保 `RestaurantDetailPage` 與收藏功能正常運作。
  - **「Google Maps 導航」**（`Key('note_restaurant_sheet_maps_btn')`）：有經緯度時以 `lat,lng` 導航，無經緯度時以去空白後的餐廳名稱純文字作為 `Constants.googleMapNavigationLatLng` 參數呼叫 `Utils.openUrl(scheme: Constants.httpsScheme, host: Constants.googleMapHost, path: Constants.googleMapNavigationPath, parameters: ...)`。
- **AC-5 (無 `restaurantId` 與載入失敗之優雅降級)**：
  - 當 `note.restaurantId.isEmpty` 時，不發起網路請求，直接顯示 `note.restaurantName`、降級提示文字與可用的「Google Maps 導航」按鈕（以 `restaurantName` 搜尋導航）。
  - 當 `note.restaurantId.isNotEmpty` 但 `fetchYelpRestaurantDetailInfo` 拋出 `Exception` 或回傳空殼資料時，顯示錯誤提示、重試按鈕（`Key('note_restaurant_sheet_retry_btn')`，複用 `S.current.empty_data_retry`）以及可用的「Google Maps 導航」降級按鈕。
- **AC-6 (靜態分析與測試覆蓋)**：
  - 補齊 `ugc_note_repo_test.dart`（驗證 `restaurant_id` 解析與缺省預設值）、`note_restaurant_sheet_bloc_test.dart`（以 `bloc_test` 驗證 ID 校驗、未綁定降級、詳情載入與收藏 2 秒逾時降級、空殼回應／例外失敗重試、逾期請求捨棄）、`note_restaurant_summary_sheet_test.dart`（涵蓋載入成功、無 `restaurantId` 降級、載入失敗重試、點擊跳轉 `RestaurantDetailPage`、注入 BLoC 與 GetIt 生命週期管理）、以及 `note_detail_page_test.dart` 與 `notes_feed_page_test.dart` 的互動測試。
  - `flutter analyze .` 零警告，`flutter test` 全數通過。

---

## 4. 明確排除 (Out of Scope)

- **不包含** `F-4.1` In-App Micro-Booking 免跳轉極速訂位抽屜與即時空位查詢（`F-4.1` 尚未實作）。
- **不包含** UGC 筆記的發文／編輯／打卡地點搜尋選取器（屬 `F-5.1` 範圍）。
- **不新增** 任何第三方套件至 `pubspec.yaml`。
