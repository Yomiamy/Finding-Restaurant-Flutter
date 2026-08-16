# 實作計畫：地圖與 BottomSheet Carousel 及 Future.wait 錯誤處理修正

## 1. 資料結構設計 (Data Structure Design)

### 1.1 Future.wait 錯誤處理 (main.dart)
不需要新增資料結構，純粹控制流重構：將基於 `.then()` 的 Promise/Future 鏈式呼叫，改寫為符合 Dart 最佳實踐的 `try-await-catch` 結構，並引入 `Logger().e` 保存並輸出 stackTrace。

### 1.2 MapWidget 與 Carousel 狀態連動 (map_widget.dart)
為達成 Map Marker 與下方卡片的雙向連動，設計以下本地狀態：
*   **`List<RestaurantEntity> _validRestaurants`**: 
    在 `didUpdateWidget` / `initState` 階段從 `_summaryInfos` 過濾出具備有效 `latitude` 與 `longitude` 的餐廳列表，作為 Map Markers 與 Carousel Pages 的唯一 Truth Source，確保兩者的 index 絕對對齊。
*   **`GoogleMapController? _mapController`**:
    於 `GoogleMap.onMapCreated` 時取得，用於呼叫 `_mapController?.animateCamera()` 來移動地圖視角。
*   **`PageController _pageController`**:
    用於控制與讀取底部 Carousel 的滑動狀態。設定 `viewportFraction` 使前後卡片能稍微露出邊緣，提升 UX。
*   **`int _selectedIndex`**:
    記錄目前被選中的餐廳 Index，用於高亮對應的 Marker（例如：改變 Hue）。可用 `ValueNotifier<int>` 或 `setState` 來更新。

## 2. 檔案異動清單 (File Change List)

*   **修改** `lib/main.dart`
    *   移除 `main()` 內的 `.then()`，改為 `try { await Future.wait(...); ... } catch (e, st) { ... }`。
    *   新增 `import 'package:logger/logger.dart';`（如果專案原本是統一使用自訂 logger，請遵循專案慣例）。
*   **修改** `lib/flow/main/view/map_widget.dart`
    *   新增 `GoogleMapController` 與 `PageController` 狀態變數。
    *   將 `GoogleMap` 包裝進 `Stack` 內，以便在底部疊加 Carousel 介面。
    *   修改 Marker 的建立邏輯，加入 `onTap` 事件來觸發 `_pageController.animateToPage()`。
*   **新增** `lib/flow/main/view/map_carousel_widget.dart` (視情況，若 UI 簡單可直接寫在 map_widget 內，但拆分符合 Clean Architecture 精神)
    *   實作橫向滾動的 `PageView.builder`。
    *   呼叫既有的卡片元件（如 `RestaurantItemCell`）呈現每一頁的內容。
    *   綁定 `onPageChanged` 事件來觸發地圖的 `animateCamera` 與 `_selectedIndex` 更新。

## 3. 任務拆分 (Task Breakdown)

請嚴格依照順序執行，確保每個任務具備獨立的驗收點。

### Task 1: 修正 `main.dart` 中的 `Future.wait` 錯誤處理
*   **動作**: 將 `lib/main.dart` 中的 `Future.wait([...]).then(...)` 重構為 `try-await-catch`。
*   **實作細節**: 
    1. 在 `try` 區塊中 `await Future.wait([...]);`。
    2. 在 `catch (e, st)` 區塊中使用 `Logger().e`（或專案約定的 log 方式）記錄錯誤及堆疊追蹤。
    3. 確保 `FcmManager().init();` 與 `runApp()` 仍能正常被執行（即使初始化失敗，或視業務邏輯決定是否顯示 Error Screen，依原邏輯為即使出錯也不能靜默卡死，至少需印出 log 後繼續執行 runApp）。
*   **驗收**: `dart format` 無錯誤，手動拋出一個例外能看到 Logger 輸出且 app 不會靜默崩潰。

### Task 2: 重構 `MapWidget` 狀態與地圖控制器
*   **動作**: 在 `MapWidget` 引入對應的 Controllers 與資料過濾邏輯。
*   **實作細節**:
    1. 宣告 `GoogleMapController? _mapController` 與 `PageController _pageController`，並在 `dispose` 中釋放 `_pageController`。
    2. 抽離過濾有效餐廳的邏輯為 `List<RestaurantEntity> _validRestaurants`，在 `initState` 與 `didUpdateWidget` 時更新。
    3. 在 `GoogleMap` 的 `onMapCreated` 回呼中綁定 `_mapController`。
*   **驗收**: 地圖正常顯示原本的 Markers，且不會有 Memory Leak。

### Task 3: 實作底部 Carousel 介面與單向連動 (Carousel -> Map)
*   **動作**: 在 `MapWidget` 底部新增 `PageView` 並實作滑動時移動地圖的功能。
*   **實作細節**:
    1. 用 `Stack` 將 `GoogleMap` 與底部的 `Positioned(bottom: 20, ...)` 佈局組合起來。
    2. 在 `Positioned` 中實作 `PageView.builder`，資料來源為 `_validRestaurants`，回傳卡片 UI。
    3. 實作 `onPageChanged: (index)`，在回呼中取得對應餐廳的座標，並透過 `_mapController?.animateCamera(CameraUpdate.newLatLng(...))` 移動視角。
*   **驗收**: 可以在底部看到卡片，左右滑動卡片時地圖視角會平滑跟隨移動。

### Task 4: 實作地圖 Marker 點擊至 Carousel 的單向連動 (Map -> Carousel) 與高亮
*   **動作**: 讓點擊 Map Marker 時能反向控制 Carousel，並高亮選取的 Marker。
*   **實作細節**:
    1. 修改 `_updateMarkers` 邏輯，為每個 Marker 加入 `onTap` 屬性。
    2. 在 `onTap` 中呼叫 `_pageController.animateToPage(index, ...)`。
    3. 加入選取狀態 (`_selectedIndex`)：被選取的 Marker 顯示藍色 (或其他顯眼顏色，如 HueBlue)，未選取的顯示預設紅色。透過 `setState` 重繪 Marker。
*   **驗收**: 點擊地圖上的 Marker，下方的卡片會自動滾動到該餐廳，且該 Marker 變換顏色以表示被選取。
