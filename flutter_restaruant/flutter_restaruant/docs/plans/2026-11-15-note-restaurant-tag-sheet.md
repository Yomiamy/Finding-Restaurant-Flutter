# 實作計畫：F-2.4 筆記地點打卡 Tag 點擊彈出輕量餐廳摘要 BottomSheet

> 項目編號：**F-2.4**  
> 建立日期：2026-11-15  
> 關聯規格：[`docs/features/2026-11-15-note-restaurant-tag-sheet.md`](../features/2026-11-15-note-restaurant-tag-sheet.md)  
> 實查基線：`main`  
> 狀態：草稿（等待 STAGE 0b plan-verifier 初審與使用者確認）

---

## 1. 目標與架構方案權衡

### 1.1 目標
為「探店筆記」的瀑布流卡片（`NoteMasonryCard`）與筆記詳情頁（`NoteDetailPage`）中的地點打卡標籤加上點擊互動，彈出輕量餐廳摘要 BottomSheet（`NoteRestaurantSummarySheet`），串接既有 `RestaurantDetailRepository` 呈現餐廳評分、營業狀態、價位分類與地址，並提供 **「查看餐廳詳情」**（跳轉 `RestaurantDetailPage`）與 **「Google Maps 導航」** 兩大轉化行動。

### 1.2 方案權衡（Trade-offs）

| 評估維度 | 方案 A（採用）：`StatefulWidget` + 私有 `sealed class _SheetState` | 方案 B（淘汰）：新建 `NoteRestaurantSheetBloc`（Event / State / Bloc 三檔） |
|:---|:---|:---|
| **狀態本質** | 單一 BottomSheet 生命週期內的一次性 `Future` 查詢（加失敗重試），無跨畫面共享狀態 | 過度設計；為單一 `fetchYelpRestaurantDetailInfo` 包裝 Event/State/Bloc 徒增 3 個檔案與樣板碼 |
| **型別安全與邊界消滅** | 符合 Style Guide §5.4：以 `sealed class _SheetState`（`_SheetLoading` / `_SheetLoaded` / `_SheetUnlinked` / `_SheetFailure`）搭配窮盡式 `switch` 編譯期強制覆蓋所有分支 | 同樣用 `sealed class`，但多一層 `BlocProvider` 與 `Stream` 訂閱開銷 |
| **可測試性** | `NoteRestaurantSummarySheet` 建構子直接支援選填注入 `RestaurantDetailRepository? repository` 與 `void Function(String query)? onOpenMaps`（不污染 `NotesFeedPage` / `NoteDetailPage` 建構子） | 需額外引入 `bloc_test` 測單一方法轉發 |

**結論**：採用 **方案 A**，遵守 Linus「消滅非必要複雜度」與 Ponytail YAGNI 原則。

---

## 2. 資料結構與邊界條件消滅設計

1. **DTO 與 Entity 邊界正規化**：
   - `UgcNoteDto` 新增 `@JsonKey(name: 'restaurant_id') final String? restaurantId;`。
   - `UgcNoteEntity` 新增 `final String restaurantId`（建構子預設 `this.restaurantId = ''`），在 `UgcNoteEntity.fromDto` 中以 `(dto.restaurantId ?? '').trim()` 正規化為非 null 字串，UI 層只需檢查 `note.restaurantId.isNotEmpty`，徹底消滅 `null` 與空白字串 `"   "` 的雙重判斷。
2. **四態封閉狀態機（`sealed class _SheetState`）**：
   - `_SheetUnlinked`：當 `note.restaurantId.isEmpty` 時於 `initState` 直接進入此狀態，**不發起任何網路請求**，呈現餐廳名稱與 Google Maps 導航按鈕。
   - `_SheetLoading`：當 `note.restaurantId.isNotEmpty` 時於 `initState`（及重試時）進入此狀態並呼叫 `fetchYelpRestaurantDetailInfo(note.restaurantId)`。
   - `_SheetLoaded(final RestaurantDetailEntity detail)`：當 `fetchYelpRestaurantDetailInfo` 成功回傳且 `(detail.id?.trim().isNotEmpty ?? false) || (detail.name?.trim().isNotEmpty ?? false)` 時進入，呈現完整餐廳摘要與雙行動按鈕。
   - `_SheetFailure`：當拋出 `Exception`（如 `DioException`）、回傳空殼物件、或 DI 未註冊 `RestaurantDetailRepository` 時進入，呈現重試按鈕（複用 `S.current.empty_data_retry`）與 Google Maps 降級導航按鈕。
3. **Google Maps 查詢參數單一純函式（消除雙重 URL 編碼）**：
   - `Utils.openUrl` 內部的 `Utils.encodeQueryParameters` 已對每個參數值呼叫 `Uri.encodeComponent(e.value)`。因此 `buildGoogleMapsQuery` 必須回傳**未編碼的原始字串**，避免中文店名遭雙重編碼：
   ```dart
   static String buildGoogleMapsQuery(
     UgcNoteEntity note,
     RestaurantDetailEntity? detail,
   ) {
     final lat = detail?.coordinates?.latitude;
     final lng = detail?.coordinates?.longitude;
     if (lat != null && lng != null) {
       return sprintf('%f,%f', [lat, lng]);
     }
     final name = (detail?.name?.trim().isNotEmpty ?? false)
         ? detail!.name!.trim()
         : note.restaurantName.trim();
     return name;
   }
   ```
   - 呼叫端對齊 `RestaurantInfoCell` 既有寫法：
   ```dart
   Utils.openUrl(
     scheme: Constants.httpsScheme,
     host: Constants.googleMapHost,
     path: Constants.googleMapNavigationPath,
     parameters: <String, String>{
       Constants.googleMapNavigationLatLng: query,
     },
   );
   ```
4. **精確映射 `RestaurantEntity` 與 `id` 非空保底（Never Break Userspace）**：
   - `RestaurantDetailPage` 在 `didChangeDependencies` 讀取 `_summaryInfo` 並執行 `_bloc.add(FetchDetailInfo(id: _summaryInfo.id!))`（強制非空 `!`），且其頂部 `RestaurantHeadCell` 點擊收藏時會將該 `RestaurantEntity` 寫入本地收藏庫。
   - 因此 `NoteRestaurantSummarySheet` 在跳轉 `RestaurantDetailPage` 時，透過 `_toRestaurantEntity(UgcNoteEntity note, RestaurantDetailEntity detail)` 映射 `RestaurantEntity` 實際存在的欄位，並以 `note.restaurantId` 保底 `id` 絕不為空或 `null`：
   ```dart
   static RestaurantEntity toRestaurantEntity(
     UgcNoteEntity note,
     RestaurantDetailEntity detail,
   ) {
     final resolvedId = (detail.id?.trim().isNotEmpty ?? false)
         ? detail.id!.trim()
         : note.restaurantId;
     final resolvedName = (detail.name?.trim().isNotEmpty ?? false)
         ? detail.name!.trim()
         : note.restaurantName;
     return RestaurantEntity(
       id: resolvedId,
       name: resolvedName,
       imageUrl: detail.imageUrl,
       rating: detail.rating,
       reviewCount: detail.reviewCount,
       price: detail.price,
       phone: detail.phone,
       categories: detail.categories,
       location: detail.location,
       coordinates: detail.coordinates,
     );
   }
   ```

---

## 3. 任務切分與依賴關係

| 任務編號 | 負責範圍 | 異動檔案（寫入路徑完全互斥） | 執行方式 |
|:---|:---|:---|:---:|
| **T1** | `UgcNoteDto` / `UgcNoteEntity` 擴充 `restaurantId`、多國語系與資料層單元測試 | `lib/api/dto/ugc_note_dto.dart`<br>`lib/api/dto/ugc_note_dto.g.dart`<br>`lib/domain/entities/ugc_note_entity.dart`<br>`lib/l10n/intl_zh_TW.arb`<br>`lib/l10n/intl_en.arb`<br>`lib/generated/intl/messages_all.dart`<br>`lib/generated/intl/messages_en.dart`<br>`lib/generated/intl/messages_zh_TW.dart`<br>`lib/generated/l10n.dart`<br>`test/data_layer/ugc_note_repo_test.dart` | 序列第一步 |
| **T2** | `NoteRestaurantSummarySheet` 元件、`NoteDetailPage` 與 `NotesFeedPage` 雙入口串接及 Widget 測試 | `lib/flow/notes/view/note_restaurant_summary_sheet.dart`（新增）<br>`lib/flow/notes/view/note_detail_page.dart`<br>`lib/flow/notes/view/notes_feed_page.dart`<br>`lib/flow/notes/view/view_barrel.dart`<br>`test/flow/notes/note_restaurant_summary_sheet_test.dart`（新增）<br>`test/flow/notes/note_detail_page_test.dart`<br>`test/flow/notes/notes_feed_page_test.dart` | 序列第二步（依賴 T1） |

---

## 4. 詳細設計與具體實作步驟

### 4.1 T1：資料層擴充與多國語系

#### 4.1.1 多國語系 (`lib/l10n/intl_zh_TW.arb` & `lib/l10n/intl_en.arb`)
新增 4 個語系鍵值並執行 `dart run intl_utils:generate`（評論數與重試按鈕直接複用既有 `S.current.review_count_suffix` 與 `S.current.empty_data_retry`）：
- `note_restaurant_sheet_view_detail`: `"查看餐廳詳情"` / `"View Restaurant Details"`
- `note_restaurant_sheet_open_maps`: `"Google Maps 導航"` / `"Navigate with Google Maps"`
- `note_restaurant_sheet_unlinked_hint`: `"此筆記尚未綁定餐廳詳情，可直接開啟地圖搜尋導航"` / `"This note isn't linked to a restaurant profile yet. You can still navigate via Google Maps."`
- `note_restaurant_sheet_error`: `"無法載入餐廳摘要資訊"` / `"Unable to load restaurant summary"`

#### 4.1.2 `lib/api/dto/ugc_note_dto.dart` & `ugc_note_dto.g.dart`
- 在 `UgcNoteDto` 新增：
  ```dart
  @JsonKey(name: 'restaurant_id')
  final String? restaurantId;
  ```
- 加入建構子 `this.restaurantId` 與 `props`，並更新 `ugc_note_dto.g.dart` 的 `_$UgcNoteDtoFromJson` 與 `_$UgcNoteDtoToJson` 對 `'restaurant_id'` 的序列化映射。

#### 4.1.3 `lib/domain/entities/ugc_note_entity.dart`
- 在 `UgcNoteEntity` 新增：
  ```dart
  final String restaurantId;
  ```
- 建構子加入選填預設值 `this.restaurantId = ''`（維持既有呼叫端 100% 向後相容）。
- `UgcNoteEntity.fromDto` 新增：
  ```dart
  final normalizedRestaurantId = (dto.restaurantId ?? '').trim();
  ```
  並傳入 `restaurantId: normalizedRestaurantId`，同時將 `restaurantId` 加入 `props`。

#### 4.1.4 `test/data_layer/ugc_note_repo_test.dart`
- 新增測試驗證：
  1. `UgcNoteDto.fromJson` 與 `UgcNoteEntity.fromDto` 正確解析 `restaurant_id` 並去除前後空白。
  2. 缺少 `restaurant_id` 欄位時，`UgcNoteEntity.restaurantId` 預設為空字串 `''`。

---

### 4.2 T2：`NoteRestaurantSummarySheet` 與雙入口整合

#### 4.2.1 `lib/flow/notes/view/note_restaurant_summary_sheet.dart`（新增）
- 提供靜態方法 `NoteRestaurantSummarySheet.show`：
  ```dart
  static Future<void> show(
    BuildContext context, {
    required UgcNoteEntity note,
    RestaurantDetailRepository? repository,
    void Function(String query)? onOpenMaps,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ThemeSize.space16),
        ),
      ),
      builder: (sheetContext) => NoteRestaurantSummarySheet(
        note: note,
        repository: repository,
        onOpenMaps: onOpenMaps,
      ),
    );
  }
  ```
- 狀態與生命週期：
  - 若 `widget.note.restaurantId.isEmpty`，初始狀態為 `const _SheetUnlinked()`。
  - 若 `widget.note.restaurantId.isNotEmpty`，初始狀態為 `const _SheetLoading()`，並於 `initState` 執行 `_loadDetail()`：
    - 優先使用 `widget.repository`，若為 `null` 且 `GetIt.I.isRegistered<RestaurantDetailRepository>()` 則取 `GetIt.I<RestaurantDetailRepository>()`；若均未提供則轉為 `const _SheetFailure()`。
    - 呼叫 `repo.fetchYelpRestaurantDetailInfo(widget.note.restaurantId)`：
      - `if (!mounted) return;`（遵守 Style Guide §7.5 非同步安全）。
      - 若 `(detail.id?.trim().isNotEmpty ?? false) || (detail.name?.trim().isNotEmpty ?? false)`，狀態更新為 `_SheetLoaded(detail)`；否則轉為 `const _SheetFailure()`。
    - 捕捉 `on Exception catch (e, st)`，以 `Logger().e('Failed to fetch note restaurant detail', error: e, stackTrace: st)` 記錄後更新為 `const _SheetFailure()`。
- 拆分獨立小 Widget（遵守 Style Guide 禁止 `_buildSubWidget` 輔助方法）：
  - `NoteRestaurantDetailPreview`：
    - 渲染封面圖（80x80 圓角縮圖，失敗回退 `Assets.images.empty`）。
    - 營業狀態膠囊：僅當 `detail.hours != null && detail.hours!.isNotEmpty && detail.hours!.first.isOpenNow != null` 時渲染（`isOpenNow == true` 顯示綠底 `S.current.business_status_open`；`false` 顯示灰底 `S.current.business_status_closed`）。
    - 評分與評論數：`RatingStars(rating: detail.rating ?? 0)` + `'${detail.reviewCount ?? 0}${S.current.review_count_suffix}'`。
    - 價位與分類列（如 `$$ · 拉麵`）、地址列（`detail.location?.displayAddress?.join(', ')`）。
  - 點擊 **「查看餐廳詳情」**（`Key('note_restaurant_sheet_detail_btn')`）：
    ```dart
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.pushNamed(
      RestaurantDetailPage.routeName,
      arguments: Tuple2(toRestaurantEntity(widget.note, detail), null),
    );
    ```
  - 點擊 **「Google Maps 導航」**（`Key('note_restaurant_sheet_maps_btn')`）：
    ```dart
    final query = buildGoogleMapsQuery(widget.note, detail);
    if (widget.onOpenMaps != null) {
      widget.onOpenMaps!(query);
      return;
    }
    Utils.openUrl(
      scheme: Constants.httpsScheme,
      host: Constants.googleMapHost,
      path: Constants.googleMapNavigationPath,
      parameters: <String, String>{
        Constants.googleMapNavigationLatLng: query,
      },
    );
    ```

#### 4.2.2 `lib/flow/notes/view/note_detail_page.dart`
- 不更動 `NoteDetailPage` 建構子簽章（零 Prop-Drilling）。
- `NoteRestaurantTag` 新增 `final VoidCallback? onTap;`，外層以 `Material` + `InkWell(borderRadius: BorderRadius.circular(ThemeSize.space16), onTap: onTap)` 包覆，並在文字右側加上 `Icon(Icons.chevron_right, size: ThemeSize.size16, color: ThemeColor.colord84a20)` 視覺提示可點擊。
- 點擊時呼叫 `NoteRestaurantSummarySheet.show(context, note: note)`。

#### 4.2.3 `lib/flow/notes/view/notes_feed_page.dart`
- 不更動 `NotesFeedPage` 建構子簽章（零 Prop-Drilling）。
- `NoteMasonryCard` 新增選填 `final VoidCallback? onRestaurantTagTap;`，將 `if (note.restaurantName.isNotEmpty)` 的餐廳地點列包進 `InkWell(key: Key('note_card_restaurant_tag_${note.id}'), onTap: onRestaurantTagTap, ...)`，點擊時直接彈出 `NoteRestaurantSummarySheet.show(context, note: note)`，不會誤觸外層卡片進入筆記詳情頁。

#### 4.2.4 `lib/flow/notes/view/view_barrel.dart`
- 匯出 `export 'note_restaurant_summary_sheet.dart';`。

---

## 5. 破壞性與回滾機制 (Blast Radius & Rollback)

- **相容性保證**：
  - `UgcNoteEntity.restaurantId` 具預設值 `''`，`NoteDetailPage` 與 `NotesFeedPage` 建構子完全不變，既有路由表（`routes_table.dart`）與所有既有測試零破壞。
- **回滾機制**：
  - 本功能完全封裝於 `notes` 模組與 `UgcNoteDto`/`UgcNoteEntity` 的選填欄位，若需回滾可直接 `git revert` 該 PR，不影響 Firestore 既有 `ugc_notes` documents 或 `RestaurantDetailPage` 主流程。

---

## 6. 驗證與測試命令

1. **多國語系生成**：
   ```bash
   dart run intl_utils:generate
   ```
2. **單元與 Widget 測試**：
   ```bash
   flutter test test/data_layer/ugc_note_repo_test.dart test/flow/notes/note_restaurant_summary_sheet_test.dart test/flow/notes/note_detail_page_test.dart test/flow/notes/notes_feed_page_test.dart
   ```
3. **全專案迴歸與靜態分析**：
   ```bash
   flutter analyze .
   flutter test
   ```
