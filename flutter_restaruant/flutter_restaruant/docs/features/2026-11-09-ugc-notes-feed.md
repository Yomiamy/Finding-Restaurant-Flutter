# 功能規格：F-2.3 雙排瀑布流 UGC 食記與 15 秒探店短影片

- **日期**：2026-11-09
- **狀態**：草稿（等待 STAGE 0b 計畫與實作）
- **實查基線**：`main`
- **需求來源**：`gen-grill` 結構化 brief（Q1–Q5 五項齊備，3 輪問答收斂）
- **相關 brainstorm 項目**：[`docs/brainstorm/2026-11-02-features-brainstorm.md`](../brainstorm/2026-11-02-features-brainstorm.md) §2.2 [F-2.3] (L356-359, L608, L673)

---

## 1. 背景與問題

### 1.1 現況（實查）

1. **缺乏視覺化探店靈感瀏覽（種草體驗）**：
   - 目前 App 僅提供 Yelp 結構化餐廳列表與地圖點位（`MainPage`），使用者必須先想好關鍵字或篩選條件，無法透過隨機滑動高顏值美食圖文與短影音來「找靈感（種草）」。
2. **套件與模組現況（Q5 實查）**：
   - [`pubspec.yaml`](../../pubspec.yaml) 尚未引入 `flutter_staggered_grid_view` 與 `video_player`，但已具備 `cloud_firestore: ^6.7.1` 與 `fake_cloud_firestore: ^4.2.0`。
   - `lib/flow/` 下僅有 `ai_foodie`、`favor`、`filter`、`main`、`menu_vision`、`photo_viewer`、`restaurant`、`settings`、`signinup`、`splash`（加上 #180 的 `autocomplete`），尚無任何 UGC 食記或短影片相關頁面、BLoC、DTO 或 Entity。

### 1.2 為什麼是問題

- 餐飲探索決策高度仰賴視覺誘惑（Food Porn）。單純的餐廳列表缺乏臨場感與菜色動態展示（如拉麵湯頭沸騰、起司牽絲的 15 秒短影片）。
- 若無獨立的雙排瀑布流瀏覽入口，使用者在沒有明確目標時缺乏停留與探索的誘因。

### 1.3 【核心判斷】（Linus 模式）

**✅ 值得做。**

- **資料結構**：
  - 核心資料流向：Firestore `ugc_notes` collection（唯讀種子資料） → `UgcNoteDataSource` → `UgcNoteDto` → `UgcNoteEntity` → `UgcNoteRepository` (`UgcNoteRepo`) → `NotesFeedBloc` → `NotesFeedPage`（雙排瀑布流） → `NoteDetailPage`（多圖輪播 / 15 秒短影片播放）。
  - 在 `UgcNoteDto` / `UgcNoteEntity` 內建 `coverAspectRatio`（封面寬高比），並在 `UgcNoteEntity.fromDto` 夾限至 `[0.6, 1.5]`（預設 `0.8`）。這讓雙排瀑布流在圖片尚未下載完成前就能直接由 `AspectRatio` 算出精確高度，**徹底消滅圖片載入後的版面跳動（Layout Shift）與除以零的邊界條件**。
- **消滅特殊情況**：
  - 瀑布流列表頁**一律只渲染靜態封面圖**（若為影片則疊加右上角 `▶` 標示與秒數膠囊），不於瀑布流內自動播放影片，消滅滑動可視區域偵測、多影片搶佔硬體解碼器與記憶體暴增的複雜度。
  - 點擊卡片進入 `NoteDetailPage` 後，才依 `note.isVideo` 決定頂部媒體區為「15 秒短影片播放器（`video_player`）」或「多圖左右滑動輪播（`PageView`）」。
- **零破壞性（Never break userspace）**：
  - 入口設於 `DrawerWidget` 新增的「探店筆記」項目，點擊後以 `Navigator.pushNamed(NotesFeedPage.routeName)` 開啟獨立頁面，**完全不更動 `MainPage` 的列表／地圖切換結構與底部 `BannerAD`**。

---

## 2. 使用者故事

1. **雙排瀑布流瀏覽**：身為**正在找聚餐靈感的使用者**，我可以從側邊選單（Drawer）點選「探店筆記」進入雙排瀑布流頁面，流暢滑動高低交錯的美食圖文與短影片封面卡片，快速預覽標題、作者與餐廳名稱。
2. **多圖食記詳情**：身為**使用者**，當我點擊一篇圖文食記卡片時，可進入筆記詳情頁，左右滑動瀏覽多張高清美食照片（含頁碼指示），並閱讀完整探店心得、作者資訊與餐廳標記。
3. **15 秒探店短影片播放**：身為**使用者**，當我在瀑布流看到帶有 `▶` 與秒數標示的短影片卡片並點擊進入詳情頁時，可觀看最高 15 秒的探店短影片，並支援點擊播放／暫停切換與進度條顯示。

---

## 3. 驗收條件 (Acceptance Criteria)

- **AC-1 (相依套件)**：
  - `pubspec.yaml` 新增 `flutter_staggered_grid_view: ^0.7.0` 與官方 `video_player: ^2.14.1`（不引入非必要的第三方包裝庫 `chewie`）。
- **AC-2 (DTO / Entity / Firestore DataSource & Repository)**：
  - `UgcNoteDto` 實作 `@JsonSerializable()` 與 `Equatable`，映射 Firestore `ugc_notes` collection 欄位（`id`、`title`、`content`、`author_name`、`author_avatar_url`、`media_type`、`cover_url`、`cover_aspect_ratio`、`image_urls`、`video_url`、`video_duration_sec`、`restaurant_name`、`created_at_ms`）。
  - `UgcNoteEntity` 透過 `UgcNoteEntity.fromDto` 正規化所有欄位：`coverAspectRatio` 夾限於 `[0.6, 1.5]`（預設 `0.8`），`videoDurationSec` 夾限於 `[1, 15]`（預設 `15`），並提供 `isVideo` 布林屬性。
  - `UgcNoteDataSource` 支援建構子注入 `FirebaseFirestore? firestore`（以 lazy getter 存取 `FirebaseFirestore.instance`，確保未初始化 Firebase 的單元測試與 DI 測試不崩潰），依 `created_at_ms` 降冪讀取 `ugc_notes` documents，並兼容 `Timestamp` 與 `int` 兩種時間格式。
  - `UgcNoteRepository` / `UgcNoteRepo` 註冊至 GetIt (`setupInjection`)。
- **AC-3 (NotesFeedBloc 狀態管理)**：
  - 定義 `NotesFeedEvent`（`FetchNotesFeed`）與 `NotesFeedState`（`NotesFeedInitial`、`NotesFeedLoading`、`NotesFeedSuccess`、`NotesFeedEmpty`、`NotesFeedFailure`）。
  - 當 Firestore 回傳空列表時發出 `NotesFeedEmpty`；拋出 `Exception` 時記錄 Logger 並發出 `NotesFeedFailure`。
- **AC-4 (NotesFeedPage 雙排瀑布流 UI)**：
  - 使用 `MasonryGridView.count(crossAxisCount: 2)` 渲染雙排瀑布流卡片（`_NoteMasonryCard`）。
  - 每張卡片依 `note.coverAspectRatio` 呈現封面圖；若 `note.isVideo == true`，右上角疊加半透明膠囊顯示 `▶` 圖示與秒數（如 `0:15`）。
  - 卡片下方顯示標題（最多 2 行）、餐廳名稱（若有）與作者名稱。
  - 支援下拉重新整理（`RefreshIndicator`）與空狀態／錯誤重試狀態（`EmptyDataWidget`）。
- **AC-5 (NoteDetailPage 多圖輪播與 15 秒短影片播放)**：
  - 圖文筆記（`!note.isVideo`）：頂部以 `PageView.builder` 呈現多張圖片，底部附頁數指示（如 `1 / 3`）。
  - 短影片筆記（`note.isVideo`）：頂部以 `_NoteVideoPlayerWidget` 封裝 `VideoPlayerController`，在 `dispose()` 正確釋放資源；支援播放／暫停切換與 `VideoProgressIndicator`，若影片初始化失敗或於測試環境無原生播放器時，顯示優雅降級控制介面而不崩潰。
  - 下方顯示完整標題、作者列、餐廳地點標籤（純展示文字與圖示，不含 F-2.4 彈窗）與完整內文。
- **AC-6 (Drawer 與路由整合)**：
  - `DrawerWidget` 新增「探店筆記」項目（`Icons.StickyNote2` 或 `Icons.explore_outlined`），點擊後導航至 `NotesFeedPage.routeName`。
  - `routes_table.dart` 註冊 `NotesFeedPage.routeName` 與 `NoteDetailPage.routeName`。
- **AC-7 (靜態分析與測試覆蓋)**：
  - 涵蓋 `UgcNoteDataSource` / `UgcNoteRepo`（使用 `fake_cloud_firestore`）、`NotesFeedBloc`（`bloc_test`）、`NotesFeedPage` 與 `NoteDetailPage` Widget 測試，以及 `DrawerWidget`、`di_test` 更新。
  - `flutter analyze .` 零警告，`flutter test` 全數通過。

---

## 4. 明確排除 (Out of Scope)

- **發文與媒體上傳**：不包含相機拍攝、相簿選取圖片／影片、壓縮上傳至 Firebase Storage 或寫入 Firestore `ugc_notes`。
- **F-2.4 地點打卡 Tag 互動彈窗**：筆記上的餐廳名稱僅作靜態標籤展示，點擊不彈出預訂／導航 BottomSheet（屬 F-2.4 獨立範圍）。
- **瀑布流內自動播放影片**：瀑布流卡片僅顯示靜態封面與播放圖示，不於列表滾動時自動播放影片。
- **社群互動與審核**：不包含按讚計數寫入、留言系統、檢舉或後台內容審核工具。
- **MainPage 結構變更**：不在 `MainPage` 新增 `TabBar` 或 `BottomNavigationBar`，確保既有列表／地圖切換與底部廣告零影響。
