# 實作計畫：F-2.2 自訂美食地圖社群共編（Collaborative Food Maps）

> 項目編號：**F-2.2**  
> 建立日期：2026-11-25（修訂第 2 版，補齊 Rules 長度／型別斷言、Transaction 重試安全與並發投票不覆蓋）  
> 關聯規格：[`docs/features/2026-11-25-collaborative-food-maps.md`](../features/2026-11-25-collaborative-food-maps.md)  
> 實查基線：`main`  
> 狀態：初審通過（`READY`），等待使用者確認後進入 STAGE 1

---

## 1. 目標與架構方案權衡

### 1.1 目標
在不更動既有 `favors/{uid}/items` 與零新增 `pubspec.yaml` 相依的前提下，落地獨立頂層共編美食地圖功能：已登入使用者可建立多張共編地圖、複製 8 碼高熵邀請碼邀請好友加入、從 `RestaurantDetailPage` 或地圖頁「從最愛匯入」收錄餐廳、於列表／地圖雙視圖（行動平台）透過決定性成員色標辨識推薦人、進行讚／踩投票與私房推薦短評協作。

### 1.2 方案權衡（Trade-offs）

#### 決策 A：Firestore 邀請碼索引結構

| 評估維度 | 方案 A1（採用）：`food_maps/{mapId}` + 輕量索引 `food_map_invites/{inviteCode}` | 方案 A2（淘汰）：僅 `food_maps` 單集合，加入時以 `where('invite_code', isEqualTo: code)` 查詢 |
| :--- | :--- | :--- |
| **Security Rules 安全性** | `food_map_invites` 設 `allow get: if isSignedIn(); allow list: if false;`（不可枚舉），`food_maps` 維持 `allow list: if uid in member_uids`（僅成員可列舉） | Firestore Rules 無法檢查 `where` 條件值，為了讓非成員能查詢邀請碼，`food_maps` 必須放寬 `allow list`，造成任意登入者可讀取未授權地圖的資料外洩風險 |
| **邀請碼唯一性原子保證** | 建立時在 `runTransaction` 內以 `tx.get(inviteRef)` 檢查碰撞並同時寫入主文件與索引文件（Rules 以 `getAfter` 校驗歸屬），**零併發碰撞** | Firestore Transaction 不支援 `query`，無法原子保證邀請碼不撞碼 |
| **額外成本** | 僅 1 份 2 欄位文件（`map_id`, `owner_uid`），刪除地圖時由獨立最終 batch 一併刪除，零複合索引需求 | 需承受安全規則妥協或另建 Cloud Function |

**結論**：採用 **方案 A1**。`food_map_invites/{inviteCode}` 完全封裝在 `FoodMapDataSource` 內部，對 Domain／Presentation 零外洩。

#### 決策 B：查詢排序方式（免除 Composite Index）

- **採用**：`fetchMyFoodMaps()` 執行 `where('member_uids', arrayContains: uid).get()` 後在記憶體內依 `updatedAtMs` 降序排序；`fetchFoodMapItems(mapId)` 執行 `items.get()` 後在記憶體內依 `addedAtMs` 降序排序。
- **理由**：Firestore 組合 `arrayContains` + `orderBy` 強制要求在 Firebase Console 手動建立 Composite Index，漏建會在生產環境拋出 `FAILED_PRECONDITION`（對齊 `UgcNoteDataSource` 的記憶體排序設計）。

#### 決策 C：表現層 BLoC 切分

- 依 `flutter-styles.md` §7.3 與 `docs/architecture/overview.md` 硬性邊界，凡存取 `Repository` 之頁面與 BottomSheet 皆對應單一職責 BLoC，純本地 UI 狀態（表單輸入、列表／地圖切換、匯入勾選暫存）保留於 `State`：
  1. `FoodMapsBloc`（路由級 `BlocProvider`）：清單載入／重整／建立／邀請碼加入／刪除／退出。
  2. `FoodMapDetailBloc`（路由級 `BlocProvider`）：單張地圖詳情＋餐廳項目載入／重整／投票／編輯短評／移除餐廳。
  3. `AddToFoodMapBloc`（Sheet 級，支援可選 `bloc` 注入、`_isLocalBloc` 關閉、`fromGetIt` 檢查 `isRegistered`）：供 `RestaurantDetailPage` 的 `AddToFoodMapSheet` 載入地圖、現場建圖並加入餐廳。
  4. `ImportFavoritesBloc`（Sheet 級，支援可選 `bloc` 注入、`_isLocalBloc` 關閉、`fromGetIt` 檢查 `isRegistered`）：供 `ImportFavoritesSheet` 讀取 `FavorRepository.fetchFavorInfos()` 並批次匯入至指定地圖。

---

## 2. 資料結構與邊界條件消滅設計

### 2.1 Firestore Schema

```text
food_maps/{mapId}
  ├── title: String                      // 1–40 字（trimmed）
  ├── description: String                // 0–120 字（trimmed）
  ├── owner_uid: String                  // 建立者 UID
  ├── owner_name: String                 // 建立者顯示名
  ├── invite_code: String                // 8 碼大寫英數（Random.secure + ABCDEFGHJKLMNPQRSTUVWXYZ23456789）
  ├── member_uids: List<String>          // 所有成員 UID（建立者必在其中）
  ├── member_names: Map<String, String>  // { uid: displayName }
  ├── item_count: int                    // 餐廳數（由 Transaction 維護，永不 < 0）
  ├── created_at_ms: int
  └── updated_at_ms: int

food_maps/{mapId}/items/{restaurantId}
  ├── restaurant: Map<String, dynamic>   // YelpRestaurantSummaryDto.toJson()（explicitToJson: true）
  ├── added_by_uid: String               // 推薦人 UID
  ├── added_by_name: String              // 推薦人顯示名
  ├── note: String                       // 私房推薦短評（0–140 字）
  ├── added_at_ms: int
  └── votes: Map<String, int>            // { uid: 1 (讚) | -1 (踩) }，建立時強制寫入空 Map {}

food_map_invites/{inviteCode}            // DataSource 內部防枚舉邀請碼索引
  ├── map_id: String
  └── owner_uid: String
```

### 2.2 邊界條件消滅對照

| 邊界情況 | 設計消滅方式 |
| :--- | :--- |
| **DTO 欄位命名與 Firestore snake_case 斷裂** | `FoodMapDto` 強制標註 `@JsonSerializable(fieldRename: FieldRename.snake)`；`FoodMapItemDto` 強制標註 `@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)` 且 `votes` 預設 `const <String, int>{}`，與 `YelpRestaurantSummaryDto`、所有查詢及 Security Rules 鍵名完全對齊。 |
| **查詢「我建立的」與「我加入的」地圖需合併** | 建立時 `owner_uid` 必寫入 `member_uids`，單一 `arrayContains` 查詢涵蓋全部。 |
| **重複加入同一間餐廳 / 膨脹 `item_count`** | 子集合 doc ID 固定為 `restaurantId`，且 `addRestaurant` / `importRestaurants` 於 `runTransaction` 內採嚴格 **Read-Before-Write（先讀完全部再寫）**：已存在則略過且不遞增 `item_count`。 |
| **刪除超過 498 筆餐廳之地圖超過 WriteBatch 500 上限** | 先以 `_batchLimit = 500` 完整分批刪除並 commit 所有 `items`，再**另開獨立最終 WriteBatch** 刪除 `food_maps/{mapId}` 與 `food_map_invites/{inviteCode}`（至多 2 筆寫入，永不爆 500 上限）。 |
| **離團原推薦人仍試圖編輯／移除舊餐廳** | `removeRestaurant` 與 `updateItemNote` 皆於 Transaction 內同時檢驗 `mapSnap.exists`（`mapNotFound`）、`member_uids.contains(uid)`（`permissionDenied`）與 `owner_uid == uid || added_by_uid == uid`，與 Security Rules 的 `isFoodMapMember(mapId)` 完全一致。 |
| **不同成員併發投票互相覆蓋（lost update）** | `setVote` 採單鍵點路徑更新 `itemRef.update({'votes.$uid': 1 | -1 | FieldValue.delete()})`（並驗證 `uid` 非空且不含 `.`），互不觸碰他人投票；`upvoteCount` / `downvoteCount` / `voteOf(uid)` 皆為衍生 getter。 |
| **同一使用者連點投票鈕競態** | `FoodMapDetailBloc` 以私有 `Set<String> _votingRestaurantIds` 攔截同一餐廳進行中的重複點擊；不同餐廳仍可並行投票。 |
| **跨平台／重啟後成員顏色跳動** | `FoodMapMemberStyle` 使用固定雜湊 `uid.codeUnits.fold(0, (a, c) => (a * 31 + c) & 0x7fffffff)` 映射 8 組 `(Color, BitmapDescriptor hue)`，不依賴 Dart isolate-salted `String.hashCode`。 |
| **邀請碼熵不足** | `FoodMapDataSource` 預設亂數生成器強制鎖定 `Random.secure()`（比照 `AppleSignInManager`），僅允許單元測試透過可選 `random` 注入確定性種子。 |
| **下拉重整 `Completer` 卡死風險** | `RefreshFoodMaps` / `RefreshFoodMapDetail` 均於 `try ... finally` 保證 `completer` 完成，且於 BLoC `close()` 內清理所有尚未完成之 `_pendingRefreshCompleters`，永不造成 `RefreshIndicator` 永久旋轉。 |
| **未登入／訪客誤入寫入路徑** | UI 層於 `MainPage` 與 `RestaurantDetailPage` 檢查 `SignInManager().isGuest || uid.isEmpty` 導向 `SignInPage`；`FoodMapDataSource` 層於**所有寫入方法最前頭**呼叫 `_requireUid()` 拋出 `StateError`，空 `uid` 讀取回傳空清單。 |
| **Firestore 異常與一般錯誤未收斂** | `FoodMapDataSource` 以 `_guardFirestore` 集中轉譯 `FirebaseException`（`permission-denied` → `permissionDenied`、`not-found` → `mapNotFound`／`itemNotFound`、其餘 → `unknown`）；`FoodMapErrorCode` 含 `unknown`，所有 BLoC 皆可完整映射非預期例外。 |
| **跨平台 GoogleMap 崩潰（macOS 等桌面）** | `FoodMapDetailPage` 僅在 `platformCapabilities().mapMode == true` 顯示視圖切換鈕並掛載 `FoodMapMapView`；桌面平台恆為列表模式。 |
| **跳轉 `RestaurantDetailPage` 參數型別不符閃退** | `FoodMapDetailPage` 與 `FoodMapMapView` 點擊餐廳卡片一律傳遞 `Tuple2<RestaurantEntity, dynamic>(item.restaurant, null)`（對齊 `restaurant_detail_page.dart:33-36` 強轉契約）。 |
| **既有 `DrawerWidget` 測試斷言 `Icons.map`** | 「美食地圖」項目使用 `Icons.edit_location_alt`（避開 `drawer_widget_test.dart:117` 之 `expect(find.byIcon(Icons.map), findsNothing)`）。 |

---

## 3. 任務切分、模型分級與並行拓撲

```text
      ┌──► T2 (Data + DI) [最強推論] ─────────┐
T1 ───┤                                       ├──► T5 (Entry Wiring + Full Verify) [標準]
[標準]└──► T3 (4 BLoCs + Style) [標準] ─► T4 ─┘
                                         [標準]
```

| 任務 | 負責範圍 | 複雜度／委派等級 | 異動檔案（嚴格互斥） | 依賴 |
| :--- | :--- | :---: | :--- | :---: |
| **T1** | Domain Entities／Exception／Repository Interface、DTOs（`FieldRename.snake` + `.g.dart`）、完整雙語 L10n（含 `intl_utils:generate`）與 Entity 單元測試 | 標準 | `lib/api/dto/food_map_dto.dart`（新增）<br>`lib/api/dto/food_map_dto.g.dart`（新增）<br>`lib/api/dto/food_map_item_dto.dart`（新增）<br>`lib/api/dto/food_map_item_dto.g.dart`（新增）<br>`lib/api/dto/dto_barrel.dart`<br>`lib/domain/entities/food_map_vote.dart`（新增）<br>`lib/domain/entities/food_map_entity.dart`（新增）<br>`lib/domain/entities/food_map_item_entity.dart`（新增）<br>`lib/domain/entities/food_map_exception.dart`（新增）<br>`lib/domain/entities/entities_barrel.dart`<br>`lib/domain/repositories/food_map_repository.dart`（新增）<br>`lib/domain/repositories/repositories_barrel.dart`<br>`lib/l10n/intl_zh_TW.arb`<br>`lib/l10n/intl_en.arb`<br>`lib/generated/l10n.dart` 及 `lib/generated/intl/*.dart`<br>`test/domain/food_map_entity_test.dart`（新增） | 無 |
| **T2** | `FoodMapDataSource`、`FoodMapRepo`、GetIt DI 註冊與 `FakeFirebaseFirestore` 完整單元測試 | 最強推論 | `lib/data_layer/datasources/food_map_data_source.dart`（新增）<br>`lib/data_layer/datasources/datasources_barrel.dart`<br>`lib/data_layer/repositories/food_map_repo.dart`（新增）<br>`lib/data_layer/repositories/repositories_barrel.dart`<br>`lib/app/di/injection.dart`<br>`test/data_layer/datasources/food_map_data_source_test.dart`（新增）<br>`test/data_layer/food_map_repo_test.dart`（新增）<br>`test/di_test.dart` | T1（與 T3 🟢 並行） |
| **T3** | `FoodMapsBloc`、`FoodMapDetailBloc`、`AddToFoodMapBloc`、`ImportFavoritesBloc`、`FoodMapMemberStyle` 與 `bloc_test` 單元測試 | 標準 | `lib/flow/food_maps/bloc/food_maps_bloc.dart`（新增）<br>`lib/flow/food_maps/bloc/food_maps_event.dart`（新增）<br>`lib/flow/food_maps/bloc/food_maps_state.dart`（新增）<br>`lib/flow/food_maps/bloc/food_map_detail_bloc.dart`（新增）<br>`lib/flow/food_maps/bloc/food_map_detail_event.dart`（新增）<br>`lib/flow/food_maps/bloc/food_map_detail_state.dart`（新增）<br>`lib/flow/food_maps/bloc/add_to_food_map_bloc.dart`（新增）<br>`lib/flow/food_maps/bloc/add_to_food_map_event.dart`（新增）<br>`lib/flow/food_maps/bloc/add_to_food_map_state.dart`（新增）<br>`lib/flow/food_maps/bloc/import_favorites_bloc.dart`（新增）<br>`lib/flow/food_maps/bloc/import_favorites_event.dart`（新增）<br>`lib/flow/food_maps/bloc/import_favorites_state.dart`（新增）<br>`lib/flow/food_maps/bloc/bloc_barrel.dart`（新增）<br>`lib/flow/food_maps/model/food_map_member_style.dart`（新增）<br>`test/flow/food_maps/food_maps_bloc_test.dart`（新增）<br>`test/flow/food_maps/food_map_detail_bloc_test.dart`（新增）<br>`test/flow/food_maps/add_to_food_map_bloc_test.dart`（新增）<br>`test/flow/food_maps/import_favorites_bloc_test.dart`（新增）<br>`test/flow/food_maps/food_map_member_style_test.dart`（新增） | T1（與 T2 🟢 並行） |
| **T4** | `FoodMapsPage`、`FoodMapDetailPage`、`FoodMapMapView`、`AddToFoodMapSheet`、`ImportFavoritesSheet` 與 Widget 測試 | 標準 | `lib/flow/food_maps/view/food_maps_page.dart`（新增）<br>`lib/flow/food_maps/view/food_map_detail_page.dart`（新增）<br>`lib/flow/food_maps/view/food_map_map_view.dart`（新增）<br>`lib/flow/food_maps/view/add_to_food_map_sheet.dart`（新增）<br>`lib/flow/food_maps/view/import_favorites_sheet.dart`（新增）<br>`lib/flow/food_maps/view/view_barrel.dart`（新增）<br>`lib/flow/food_maps/food_maps_barrel.dart`（新增）<br>`test/flow/food_maps/food_maps_page_test.dart`（新增）<br>`test/flow/food_maps/food_map_detail_page_test.dart`（新增）<br>`test/flow/food_maps/add_to_food_map_sheet_test.dart`（新增）<br>`test/flow/food_maps/import_favorites_sheet_test.dart`（新增） | T3 |
| **T5** | 路由註冊、`DrawerWidget`、`MainPage`、`RestaurantDetailPage` 入口銜接、既有測試更新（含 `main_page_test.dart`）與全量驗證 | 標準 | `lib/app/routes/routes_table.dart`<br>`lib/flow/main/view/drawer_widget.dart`<br>`lib/flow/main/view/main_page.dart`<br>`lib/flow/restaurant/view/restaurant_detail_page.dart`<br>`test/flow/main/view/drawer_widget_test.dart`<br>`test/flow/main/view/main_page_test.dart`<br>`test/flow/restaurant/restaurant_detail_page_test.dart` | T2, T4 |

> **共享檔案唯一擁有者檢查**：`pubspec.yaml` 不異動；`lib/l10n/*` 與 `lib/generated/*` 僅由 T1 修改（完整 key 清單於 §4.1.4 鎖定）；`injection.dart` 與 `di_test.dart` 僅由 T2 修改；`routes_table.dart`、`drawer_widget.dart`、`main_page.dart`、`restaurant_detail_page.dart` 僅由 T5 修改。所有並行單元寫入路徑完全互斥。

---

## 4. 詳細設計與具體實作步驟（TDD-First）

### 4.1 T1：Domain 模型、DTOs 與完整雙語 L10n

#### 4.1.1 DTO（`lib/api/dto/`）
1. `food_map_dto.dart`（`@JsonSerializable(fieldRename: FieldRename.snake)` + `Equatable`）：
   - 欄位：`title`、`description`、`ownerUid`（JSON `owner_uid`）、`ownerName`（`owner_name`）、`inviteCode`（`invite_code`）、`memberUids`（`member_uids`：`List<String>?`）、`memberNames`（`member_names`：`Map<String, String>?`）、`itemCount`（`item_count`：`int?`）、`createdAtMs`（`created_at_ms`：`int?`）、`updatedAtMs`（`updated_at_ms`：`int?`）。
   - 執行 `dart run build_runner build --delete-conflicting-outputs` 產生 `food_map_dto.g.dart`。
2. `food_map_item_dto.dart`（`@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)` + `Equatable`）：
   - 欄位：`restaurant`（`YelpRestaurantSummaryDto?`）、`addedByUid`（`added_by_uid`）、`addedByName`（`added_by_name`）、`note`、`addedAtMs`（`added_at_ms`）、`votes`（`Map<String, int>`，預設 `const <String, int>{}`，確保寫入 Firestore 時永不為 `null`）。
   - 執行 `build_runner` 產生 `food_map_item_dto.g.dart`。
3. 於 `dto_barrel.dart` 匯出上述兩個 DTO。

#### 4.1.2 Domain Entities & Exception（`lib/domain/entities/`）
1. `food_map_vote.dart`：
   ```dart
   enum FoodMapVote {
     up(1),
     down(-1),
     none(0);

     final int rawValue;
     const FoodMapVote(this.rawValue);

     static FoodMapVote fromRaw(int? raw) => switch (raw) {
       1 => FoodMapVote.up,
       -1 => FoodMapVote.down,
       _ => FoodMapVote.none,
     };
   }
   ```
2. `food_map_exception.dart`（移除未使用的 `unauthenticated`，新增 `itemNotFound` 與 `unknown`；訪客／未登入寫入一律依 AC-2 拋出 `StateError`）：
   ```dart
   enum FoodMapErrorCode {
     invalidInput,
     invalidInviteCode,
     mapNotFound,
     itemNotFound,
     permissionDenied,
     inviteCodeGenerationFailed,
     unknown,
   }

   class FoodMapException implements Exception {
     final FoodMapErrorCode code;
     final String? debugMessage;

     const FoodMapException(this.code, [this.debugMessage]);

     @override
     String toString() =>
         'FoodMapException(${code.name}${debugMessage == null ? '' : ': $debugMessage'})';
   }
   ```
3. `food_map_entity.dart`（`Equatable`）：
   - 常數：`maxTitleLength = 40`、`maxDescriptionLength = 120`、`inviteCodeLength = 8`。
   - 欄位：`id`、`title`、`description`、`ownerUid`、`ownerName`、`inviteCode`、`memberUids`（不可變清單）、`memberNames`（不可變 Map）、`itemCount`（夾限 `>= 0`）、`createdAtMs`、`updatedAtMs`。
   - `factory FoodMapEntity.fromDto(FoodMapDto dto, {required String docId})`：確保 `ownerUid` 若非空必包含於 `memberUids`，正規化空白字元與負值 `itemCount`。
   - Helper：`isOwner(String uid)`、`memberCount`、`memberDisplayName(String uid)`、`copyWith(...)`。
4. `food_map_item_entity.dart`（`Equatable`）：
   - 常數：`maxNoteLength = 140`。
   - 欄位：`restaurantId`、`restaurant`（`RestaurantEntity`）、`addedByUid`、`addedByName`、`note`、`addedAtMs`、`votes`（不可變 `Map<String, int>`，僅保留值為 `1` 或 `-1` 的有效項目）。
   - `factory FoodMapItemEntity.fromDto(FoodMapItemDto dto, {required String docId})`：若 `dto.restaurant == null` 拋 `FormatException`（由 DataSource 容錯略過）；以 `docId` 保底 `restaurant.id`。
   - 衍生屬性：`upvoteCount`、`downvoteCount`、`voteOf(String uid)`、`canModify(String uid, {required String mapOwnerUid})`、`withVote(String uid, FoodMapVote vote)`、`copyWith(...)`。
5. 於 `entities_barrel.dart` 匯出上述檔案。

#### 4.1.3 Repository Interface（`lib/domain/repositories/food_map_repository.dart`）
採 Dart 3 `abstract interface class` 與具名 Record（Style Guide §5.4）：
```dart
abstract interface class FoodMapRepository {
  String get currentUid;

  Future<List<FoodMapEntity>> fetchMyFoodMaps();

  Future<({FoodMapEntity map, List<FoodMapItemEntity> items})> fetchFoodMapDetail(
    String mapId,
  );

  Future<FoodMapEntity> createFoodMap({
    required String title,
    String description = '',
  });

  Future<({FoodMapEntity map, bool alreadyMember})> joinFoodMapByInviteCode(
    String rawCode,
  );

  Future<void> deleteFoodMap(String mapId);

  Future<void> leaveFoodMap(String mapId);

  Future<({bool added, FoodMapItemEntity item})> addRestaurant({
    required String mapId,
    required RestaurantEntity restaurant,
    String note = '',
  });

  Future<({int addedCount, int skippedCount})> importRestaurants({
    required String mapId,
    required List<RestaurantEntity> restaurants,
  });

  Future<void> removeRestaurant({
    required String mapId,
    required String restaurantId,
  });

  Future<FoodMapItemEntity> updateItemNote({
    required String mapId,
    required String restaurantId,
    required String note,
  });

  Future<void> setVote({
    required String mapId,
    required String restaurantId,
    required FoodMapVote vote,
  });
}
```
於 `repositories_barrel.dart` 匯出。

#### 4.1.4 多國語系完整鍵值契約（`lib/l10n/intl_zh_TW.arb` & `intl_en.arb`）
T1 一次補齊以下所有鍵值並執行 `dart run intl_utils:generate`，T4 與 T5 嚴格使用本表鍵名（不另外修改 `.arb`）：

| Key | `zh_TW` | `en` |
| :--- | :--- | :--- |
| `food_maps_title` | `美食地圖` | `Food Maps` |
| `food_maps_empty_title` | `還沒有共編美食地圖` | `No collaborative food maps yet` |
| `food_maps_empty_subtitle` | `建立自己的主題美食地圖，或輸入好友邀請碼一起共編` | `Create a themed food map or enter a friend's invite code to collaborate` |
| `food_maps_create_action` | `建立地圖` | `Create Map` |
| `food_maps_join_action` | `輸入邀請碼` | `Join with Code` |
| `food_maps_create_dialog_title` | `建立共編美食地圖` | `Create Collaborative Map` |
| `food_maps_name_label` | `地圖名稱` | `Map Name` |
| `food_maps_name_hint` | `例如：台北深夜拉麵地圖` | `e.g. Late Night Ramen Spots` |
| `food_maps_description_label` | `簡介（選填）` | `Description (optional)` |
| `food_maps_description_hint` | `簡單描述這張美食地圖的主題` | `Briefly describe this food map` |
| `food_maps_join_dialog_title` | `加入共編地圖` | `Join Food Map` |
| `food_maps_invite_code_label` | `8 碼邀請碼` | `8-Character Invite Code` |
| `food_maps_invite_code_hint` | `請輸入好友分享的邀請碼` | `Enter invite code from a friend` |
| `food_maps_copy_code_tooltip` | `複製邀請碼` | `Copy Invite Code` |
| `food_maps_code_copied` | `已複製邀請碼：{code}` | `Invite code copied: {code}` |
| `food_maps_owner_badge` | `建立者` | `Owner` |
| `food_maps_member_count` | `{count} 位成員` | `{count} members` |
| `food_maps_item_count` | `{count} 間餐廳` | `{count} restaurants` |
| `food_maps_delete_map` | `刪除地圖` | `Delete Map` |
| `food_maps_delete_confirm` | `確定要刪除「{title}」嗎？地圖內的推薦與投票將一併移除且無法復原。` | `Delete "{title}"? All recommendations and votes will be permanently removed.` |
| `food_maps_leave_map` | `退出地圖` | `Leave Map` |
| `food_maps_leave_confirm` | `確定要退出「{title}」嗎？` | `Leave "{title}"?` |
| `food_maps_created_success` | `已建立地圖「{title}」` | `Created map "{title}"` |
| `food_maps_joined_success` | `已加入地圖「{title}」` | `Joined map "{title}"` |
| `food_maps_already_member` | `你已在「{title}」中` | `You are already in "{title}"` |
| `food_maps_deleted_success` | `已刪除美食地圖` | `Food map deleted` |
| `food_maps_left_success` | `已退出美食地圖` | `Left food map` |
| `food_maps_detail_empty` | `這張地圖還沒有餐廳，從餐廳詳情加入或從我的最愛匯入吧！` | `No restaurants yet. Add from restaurant details or import from favorites!` |
| `food_maps_recommended_by` | `推薦人：{name}` | `Recommended by {name}` |
| `food_maps_edit_note` | `編輯推薦短評` | `Edit Recommendation Note` |
| `food_maps_note_label` | `私房推薦短評（選填）` | `Recommendation Note (optional)` |
| `food_maps_note_hint` | `分享必點菜色或避雷提醒...` | `Share must-order dishes or tips...` |
| `food_maps_note_updated` | `已更新推薦短評` | `Recommendation note updated` |
| `food_maps_remove_restaurant` | `移除餐廳` | `Remove Restaurant` |
| `food_maps_remove_restaurant_confirm` | `確定要從地圖中移除「{name}」嗎？` | `Remove "{name}" from this map?` |
| `food_maps_restaurant_removed` | `已移除餐廳` | `Restaurant removed` |
| `food_maps_no_coordinates` | `地圖內尚無含座標的餐廳，請切換回列表檢視` | `No restaurants with coordinates yet. Switch back to list view.` |
| `food_maps_toggle_map_view` | `地圖檢視` | `Map View` |
| `food_maps_toggle_list_view` | `列表檢視` | `List View` |
| `food_maps_add_to_map_tooltip` | `加入美食地圖` | `Add to Food Map` |
| `food_maps_add_sheet_title` | `加入共編美食地圖` | `Add to Collaborative Map` |
| `food_maps_add_sheet_create_new` | `建立新地圖並加入` | `Create New Map & Add` |
| `food_maps_add_sheet_submit` | `加入所選地圖` | `Add to Selected Map` |
| `food_maps_added_success` | `已加入「{title}」` | `Added to "{title}"` |
| `food_maps_already_in_map` | `此餐廳已在「{title}」中` | `Already in "{title}"` |
| `food_maps_import_favorites_action` | `從最愛匯入` | `Import Favorites` |
| `food_maps_import_favorites_title` | `從我的最愛匯入` | `Import from Favorites` |
| `food_maps_import_favorites_empty` | `目前沒有可匯入的個人最愛餐廳` | `No favorite restaurants available to import` |
| `food_maps_import_already_added` | `已在清單中` | `Already added` |
| `food_maps_import_submit` | `匯入所選（{count}）` | `Import Selected ({count})` |
| `food_maps_import_success` | `已匯入 {added} 間餐廳` | `Imported {added} restaurants` |
| `food_maps_error_invalid_input` | `請確認欄位內容與字數限制` | `Please check your input and character limits` |
| `food_maps_error_invalid_invite_code` | `請輸入正確的 8 碼邀請碼` | `Please enter a valid 8-character invite code` |
| `food_maps_error_map_not_found` | `找不到對應的美食地圖或邀請碼` | `Food map or invite code not found` |
| `food_maps_error_item_not_found` | `該餐廳已不存在於地圖中` | `This restaurant is no longer in the map` |
| `food_maps_error_permission_denied` | `你沒有執行此操作的權限` | `You do not have permission for this action` |
| `food_maps_error_generic` | `操作失敗，請稍後再試` | `Something went wrong, please try again` |

#### 4.1.5 TDD 驗證（`test/domain/food_map_entity_test.dart`）
- 測試 `FoodMapDto` / `FoodMapItemDto` 的 `snake_case` JSON 往返與 `votes` 非 null 預設值。
- 測試 `FoodMapVote.fromRaw`、`FoodMapEntity.fromDto`（正規化、owner 自動補入 `memberUids`、負數 `itemCount` 歸零）、`FoodMapItemEntity.fromDto`（投票過濾、讚／踩計算、`voteOf`、`withVote`、`canModify` 權限判斷、缺 `restaurant` 拋 `FormatException`）。
- 驗證指令：`flutter test test/domain/food_map_entity_test.dart`

---

### 4.2 T2：Data Layer（`FoodMapDataSource`, `FoodMapRepo`）與 DI

#### 4.2.1 `lib/data_layer/datasources/food_map_data_source.dart`
- 常數：
  - `mapsCollectionName = 'food_maps'`
  - `itemsSubcollectionName = 'items'`
  - `invitesCollectionName = 'food_map_invites'`
  - `inviteAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'`（32 字元，排除 `0`/`O`/`1`/`I`）
  - `maxInviteCodeAttempts = 5`
  - `_batchLimit = 500`
  - `_importChunkSize = 400`（嚴格低於單筆 Transaction 500 寫入上限）
- 建構子注入（零單例硬耦合，亂數預設 `Random.secure()`）：
  ```dart
  FoodMapDataSource({
    FirebaseFirestore? firestore,
    String Function()? uidProvider,
    String Function()? displayNameProvider,
    int Function()? nowMsProvider,
    Random? random,
    Logger? logger,
  }) : _firestoreOverride = firestore,
       _uidProvider = uidProvider,
       _displayNameProvider = displayNameProvider,
       _nowMsProvider = nowMsProvider,
       _random = random ?? Random.secure(),
       _logger = logger ?? Logger();
  ```
  - 預設 `uidProvider`：`() => SignInManager().accountDto?.uid ?? ''`
  - 預設 `displayNameProvider`：從 `SignInManager().accountDto?.account` 擷取 `@` 前段（去除前後空白）；若為空則取 `uid` 前 6 碼，再空則回退 `'Member'`。
  - `_firestore` 採 lazy getter：`_firestoreOverride ?? FirebaseFirestore.instance`。
- 統一 Firestore 錯誤轉譯器 `_guardFirestore<T>(Future<T> Function() action, {FoodMapErrorCode notFoundCode = FoodMapErrorCode.mapNotFound})`：
  - `on FirebaseException catch (e)`:
    - `'permission-denied'` → `throw FoodMapException(FoodMapErrorCode.permissionDenied, e.message)`
    - `'not-found'` → `throw FoodMapException(notFoundCode, e.message)`
    - 其他 → `throw FoodMapException(FoodMapErrorCode.unknown, '${e.code}: ${e.message}')`
- 核心操作規格：
  1. `_requireUid()`：空字串拋 `StateError('FoodMap operation requires a signed-in user')`；含 `.` 拋 `ArgumentError`。另設 `_validateDocId(String id)`：檢查 `id.trim().isNotEmpty && !id.contains('/') && id != '.' && id != '..'`，不符拋 `FoodMapException(invalidInput)`，於所有接收 `mapId` / `restaurantId` 的讀寫方法入口呼叫，防止空路徑、斜線或 Firestore 保留 doc ID 導致 SDK 拋出穿透 `on Exception` 的 `ArgumentError`。
  2. `fetchMyFoodMaps()`：空 `uid` 回傳 `[]`；查 `food_maps` `where('member_uids', arrayContains: uid)`；逐筆容錯解析（相容 `Timestamp` / `num`），依 `updatedAtMs` 降序排列。
  3. `fetchFoodMapDetail(String mapId)`：`_requireUid()`、`_validateDocId(mapId)`；讀取 `mapDoc`（不存在拋 `mapNotFound`，非成員拋 `permissionDenied`）；讀取 `items` 子集合，逐筆容錯解析，依 `addedAtMs` 降序排列。
  4. `createFoodMap({required String title, String description = ''})`：
     - `_requireUid()`；驗證 `trimmedTitle`（`1..40` 字）與 `trimmedDesc`（`<= 120` 字），不符拋 `invalidInput`。
     - 最多 `maxInviteCodeAttempts` 次使用 `_random` 生成 8 碼邀請碼，於 `_firestore.runTransaction` 檢查 `invitesCollection.doc(code)` 不存在後，原子寫入 `food_maps/{newId}`（`owner_uid == uid`, `member_uids: [uid]`, `member_names: {uid: name}`, `item_count: 0`）與 `food_map_invites/{code}`（`map_id`, `owner_uid`）。
  5. `joinFoodMapByInviteCode(String rawCode)`：
     - `_requireUid()`；正規化 `code = rawCode.trim().toUpperCase()`，驗證 `RegExp(r'^[A-Z0-9]{8}$')`（不符拋 `invalidInviteCode`）。
     - 讀取 `food_map_invites/{code}`（不存在拋 `mapNotFound`），並校驗 `data()['map_id']` 為非空且不含 `'/'` 之 `String`（否則拋 `mapNotFound`）。
     - 於 `runTransaction` 讀取 `food_maps/{mapId}`（不存在拋 `mapNotFound`）：
       - 已是成員 → 回傳 `(map: entity, alreadyMember: true)`（不執行多餘寫入）。
       - 非成員 → 更新 `member_uids: [...existing, uid]`、`member_names.{uid}: displayName`、`updated_at_ms: now`，回傳 `(map: updatedEntity, alreadyMember: false)`。
  6. `deleteFoodMap(String mapId)`：
     - `_requireUid()`、`_validateDocId(mapId)`；讀取 `mapDoc`（不存在拋 `mapNotFound`，`owner_uid != uid` 拋 `permissionDenied`）。
     - 讀取 `items` 子集合所有文件，**以 `_batchLimit = 500` 分批 `WriteBatch.delete` 並逐批 `commit()`**。
     - **另開獨立最終 `WriteBatch`**（至多 2 筆寫入，永不超過 500 上限）刪除 `food_maps/{mapId}`，若 `inviteCode.isNotEmpty` 一併加入刪除 `food_map_invites/{inviteCode}`，再 `commit()`。
  7. `leaveFoodMap(String mapId)`：
     - `_requireUid()`、`_validateDocId(mapId)`；於 `runTransaction` 驗證 `mapDoc` 存在（`mapNotFound`）、為成員且非建立者（否則拋 `permissionDenied`），更新 `member_uids: FieldValue.arrayRemove([uid])`、`member_names.$uid: FieldValue.delete()`、`updated_at_ms: now`。
  8. `addRestaurant({required String mapId, required RestaurantEntity restaurant, String note = ''})`：
     - `_requireUid()`、`_validateDocId(mapId)`、`_validateDocId(restaurant.id ?? '')`；驗證 `note.trim().length <= 140`（不符拋 `invalidInput`）。
     - 於 `runTransaction` 讀取 `mapDoc`（檢查存在 `mapNotFound` 與成員資格 `permissionDenied`）與 `items/{restaurantId}`：
       - 已存在 → 回傳 `(added: false, item: existingEntity)`，不動 `item_count`。
       - 不存在 → 寫入 `itemRef`（強制帶 `'votes': <String, int>{}`）、更新 `mapRef`（`item_count: currentCount + 1`, `updated_at_ms: now`），回傳 `(added: true, item: newEntity)`。
  9. `importRestaurants({required String mapId, required List<RestaurantEntity> restaurants})`：
     - **第一行先呼叫 `_requireUid()` 與 `_validateDocId(mapId)`**（確保空 `uid` 即使傳空清單仍符合 AC-2 拋 `StateError`）。
     - 若輸入為空直接回傳 `(addedCount: 0, skippedCount: 0)`。
     - 依有效且不含 `'/'` 之非空 `id` 去重輸入清單（無效 ID 或輸入內重複項目計入 `skippedCount`）；若去重後為空則直接回傳 `(addedCount: 0, skippedCount: skippedCount)`。
     - 按 `_importChunkSize = 400` 分批執行 `runTransaction`，**Transaction callback 維持無外部副作用並回傳 `({int added, int skipped})`，於 Transaction 外才累加外層計數**（避免 Firestore 併發自動重試 Transaction 時重複灌水計數）；每批嚴格分兩階段：
       - **Phase 1（純讀取）**：先 `tx.get(mapRef)` 驗證存在（`mapNotFound`）與成員資格（`permissionDenied`），再對該批所有候選 `itemRef` 執行 `tx.get(itemRef)` 收集存在狀態。
       - **Phase 2（純寫入）**：僅對不存在的項目執行 `tx.set(itemRef, ...)`（帶 `'votes': <String, int>{}`），已存在者計入該次 `chunkSkipped`；僅在 `chunkAdded > 0` 時執行 `tx.update(mapRef, {'item_count': currentCount + chunkAdded, 'updated_at_ms': now})`。
  10. `removeRestaurant({required String mapId, required String restaurantId})`：
      - `_requireUid()`、`_validateDocId(mapId)`、`_validateDocId(restaurantId)`；於 `runTransaction` 讀取 `mapRef` 與 `itemRef`：
        - `!mapSnap.exists` → 拋 `mapNotFound`。
        - `!memberUids.contains(uid)` → 拋 `permissionDenied`（對齊 Rules `isFoodMapMember`）。
        - `!itemSnap.exists` → 直接返回（冪等 no-op，不動 `item_count`）。
        - `ownerUid != uid && itemAddedByUid != uid` → 拋 `permissionDenied`。
        - 執行 `tx.delete(itemRef)` 與 `tx.update(mapRef, {'item_count': max(0, currentCount - 1), 'updated_at_ms': now})`。
  11. `updateItemNote({required String mapId, required String restaurantId, required String note})`：
      - `_requireUid()`、`_validateDocId(mapId)`、`_validateDocId(restaurantId)`；驗證 `trimmedNote.length <= 140`（`invalidInput`）。
      - 於 `runTransaction` 讀取 `mapRef` 與 `itemRef`：
        - `!mapSnap.exists` → 拋 `mapNotFound`。
        - `!memberUids.contains(uid)` → 拋 `permissionDenied`。
        - `!itemSnap.exists` → 拋 `itemNotFound`。
        - `ownerUid != uid && itemAddedByUid != uid` → 拋 `permissionDenied`。
        - 執行 `tx.update(itemRef, {'note': trimmedNote})` 與 `tx.update(mapRef, {'updated_at_ms': now})`，回傳更新後 `FoodMapItemEntity`。
  12. `setVote({required String mapId, required String restaurantId, required FoodMapVote vote})`：
      - `_requireUid()`、`_validateDocId(mapId)`、`_validateDocId(restaurantId)`；經 `_guardFirestore(..., notFoundCode: FoodMapErrorCode.itemNotFound)` 對 `items/{restaurantId}` 執行單鍵原子 `update`：
        - `FoodMapVote.up` → `{'votes.$uid': 1}`
        - `FoodMapVote.down` → `{'votes.$uid': -1}`
        - `FoodMapVote.none` → `{'votes.$uid': FieldValue.delete()}`

#### 4.2.2 `lib/data_layer/repositories/food_map_repo.dart` & `injection.dart`
- `FoodMapRepo implements FoodMapRepository`：委派 `FoodMapDataSource`（建構子注入可選 `FoodMapDataSource`）。
- `lib/app/di/injection.dart` 註冊：
  - `getIt.registerLazySingleton<FoodMapDataSource>(() => FoodMapDataSource());`
  - `getIt.registerLazySingleton<FoodMapRepository>(() => FoodMapRepo(dataSource: getIt<FoodMapDataSource>()));`

#### 4.2.3 TDD 驗證（`test/data_layer/datasources/food_map_data_source_test.dart`, `food_map_repo_test.dart`, `test/di_test.dart`）
- 測試清單：
  1. 訪客／空 `uid`：`fetchMyFoodMaps` 回傳 `[]`，所有寫入（含空清單 `importRestaurants`）均拋 `StateError`。
  2. 建立地圖：寫入 `snake_case` 欄位、合法 8 碼邀請碼、同步寫入 `food_map_invites/{code}`、`owner` 在 `member_uids`、空白／超長輸入拋 `invalidInput`、撞碼自動重試。
  3. 邀請碼加入：自動 trim + 轉大寫、加入後 `member_uids`/`member_names` 更新、重複加入回傳 `alreadyMember: true`、格式錯誤拋 `invalidInviteCode`、查無拋 `mapNotFound`。
  4. 新增餐廳與防重複：寫入非 null `'votes': {}`、首次加入 `item_count + 1`、重複加入回傳 `added: false` 且 `item_count` 不變、非成員拋 `permissionDenied`。
  5. 批次最愛匯入：輸入含已存在項目、重複項目與無效 ID 時僅寫入新餐廳，`addedCount`／`skippedCount` 與 `item_count` 精確；非成員拋 `permissionDenied`。
  6. 併發／多成員投票：User A 讚、User B 踩、User A 取消讚，驗證彼此投票互不覆蓋；投票對象不存在轉譯為 `itemNotFound`。
  7. 短評編輯與移除權限：建立者可刪／改他人項目；一般成員只可刪／改自己項目；**已退出地圖的原推薦人**試圖刪／改舊項目拋 `permissionDenied`；編輯不存在項目拋 `itemNotFound`。
  8. 刪除與退出地圖：建立者刪除地圖（含超過 500 筆 item 或邀請碼文件缺漏邊界）正確清掉子集合、主文件與索引；地圖不存在拋 `mapNotFound`；一般成員刪除拋 `permissionDenied`；一般成員退出自 `member_uids`/`member_names` 移除；建立者退出拋 `permissionDenied`。
  9. 損毀文件容錯：夾雜壞文件時略過並回傳其餘正常項目。
  10. `di_test.dart`：驗證 `FoodMapDataSource` 與 `FoodMapRepository` 正確註冊為 lazy singleton。
- 驗證指令：`flutter test test/data_layer/datasources/food_map_data_source_test.dart test/data_layer/food_map_repo_test.dart test/di_test.dart`

---

### 4.3 T3：4 個 BLoC 與 `FoodMapMemberStyle`

#### 4.3.1 `lib/flow/food_maps/model/food_map_member_style.dart`
- 純值工具類（零副作用）：
  - 8 組固定高對比 `(Color color, double markerHue)` 對應表（`BitmapDescriptor.hueOrange`, `hueAzure`, `hueViolet`, `hueGreen`, `hueRose`, `hueCyan`, `hueMagenta`, `hueYellow`）。
  - `static int _stableHash(String uid)`：`uid.codeUnits.fold<int>(0, (acc, c) => (acc * 31 + c) & 0x7fffffff)`。
  - `static Color colorForUid(String uid)`、`static double markerHueForUid(String uid)`、`static String initialForName(String name)`（首字轉大寫，空字串回退 `'?'`）。

#### 4.3.2 `FoodMapsBloc`（`lib/flow/food_maps/bloc/food_maps_*.dart`）
- Events：`FetchFoodMaps`、`RefreshFoodMaps({Completer<void>? completer})`、`CreateFoodMapRequested({title, description})`、`JoinFoodMapByCodeRequested({inviteCode})`、`DeleteFoodMapRequested({mapId})`、`LeaveFoodMapRequested({mapId})`。
- Sealed State：`FoodMapsInitial`、`FoodMapsLoading`、`FoodMapsLoaded({maps, isSubmitting, feedback})`、`FoodMapsFailure({errorCode})`。
  - `feedback` 為 `sealed class FoodMapsFeedback`（`MapCreated(map)` / `MapJoined(map, alreadyMember)` / `MapDeleted` / `MapLeft` / `ActionError(errorCode)` + `nonce`），供 `BlocListener` 提示 SnackBar 或跳轉詳情頁，不破壞已載入清單。
- `RefreshFoodMaps` 的 `completer` 登記於私有 `_pendingRefreshCompleters` 並以 `try ... finally` 保證在成功、失敗、被新請求覆蓋與 `close()` 時皆完成，防止 `RefreshIndicator` 卡死；另以 `_requestVersion` 遞增序號拋棄逾期回應。
- 錯誤捕捉：`on FoodMapException catch (e)` 保留原 `e.code`；`on Exception` 記錄 `Logger` 並發送 `FoodMapErrorCode.unknown`。

#### 4.3.3 `FoodMapDetailBloc`（`lib/flow/food_maps/bloc/food_map_detail_*.dart`）
- Events：`LoadFoodMapDetail({mapId, initialMap})`、`RefreshFoodMapDetail({mapId, completer})`、`ToggleFoodMapItemVote({mapId, restaurantId, tappedVote})`、`UpdateFoodMapItemNoteRequested({mapId, restaurantId, note})`、`RemoveFoodMapItemRequested({mapId, restaurantId})`。
- Sealed State：`FoodMapDetailInitial`、`FoodMapDetailLoading({initialMap})`、`FoodMapDetailLoaded({map, items, currentUid, feedback})`、`FoodMapDetailFailure({initialMap, errorCode})`。
- 私有 `_votingRestaurantIds` 防同項目連點競態；`RefreshFoodMapDetail` 同樣以 `try ... finally` 與 `close()` 保護 `completer`；`ToggleFoodMapItemVote` 於 `await repository.setVote(...)` 成功後**一律重新讀取最新 `state`** 並套用 `item.withVote(uid, nextVote)`，避免使用者同時對兩間不同餐廳投票時後完成者覆蓋先完成者的狀態；失敗發送 `ActionError`。

#### 4.3.4 `AddToFoodMapBloc`（`lib/flow/food_maps/bloc/add_to_food_map_*.dart`）
- 比照 `NoteRestaurantSheetBloc.fromGetIt()`，建構子接受可空 `FoodMapRepository? repository`，`factory AddToFoodMapBloc.fromGetIt()` 檢查 `GetIt.I.isRegistered<FoodMapRepository>()`，未註冊時發出 `AddToFoodMapFailure(errorCode: FoodMapErrorCode.unknown)` 而不崩潰。
- Events：`LoadMapsForAdd`、`SubmitAddRestaurantToMap({mapId, restaurant, note})`、`CreateMapAndAddRestaurant({title, description, restaurant, note})`。
- `CreateMapAndAddRestaurant` 於呼叫 `createFoodMap` 前先預檢 `title.trim()`（`1..40` 字）、`description.trim()`（`<= 120` 字）、`note.trim().length <= FoodMapItemEntity.maxNoteLength` 與 `restaurant.id` 非空且不含 `'/'`，不符直接回報 `invalidInput`，避免建出孤兒空地圖後加入失敗。
- Sealed State：`AddToFoodMapInitial`、`AddToFoodMapLoading`、`AddToFoodMapReady({maps, isSubmitting, errorCode})`、`AddToFoodMapSuccess({mapTitle, alreadyExists})`、`AddToFoodMapFailure({errorCode})`。

#### 4.3.5 `ImportFavoritesBloc`（`lib/flow/food_maps/bloc/import_favorites_*.dart`）
- 比照 `NoteRestaurantSheetBloc.fromGetIt()`，建構子接受可空 `FavorRepository?` 與 `FoodMapRepository?`，`factory ImportFavoritesBloc.fromGetIt()` 檢查兩者皆 `isRegistered`，缺任一則發出 `ImportFavoritesFailure(errorCode: FoodMapErrorCode.unknown)`。
- Events：`LoadFavoritesForImport`、`SubmitImportFavorites({mapId, restaurants})`。
- Sealed State：`ImportFavoritesInitial`、`ImportFavoritesLoading`、`ImportFavoritesReady({favorites, isSubmitting, errorCode})`、`ImportFavoritesSuccess({addedCount, skippedCount})`、`ImportFavoritesFailure({errorCode})`。

#### 4.3.6 TDD 驗證
- 以 `bloc_test` + `mocktail` 編寫 5 支測試檔，涵蓋所有正常流程、空狀態、`FoodMapException`／一般 `Exception` → `unknown` 映射、投票切換／取消／防連點、重整 `Completer` 於成功／失敗／`close()` 必完成、未註冊依賴優雅降級，以及 `FoodMapMemberStyle` 跨次穩定性。
- 驗證指令：`flutter test test/flow/food_maps/food_maps_bloc_test.dart test/flow/food_maps/food_map_detail_bloc_test.dart test/flow/food_maps/add_to_food_map_bloc_test.dart test/flow/food_maps/import_favorites_bloc_test.dart test/flow/food_maps/food_map_member_style_test.dart`

---

### 4.4 T4：表現層 Pages & BottomSheets（`lib/flow/food_maps/view/`）

遵循 Style Guide：所有子區塊提取為獨立 `StatelessWidget` / `StatefulWidget` 類別（禁止 `_build*()` 輔助方法），所有 `await` 後檢查 `mounted`，全數使用 `ThemeSize` / `ThemeColor` 與 §4.1.4 定義之 `S.current.food_maps_*`。

1. **`food_maps_page.dart`**（`static const routeName = '/FoodMapsPage'`）：
   - AppBar：標題 `S.current.food_maps_title` ＋右側「輸入邀請碼加入」按鈕（`Key('food_maps_join_btn')`）。
   - FAB：「建立共編地圖」（`Key('food_maps_create_btn')`）。
   - Body：`RefreshIndicator` + `ListView.separated`（空清單顯示引導空狀態含建立與加入按鈕；載入中顯示 `LoadingWidget`；失敗顯示重試）。
   - 卡片獨立類別 `FoodMapSummaryCard`：標題、簡介、建立者標記、成員數／餐廳數晶片、邀請碼複製按鈕（`Clipboard.setData` + SnackBar）、更多選單（建立者「刪除地圖」、成員「退出地圖」，皆彈確認對話框）。
   - 點擊卡片導航至 `FoodMapDetailPage.routeName`（傳入 `FoodMapEntity`），`await` 返回後檢查 `mounted` 並觸發 `RefreshFoodMaps()`。
2. **`food_map_detail_page.dart`**（`static const routeName = '/FoodMapDetailPage'`）：
   - `didChangeDependencies` 搭配 `_isInit` 讀取 `FoodMapEntity` 參數並派發 `LoadFoodMapDetail`。
   - AppBar：地圖名稱、複製邀請碼按鈕（`Key('food_map_detail_copy_code_btn')`）、「從最愛匯入」按鈕（`Key('food_map_import_favorites_btn')`）、以及列表／地圖視圖切換按鈕（`Key('food_map_detail_toggle_view_btn')`，**僅於 `platformCapabilities().mapMode == true` 渲染**）。
   - 頂部成員橫列 `FoodMapMembersStrip`：呈現成員色標首字母徽章 `FoodMapMemberAvatar`（標示建立者）。
   - 列表模式：`RefreshIndicator` + `ListView.separated` 渲染 `FoodMapRestaurantCard`（縮圖、店名、評分、分類價位、推薦人色標與名稱、私房短評、👍／👎 投票按鈕與票數、權限內顯示編輯短評與移除按鈕）。
   - **跳轉 `RestaurantDetailPage` 契約**：點擊餐廳卡片（無論列表或地圖模式）**必須**以 `Tuple2<RestaurantEntity, dynamic>(item.restaurant, null)` 作為 `arguments` 推入 `RestaurantDetailPage.routeName`（符合 `restaurant_detail_page.dart:33-36` 強轉要求）。
   - 地圖模式：切換至 `FoodMapMapView`。
3. **`food_map_map_view.dart`**：
   - 純靜態 `static Set<Marker> buildMarkers(...)`（依 `FoodMapMemberStyle.markerHueForUid(item.addedByUid)` 決定 Marker 色相，選中項設較高 `zIndexInt`，InfoWindow 顯示店名與推薦人）。
   - 底部橫向 `PageView.builder` 呈現卡片（推薦人色標、店名、短評、👍／👎 票數），與 `GoogleMap` Marker 雙向同步，點擊卡片同樣以 `Tuple2<RestaurantEntity, dynamic>(item.restaurant, null)` 跳轉 `RestaurantDetailPage`。
   - 全無有效經緯度時顯示 `S.current.food_maps_no_coordinates` 降級提示。
4. **`add_to_food_map_sheet.dart`**：
   - `static Future<void> show(BuildContext context, {required RestaurantEntity restaurant, AddToFoodMapBloc? bloc})`。
   - 支援選填 `bloc` 注入與 `_isLocalBloc` 關閉；展示現有地圖清單、選填短評（`maxLength: 140`）、內嵌快速建圖切換區（空清單時自動展開）；成功後關閉 Sheet 並顯示對應 SnackBar（新加入 vs 已存在）。
5. **`import_favorites_sheet.dart`**：
   - `static Future<bool?> show(BuildContext context, {required String mapId, required Set<String> existingRestaurantIds, ImportFavoritesBloc? bloc})`。
   - 支援選填 `bloc` 注入與 `_isLocalBloc` 關閉；已存在餐廳顯示 `S.current.food_maps_import_already_added` 並停用勾選；多選暫存置於 `State`（`setState`），送出批次匯入後回傳 `true`。
6. **TDD 驗證**：編寫 4 支 Widget 測試檔，驗證載入／空態／建立／邀請碼加入／複製代碼／刪除／退出、詳情頁列表投票／權限按鈕／短評編輯／移除／點擊餐廳卡片傳遞 `Tuple2<RestaurantEntity, dynamic>` 跳轉 `RestaurantDetailPage`／macOS 隱藏地圖切換鈕／`FoodMapMapView.buildMarkers` 成員色相區隔、`AddToFoodMapSheet` 選地圖與新建並加入、`ImportFavoritesSheet` 防重複勾選與批次匯入。
   - 驗證指令：`flutter test test/flow/food_maps/`

---

### 4.5 T5：入口銜接與全量回歸驗證

1. **`lib/app/routes/routes_table.dart`**：
   - 註冊 `FoodMapsPage.routeName`（`BlocProvider<FoodMapsBloc>`）與 `FoodMapDetailPage.routeName`（`BlocProvider<FoodMapDetailBloc>`）。
2. **`lib/flow/main/view/drawer_widget.dart`**：
   - 新增 `required this.onFoodMaps` 參數，於「收藏店家」與「探店筆記」之間新增 `ListTile`（圖示 `Icons.edit_location_alt`、文字 `appLocalizations.food_maps_title`）。
3. **`lib/flow/main/view/main_page.dart`**：
   - 傳入 `onFoodMaps: _navigateToFoodMaps`。
   - `_navigateToFoodMaps()`：檢查 `SignInManager().isGuest || (SignInManager().accountDto?.uid?.isEmpty ?? true)`，未登入／訪客導向 `SignInPage.routeName`，否則導向 `FoodMapsPage.routeName`。
4. **`lib/flow/restaurant/view/restaurant_detail_page.dart`**：
   - AppBar `actions` 新增 `IconButton(key: const Key('add_to_food_map_action_button'), tooltip: S.current.food_maps_add_to_map_tooltip, icon: const Icon(Icons.add_location_alt_outlined, color: ThemeColor.colorffffff), onPressed: _onAddToFoodMap)`。
   - `_onAddToFoodMap()`：訪客／未登入導向 `SignInPage.routeName`；已登入則合併 `_summaryInfo` 與（若 `_bloc.state is Success`）`detailInfo` 欄位後呼叫 `AddToFoodMapSheet.show(context, restaurant: enriched)`。
5. **既有測試更新（所有操作 `SignInManager().accountDto` 之測試必於 `tearDown` 歸零）**：
   - `test/flow/main/view/drawer_widget_test.dart`：補入 `onFoodMaps` 回呼與點擊測試，更新 `ListTile` 數量斷言（行動 `7`、macOS `6`），並維持 `expect(find.byIcon(Icons.map), findsNothing)` 通過。
   - `test/flow/main/view/main_page_test.dart`：新增測試驗證點擊 Drawer「美食地圖」項目時，訪客／未登入導向 `SignInPage.routeName`、已登入導向 `FoodMapsPage.routeName`。
   - `test/flow/restaurant/restaurant_detail_page_test.dart`：新增測試驗證點擊 `add_to_food_map_action_button` 時，訪客導向 `SignInPage.routeName`、已登入彈出 `AddToFoodMapSheet`。
6. **全量驗證**：
   - `dart format --output=none --set-exit-if-changed lib test`
   - `flutter analyze .`（必須 `No issues found!`）
   - `flutter test`（全專案測試全綠）

---

## 5. 上線前手動行動項：Firebase Console Firestore Security Rules 草稿

> ⚠️ 本 repo 不包含 `firestore.rules`，部署新版本前**必須**手動將以下規則合入 Firebase Console → Firestore Database → Rules，並依下方驗證矩陣在 Rules Playground 逐項實測。

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() {
      return request.auth != null && request.auth.uid != null;
    }

    function foodMapDoc(mapId) {
      return get(/databases/$(database)/documents/food_maps/$(mapId));
    }

    function isFoodMapMember(mapId) {
      return isSignedIn()
        && request.auth.uid in foodMapDoc(mapId).data.member_uids;
    }

    function isFoodMapOwner(mapId) {
      return isSignedIn()
        && foodMapDoc(mapId).data.owner_uid == request.auth.uid;
    }

    // 邀請碼防枚舉索引：僅允許精確 get，嚴禁 list；create 以 getAfter 綁定歸屬，delete 容許文件已不存在
    match /food_map_invites/{inviteCode} {
      allow get: if isSignedIn();
      allow list: if false;
      allow create: if isSignedIn()
        && request.resource.data.keys().hasOnly(['map_id', 'owner_uid'])
        && request.resource.data.owner_uid == request.auth.uid
        && request.resource.data.map_id is string
        && getAfter(/databases/$(database)/documents/food_maps/$(request.resource.data.map_id)).data.owner_uid == request.auth.uid
        && getAfter(/databases/$(database)/documents/food_maps/$(request.resource.data.map_id)).data.invite_code == inviteCode;
      allow delete: if isSignedIn()
        && (resource == null || resource.data.owner_uid == request.auth.uid);
      allow update: if false;
    }

    // 共編美食地圖主文件
    match /food_maps/{mapId} {
      allow list: if isSignedIn()
        && request.auth.uid in resource.data.member_uids;
      allow get: if isSignedIn();
      allow create: if isSignedIn()
        && request.resource.data.keys().hasOnly([
          'title',
          'description',
          'owner_uid',
          'owner_name',
          'invite_code',
          'member_uids',
          'member_names',
          'item_count',
          'created_at_ms',
          'updated_at_ms',
        ])
        && request.resource.data.owner_uid == request.auth.uid
        && request.resource.data.owner_name is string
        && request.resource.data.title is string
        && request.resource.data.title.size() >= 1
        && request.resource.data.title.size() <= 40
        && request.resource.data.description is string
        && request.resource.data.description.size() <= 120
        && request.resource.data.invite_code is string
        && request.resource.data.invite_code.size() == 8
        && request.resource.data.member_uids == [request.auth.uid]
        && request.resource.data.member_names is map
        && request.resource.data.member_names.keys().hasOnly([request.auth.uid])
        && request.resource.data.member_names[request.auth.uid] is string
        && request.resource.data.item_count is int
        && request.resource.data.item_count == 0
        && request.resource.data.created_at_ms is int
        && request.resource.data.updated_at_ms is int;
      allow delete: if isSignedIn()
        && resource.data.owner_uid == request.auth.uid;
      allow update: if isSignedIn() && (
        // 分支 1：既有成員更新 item_count / updated_at_ms（嚴格白名單，防奪權／踢人）
        (
          request.auth.uid in resource.data.member_uids
          && request.resource.data.diff(resource.data).affectedKeys()
               .hasOnly(['item_count', 'updated_at_ms'])
          && request.resource.data.item_count is int
          && request.resource.data.item_count >= 0
          && request.resource.data.updated_at_ms is int
        )
        // 分支 2：非建立者退出自己（雙向差集 + 精確長度 -1，封死重複 UID 注入）
        || (
          request.auth.uid in resource.data.member_uids
          && resource.data.owner_uid != request.auth.uid
          && request.resource.data.diff(resource.data).affectedKeys()
               .hasOnly(['member_uids', 'member_names', 'updated_at_ms'])
          && request.resource.data.member_uids is list
          && request.resource.data.member_uids.size() == resource.data.member_uids.size() - 1
          && !(request.auth.uid in request.resource.data.member_uids)
          && resource.data.member_uids.toSet()
               .difference(request.resource.data.member_uids.toSet()) == [request.auth.uid].toSet()
          && request.resource.data.member_uids.toSet()
               .difference(resource.data.member_uids.toSet()).size() == 0
          && request.resource.data.member_names is map
          && request.resource.data.member_names.diff(resource.data.member_names).affectedKeys()
               .hasOnly([request.auth.uid])
          && !(request.auth.uid in request.resource.data.member_names)
          && request.resource.data.updated_at_ms is int
        )
        // 分支 3：非成員加入自己（雙向差集 + 精確長度 +1，封死重複 UID 注入與 DoS）
        || (
          !(request.auth.uid in resource.data.member_uids)
          && request.resource.data.diff(resource.data).affectedKeys()
               .hasOnly(['member_uids', 'member_names', 'updated_at_ms'])
          && request.resource.data.member_uids is list
          && request.resource.data.member_uids.size() == resource.data.member_uids.size() + 1
          && request.auth.uid in request.resource.data.member_uids
          && request.resource.data.member_uids.toSet()
               .difference(resource.data.member_uids.toSet()) == [request.auth.uid].toSet()
          && resource.data.member_uids.toSet()
               .difference(request.resource.data.member_uids.toSet()).size() == 0
          && request.resource.data.member_names is map
          && request.resource.data.member_names.diff(resource.data.member_names).affectedKeys()
               .hasOnly([request.auth.uid])
          && request.auth.uid in request.resource.data.member_names
          && request.resource.data.member_names[request.auth.uid] is string
          && request.resource.data.updated_at_ms is int
        )
      );

      // 地圖內餐廳項目
      match /items/{restaurantId} {
        allow read: if isFoodMapMember(mapId);
        allow create: if isFoodMapMember(mapId)
          && request.resource.data.keys().hasOnly([
            'restaurant',
            'added_by_uid',
            'added_by_name',
            'note',
            'added_at_ms',
            'votes',
          ])
          && request.resource.data.added_by_uid == request.auth.uid
          && request.resource.data.added_by_name is string
          && request.resource.data.restaurant is map
          && request.resource.data.note is string
          && request.resource.data.note.size() <= 140
          && request.resource.data.added_at_ms is int
          && request.resource.data.votes is map
          && request.resource.data.votes.size() == 0;
        allow delete: if isFoodMapMember(mapId)
          && (resource.data.added_by_uid == request.auth.uid || isFoodMapOwner(mapId));
        allow update: if isFoodMapMember(mapId) && (
          // 成員投票：僅可異動自身 votes[uid]，值限 int 1 / -1 或刪除
          (
            request.resource.data.diff(resource.data).affectedKeys().hasOnly(['votes'])
            && request.resource.data.votes is map
            && request.resource.data.votes.diff(resource.data.get('votes', {})).affectedKeys()
                 .hasOnly([request.auth.uid])
            && (
              !(request.auth.uid in request.resource.data.votes)
              || (
                request.resource.data.votes[request.auth.uid] is int
                && request.resource.data.votes[request.auth.uid] in [1, -1]
              )
            )
          )
          // 建立者或原推薦人更新推薦短評（限 140 字）
          || (
            (resource.data.added_by_uid == request.auth.uid || isFoodMapOwner(mapId))
            && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['note'])
            && request.resource.data.note is string
            && request.resource.data.note.size() <= 140
          )
        );
      }
    }
  }
}
```

### Rules Playground 負向安全驗證矩陣（上線前必測）

| 測試情境 | 預期結果 |
| :--- | :---: |
| 一般成員嘗試 `update` 篡改 `owner_uid`、`invite_code` 或踢除其他成員 | ❌ DENIED |
| 非成員加入時送出 `member_uids: [myUid]` 企圖清空既有成員 | ❌ DENIED |
| 加入／退出時在 `member_uids` 重複塞入相同 UID 企圖灌水或觸發 Rules DoS | ❌ DENIED |
| 建立地圖時塞入非自身 UID 到 `member_uids`、額外未定義欄位或 `item_count: 99` | ❌ DENIED |
| 攻擊者單獨 `create` `food_map_invites/{code}` 指向他人地圖 | ❌ DENIED |
| 成員對 `items` 新增假票（建立時 `votes` 非空）或投票值為 `99`／`1.0`／修改他人 `votes[otherUid]` | ❌ DENIED |
| 已退出地圖的原推薦人嘗試刪除或更新舊餐廳短評 | ❌ DENIED |
| 建立者刪除地圖時，若對應 `food_map_invites/{code}` 已遺失 | ✅ ALLOWED（不鎖死刪除） |

---

## 6. 執行方式選項

計畫經確認並完成 STAGE 1（建立 Issue + Worktree）後，STAGE 2 支援兩種執行方式：
1. **Subagent-Driven（本對話編排，推薦）**：依 `T1 → (T2 ∥ T3) → T4 → T5` 順序派發實作與獨立 `verifier` 兩階段驗收（spec compliance → code quality），每完成任務／批次暫停展示變更與測試結果。
2. **Parallel Session**：由使用者另開獨立 session，於新建 worktree 內依本計畫逐任務執行並檢核。
