# 地圖與 BottomSheet Carousel 及 Future.wait 錯誤處理修正

## 1. P0 缺陷 3：Future.wait 無錯誤處理修正

### What
- **目標**：修改 `lib/main.dart` 中的 `Future.wait` 寫法，將原本使用的 `.then()` 替換為符合 Dart 規範的 `try-await-catch`。
- **使用者故事**：身為開發者，我希望 App 初始化時能正確捕捉並記錄例外錯誤，避免因未處理的非同步錯誤導致應用程式靜默崩潰或卡在白畫面。

### Why
- **原因**：目前 `main.dart` 中的 `Future.wait([Constants.init(), ...]).then(...)` 寫法未妥善處理 `catchError`。根據團隊的 Flutter/Dart Style Guide，非同步操作應「禁止使用 `.then()`」並「不吞錯：捕捉後必須記錄、顯示或 rethrow，禁止空 catch 或只留 //」。

### 驗收條件 (Acceptance Criteria)
1. 移除 `main.dart` 中的 `.then()` 鏈式呼叫。
2. 將 `main()` 方法改為標準的 `async`/`await` 與 `try-catch` 結構。
3. 如果 `Future.wait` 發生錯誤，應使用 `Logger().e` 記錄錯誤與 stackTrace（保留追蹤資訊）。

### 範圍邊界 (Scope Boundary)
- 僅修改 `lib/main.dart` 中的 `main()` 函式。不影響現有的初始化邏輯或順序。

---

## 2. P1 地圖與 BottomSheet Carousel 雙向平滑連動

### What
- **目標**：在地圖模式 (`MapWidget`) 底部加入一個可橫向滑動的 Carousel（底層可能為 `PageView` 或水平 `ListView`），展示餐廳卡片，並實作卡片與地圖標記（Marker）的雙向連動。
- **使用者故事**：身為使用者，當我切換到地圖模式時，我希望能直接在地圖下方滑動檢視餐廳卡片，且當我滑動卡片時，地圖相機會平滑移動至該餐廳位置；反之，若我點擊地圖上的某個餐廳標記，下方的卡片也能自動捲動到對應的餐廳資訊。

### Why
- **原因**：目前地圖模式只會顯示所有餐廳的 Marker，使用者必須點擊 Marker 才能看到店名，缺乏直覺的圖文瀏覽體驗。加入 BottomSheet Carousel 能有效利用畫面空間，提升探索地圖的互動性與流暢度。

### 驗收條件 (Acceptance Criteria)
1. **底部 Carousel 顯示**：
   - 於 `MapWidget` 底部浮現一排橫向捲動的餐廳卡片（重用或適配 `RestaurantItemCell` 或建立精簡版卡片）。
2. **雙向連動 (Two-way Linkage)**：
   - **Carousel -> Map**：當使用者滑動 Carousel 讓某張卡片置中（或成為 focus 狀態）時，地圖 `GoogleMapController.animateCamera` 需平滑將視角移至該餐廳座標，並可視情況將該 Marker 呈現選取狀態（例如改變 icon hue 或大小）。
   - **Map -> Carousel**：當使用者點擊地圖上的任一餐廳 Marker 時，下方的 Carousel 會自動 `animateToPage` 或捲動至對應的餐廳卡片。
3. **無縫接軌既有狀態**：
   - 使用傳入的 `_summaryInfos` 作為資料來源，過濾出具備有效座標 (`latitude`, `longitude`) 的餐廳。

### 範圍邊界 (Scope Boundary)
- 主要異動範圍在 `lib/flow/main/view/map_widget.dart`。
- 可能需要建立一個新的 Carousel 子元件（例如 `lib/flow/main/view/map_carousel_widget.dart`）。
- 由於此頁面既有架構未強制引入複雜的跨元件狀態管理，可用 `StatefulWidget` 結合 `PageController` 與 `GoogleMapController` 來控制雙向同步，或運用局部 `ValueNotifier` 減少重繪。
- 不更動其他列表模式的 UI 及後端 API 邏輯。
