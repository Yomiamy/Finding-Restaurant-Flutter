# 功能規格：F-2.2 自訂美食地圖社群共編（Collaborative Food Maps）

- **日期**：2026-11-25
- **狀態**：草稿（等待確認後進入 STAGE 0b 實作計畫）
- **實查基線**：`main`
- **需求來源**：`gen-grill` 結構化 brief（Q1–Q5 五項齊備，3 輪問答收斂）
- **相關 brainstorm 項目**：[`docs/brainstorm/2026-11-23-features-brainstorm.md`](../brainstorm/2026-11-23-features-brainstorm.md) §2.2 [F-2.2] (L362-364, L622, L680)

---

## 1. 背景與問題

### 1.1 現況（Q5 程式碼實查）

1. **無多套口袋名單與共編機制（F-2.1 未實作）**：
   - [`lib/data_layer/datasources/favor_data_source.dart`](../../lib/data_layer/datasources/favor_data_source.dart)（L21-57）僅提供單層個人最愛集合 `favors/{uid}/items/{restaurantId}`；[`lib/flow/favor/view/favor_page.dart`](../../lib/flow/favor/view/favor_page.dart) 為單一扁平列表，無多套清單與跨使用者協作模型（[`docs/features/2026-08-18-favor-subcollection.md`](2026-08-18-favor-subcollection.md) L94-98 明確排除多套名單與 F-2.2）。
2. **無外部 Deep Link / QR / 系統分享套件**：
   - [`pubspec.yaml`](../../pubspec.yaml)（L14-93）未引入 `share_plus`、`qr_flutter`、`mobile_scanner`、`app_links` 或 `go_router`（路由採 [`lib/app/routes/routes_table.dart`](../../lib/app/routes/routes_table.dart) 的 `Navigator`）。
   - [`android/app/src/main/AndroidManifest.xml`](../../android/app/src/main/AndroidManifest.xml)（L77-98）與 [`ios/Runner/Info.plist`](../../ios/Runner/Info.plist)（L44-55）僅含 Google／Facebook 登入用 URL scheme，尚無 App Deep Link 或外部網頁落地頁。
3. **無使用者頭像與個人檔案集合**：
   - [`lib/data_layer/models/account_model.dart`](../../lib/data_layer/models/account_model.dart)（L7-12）僅存 `uid`、`account`、`type`，無 `displayName`、`avatarUrl` 與 Firestore `users/{uid}` profile 集合。
4. **平台與規則現況**：
   - 地圖能力透過 `platformCapabilities().mapMode` 控制（桌面平台為 `false`，見 [`lib/flow/main/view/drawer_widget.dart`](../../lib/flow/main/view/drawer_widget.dart) L68-77）。
   - Repo 內無 `firestore.rules`，規則由 Firebase Console 直接管理。

### 1.2 為什麼是問題

- 好友規劃聚餐、旅行或主題美食路線（如「台北拉麵口袋地圖」「週末約會名單」）時，目前只能各自維護孤立的個人最愛，無法在同一張地圖上彙整候選餐廳、交換私房推薦語並快速表決去哪家。
- 若強行等待 F-2.1 個人最愛遷移、外部網頁落地頁、App Links 與頭像系統全數到位再做 F-2.2，需求耦合過重且前置成本極高。

### 1.3 【核心判斷】（Linus 模式）

**✅ 值得做（以獨立頂層 `food_maps` 與零新依賴的最小閉環落地）。**

- **資料結構**：
  - 建立獨立頂層 Firestore 集合 `food_maps/{mapId}` 與子集合 `food_maps/{mapId}/items/{restaurantId}`，**完全不碰既有 `favors/{uid}/items`**。
  - 地圖主文件持有 `member_uids`（建立者必然在內）、`member_names`、`invite_code`、`item_count`；子集合以 `restaurantId` 為 document ID，內含完整 `YelpRestaurantSummaryDto` 結構化快照、`added_by_uid`、`added_by_name`、`note`（私房推薦短評）與 `votes: Map<String, int>`（`{ uid: 1 | -1 }`）。
- **消滅特殊情況**：
  - **建立者恆在 `member_uids`**：查詢「我的共編地圖」只需單一 `where('member_uids', arrayContains: uid)`，不須分別查詢「我建立的」與「我加入的」再於前端合併去重。
  - **子集合 Document ID = `restaurantId`**：重複加入同一餐廳在資料結構層面即不可能產生重複筆數。
  - **單一 `votes` Map 搭配點路徑更新（`votes.<uid>`）**：每位成員的投票獨立寫入自己的 key（`1` / `-1` / `FieldValue.delete()`），不同成員同時投票絕不互相覆蓋，讚數／踩數／個人投票狀態全部由單一資料來源衍生，不維護冗餘計數欄位。
  - **決定性成員色標與首字母**：依 `uid` 雜湊固定對應色票與 GoogleMap Marker 色相（`BitmapDescriptor.defaultMarkerWithHue`），並由 `account` 前綴推導顯示名稱與首字母徽章，免除 `users/{uid}` profile 集合與頭像上傳。
  - **桌面降級統一走既有 `platformCapabilities().mapMode`**：非行動平台僅顯示列表視圖、不掛載 `GoogleMap`，無跨平台崩潰風險。
- **零破壞性（Never break userspace）**：
  - 既有 `FavorDataSource`、`FavorPage`、`MainPage` 搜尋與廣告完全不受影響。
  - `pubspec.yaml` **零新增第三方套件**（邀請碼複製使用內建 `Clipboard.setData`，地圖複用既有 `google_maps_flutter`，最愛匯入複用既有 `FavorRepository.fetchFavorInfos()`）。

---

## 2. 使用者故事

1. **建立與分享共編美食地圖**：身為**已登入使用者**，我能從側邊選單進入「美食地圖」，建立新地圖（名稱與選填簡介），並一鍵複製系統生成的 8 碼邀請碼傳給好友。
2. **透過邀請碼加入共編**：身為**收到邀請碼的好友**，我能在「美食地圖」頁輸入邀請碼加入該地圖，立即看到地圖內所有餐廳、成員標記、投票與推薦短評，並參與共編。
3. **從餐廳詳情頁一鍵加入地圖**：身為**正在瀏覽餐廳詳情的使用者**，我能點擊 AppBar 的「加入美食地圖」按鈕，選擇一個（或現場新建一個）共編地圖並附上私房推薦短評，將餐廳收錄至該地圖。
4. **從「我的最愛」批次匯入餐廳**：身為**共編地圖成員**，我能在地圖詳情頁點選「從最愛匯入」，勾選尚未收錄的個人最愛餐廳一次加入共編地圖，免去重新搜尋的繁瑣。
5. **雙視圖瀏覽、點讚／踩與推薦短評協作**：身為**共編地圖成員**，我能在列表與地圖視圖（行動平台）間切換，依不同顏色標記辨識各成員推薦的餐廳、瀏覽私房短評、對餐廳點讚／踩投票，點擊餐廳卡片可進入完整 `RestaurantDetailPage`；建立者或該筆推薦人亦可編輯推薦短評或移除餐廳。
6. **地圖管理與訪客引導**：身為**地圖建立者**，我能刪除不再需要的地圖；身為**一般成員**，我能退出已加入的地圖；身為**訪客**，點擊共編地圖入口或詳情頁加入按鈕時會被引導至登入頁，不觸發未授權寫入。

---

## 3. 驗收條件 (Acceptance Criteria)

- **AC-1（零新依賴與既有功能零破壞）**：
  - `pubspec.yaml` 不新增任何第三方相依套件。
  - 既有 `FavorDataSource`、`FavorPage` 與 `favors/{uid}/items` 結構及相關測試完全不受破壞。
- **AC-2（資料模型、Firestore 結構與 Repository 契約）**：
  - 定義 `FoodMapEntity`、`FoodMapItemEntity`、`FoodMapVote`（`up` / `down` / `none`）與對應 `@JsonSerializable` DTO（`FoodMapDto`、`FoodMapItemDto`，餐廳欄位複用 `YelpRestaurantSummaryDto`）。
  - 實作 `FoodMapDataSource`（支援建構子注入 `FirebaseFirestore?` 與使用者識別供應函式，採 lazy getter 取得 `FirebaseFirestore.instance`）及 `FoodMapRepository` / `FoodMapRepo`，並於 [`lib/app/di/injection.dart`](../../lib/app/di/injection.dart) 註冊 lazy singleton。
  - 邀請碼為 8 碼大寫英數（排除易混淆字元 `0`/`O`/`1`/`I`），輸入查詢時自動去除前後空白並轉大寫；建立地圖時檢查碰撞並重試。
  - 訪客防護：當前使用者 `uid` 為空時，讀取回傳空清單、寫入操作一律拋出 `StateError`（與 `FavorDataSource` 一致）。
- **AC-3（美食地圖清單頁 `FoodMapsPage` & `FoodMapsBloc`）**：
  - [`DrawerWidget`](../../lib/flow/main/view/drawer_widget.dart) 新增「美食地圖」項目；[`MainPage`](../../lib/flow/main/view/main_page.dart) 點擊時，若 `SignInManager().isGuest` 或未登入則導向 `SignInPage.routeName`，已登入則導向 `FoodMapsPage.routeName`。
  - `FoodMapsPage` 透過 `FoodMapsBloc`（採 `sealed class` 狀態機）載入目前使用者建立或加入的所有共編地圖，顯示標題、簡介、成員數、餐廳數、邀請碼複製按鈕與建立者標記。
  - 支援下拉重整（`RefreshIndicator`）、建立新地圖（名稱必填 1–40 字、簡介選填 0–120 字）、輸入邀請碼加入地圖（格式無效或查無代碼顯示明確錯誤；已是成員時直接提示並可開啟）。
  - 支援建立者刪除地圖（二次確認對話框，連同清理子集合 `items`）、非建立者退出地圖（二次確認對話框，自 `member_uids` 與 `member_names` 移除自己）。
- **AC-4（共編地圖詳情頁 `FoodMapDetailPage` & `FoodMapDetailBloc`）**：
  - AppBar 顯示地圖名稱、複製邀請碼按鈕（寫入剪貼簿並顯示 SnackBar），以及列表／地圖切換按鈕（僅於 `platformCapabilities().mapMode == true` 顯示）。
  - 頂部顯示成員色標首字母清單（標示建立者）與「從最愛匯入」動作入口。
  - **列表視圖**：支援下拉重整；每張卡片顯示餐廳縮圖／名稱／星級評分／分類與價位、推薦人色標首字母與名稱、私房推薦短評、👍 讚與 👎 踩投票按鈕（含票數與個人選中狀態，再點同一按鈕取消投票）；點擊卡片導航至 `RestaurantDetailPage`。
  - **地圖視圖**（`platformCapabilities().mapMode == true`）：以 `GoogleMap` 渲染具備有效經緯度的地圖餐廳，Marker 色相依 `addedByUid` 決定性分配（不同成員呈現區隔色標），InfoWindow 顯示店名與推薦人；點擊 Marker 與底部橫向 `PageView` 卡片雙向聯動，卡片呈現在地圖上的餐廳摘要、推薦人徽章、短評與票數，點擊跳轉 `RestaurantDetailPage`。
  - 權限操作：地圖建立者可移除任一餐廳及編輯短評；一般成員僅可編輯／移除自己加入的餐廳（`addedByUid == currentUid`）；所有成員皆可點讚／踩投票。
- **AC-5（雙餐廳加入入口）**：
  - **入口 A — `RestaurantDetailPage`**：AppBar 新增「加入美食地圖」按鈕；訪客點擊導向 `SignInPage`；已登入使用者點擊彈出 `AddToFoodMapSheet`（由獨立 BLoC 管理，提供可選 `bloc` 注入參數利於測試），列出所屬地圖（空清單時支援直接新建地圖），選定地圖並可填寫選填推薦短評（0–140 字）後加入。若該餐廳已存在所選地圖中，不產生重複文件並以友善提示告知使用者。
  - **入口 B — `FoodMapDetailPage`「從我的最愛匯入」**：彈出 `ImportFavoritesSheet`（由獨立 BLoC 讀取 `FavorRepository.fetchFavorInfos()`），已存在於本地圖的餐廳自動標示為「已在清單中」且不可重複勾選；確認後批次寫入所選餐廳並更新地圖詳情與 `item_count`。
- **AC-6（寫入原子性與資料一致性）**：
  - 投票操作以 Firestore 單鍵更新（`votes.<uid>` 設值或 `FieldValue.delete()`）執行，成員 A 與成員 B 併發投票互不覆蓋。
  - 新增／移除／批次匯入餐廳時正確維護 `item_count`（不因重複加入膨脹，不低於 `0`）。
  - 資料讀取對單筆損毀文件採容錯略過並以 `Logger` 記錄警告（比照 `UgcNoteDataSource`），不因單筆壞資料癱瘓整張地圖。
- **AC-7（多語系、路由、靜態分析與測試）**：
  - 補齊 `lib/l10n/intl_zh_TW.arb` 與 `lib/l10n/intl_en.arb` 所有新增文案並重新產生 `lib/generated/`。
  - [`lib/app/routes/routes_table.dart`](../../lib/app/routes/routes_table.dart) 註冊 `FoodMapsPage.routeName` 與 `FoodMapDetailPage.routeName`。
  - 單元測試覆蓋 `FoodMapDataSource` / `FoodMapRepo`（`fake_cloud_firestore`）、新增 BLoC（`bloc_test`）、主要頁面與 BottomSheet Widget 測試，以及 `DrawerWidget`、`RestaurantDetailPage`、`di_test` 回歸更新。
  - `flutter analyze .` 零警告，`flutter test` 全數通過。

---

## 4. 明確排除 (Out of Scope)

- ❌ **F-2.1 多套個人口袋名單與 `favors` 遷移**：不動既有 `favors/{uid}/items` 與 `FavorPage`。
- ❌ **公開地圖探索廣場與訪客唯讀瀏覽**：僅限登入使用者瀏覽與協作自己建立或以邀請碼加入的地圖。
- ❌ **外部 URL 分享落地頁、App Deep Link 與 QR Code**：不建置 Firebase Hosting 落地頁，不設定 iOS Universal Links / Android App Links，不新增 `share_plus` / `qr_flutter` / `mobile_scanner` / `app_links`。
- ❌ **Firestore `snapshots()` 即時推送**：全流程採 pull-based + 下拉重整，與既有 `FavorDataSource`、`UgcNoteDataSource` 一致。
- ❌ **地圖頁內嵌 Yelp 關鍵字搜尋**：餐廳加入由 `RestaurantDetailPage` 與「從我的最愛匯入」雙入口承接，避免重複造搜尋介面。
- ❌ **獨立使用者個人檔案集合（`users/{uid}`）與自訂頭像上傳**：成員識別採帳號前綴名稱、首字母徽章與決定性色票／Marker 色相。
- ❌ **串式多則留言板**：每筆餐廳項目僅維護單一私房推薦短評（`note`），不做多樓層回覆留言串。

---

## 5. 需使用者手動處理（Out of Scope — Infra）

- 🔴 **Firestore Security Rules 與索引**：本 repo 不含 `firestore.rules`，部署前**必須**至 Firebase Console → Firestore Database → Rules 新增 `food_maps/{mapId}`、`food_maps/{mapId}/items/{restaurantId}` 與防枚舉邀請碼索引 `food_map_invites/{inviteCode}` 存取規則，否則所有共編地圖讀寫將回傳 `permission-denied`。
  - 規則需允許：
    1. 已登入使用者可建立 `food_maps`（`owner_uid == request.auth.uid`、`member_uids == [request.auth.uid]`、`item_count == 0` 與欄位長度限制）及對應之 `food_map_invites/{inviteCode}`（以 `getAfter` 校驗歸屬）。
    2. `food_map_invites/{inviteCode}` 僅開放精確 `get`、禁止 `list`（不可枚舉）；`food_maps` 僅開放成員 `list`，非成員僅能透過白名單更新將自身 UID 加入 `member_uids`／`member_names`（不可移除任何舊成員）。
    3. 地圖成員可讀寫 `items/{restaurantId}`（建立時強制 `votes` 為空 Map；刪除與短評更新限建立者或原推薦人；投票限成員修改自己對應的 `votes[request.auth.uid]` 且值域限 `1`／`-1`／刪除）。
    4. 刪除地圖主文件與對應 `food_map_invites/{inviteCode}` 限建立者（`resource.data.owner_uid == request.auth.uid`，且邀請碼文件已不存在時不阻擋刪除）。
  - 具體建議規則草稿與負向安全驗證矩陣將於 STAGE 0b 實作計畫提供，並建議於上線前在 Firebase Console Rules Playground 驗證。

---

## 6. 已知風險

| 風險 | 等級 | 說明與對策 |
| :--- | :---: | :--- |
| **Firestore Security Rules 未同步部署** | 🔴 | 上線後所有 `food_maps` 操作將遭遇 `permission-denied`。對策：列為上線前必做行動項，於 STAGE 0b 計畫提供可直接貼上的規則草稿與驗證清單。 |
| **邀請碼查詢的資料存取邊界** | 🟡 | Firestore 安全規則若僅允許「成員可讀」，則非成員依 `invite_code` 查詢會被擋下；若開放已登入者可查 `food_maps`，需透過高熵 8 碼（32⁸ ≈ 1.1×10¹²）避免窮舉，且未來若有更嚴格隱私需求可再改由 Cloud Function 核發加入（目前無 Cloud Functions 後端，先以高熵邀請碼 + Security Rules 約束）。 |
| **建立者刪除地圖時子集合超過單批 WriteBatch 500 筆** | 🟢 | 比照 `FavorDataSource._batchLimit = 500` 分批刪除子集合文件後再刪主文件。 |
| **部分 Yelp 餐廳缺少經緯度座標** | 🟢 | 地圖視圖比照 `MapWidget._updateValidRestaurants()` 僅渲染具備有效經緯度的項目，列表視圖仍完整顯示所有餐廳，不拋例外。 |
