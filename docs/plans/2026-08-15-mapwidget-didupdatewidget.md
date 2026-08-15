# 實作計畫：MapWidget 實作 didUpdateWidget 使 Marker 連動列表

## 1. 架構與資料結構 (Architecture & Data Structure)
本功能純粹針對既有的 Presentation 層元件 (`MapWidget`) 進行修改，不涉及 Domain 層與 Data 層。主要透過 Flutter 內建的生命週期鉤子 `didUpdateWidget` 來監聽傳入的 `_summaryInfos` 屬性變化，並藉由 `setState` 觸發重繪 (Rebuild)。

**核心修改點**：
- 將原本在 `initState` 中一次性建立 `_markers` 的邏輯，封裝獨立為 `_updateMarkers()`。
- `_updateMarkers()` 在重建地圖餐廳標記時，需同時判斷是否已存在使用者定位標記 (`_myLocMarker`)，若有則一併加回 `_markers` 集合中。
- 覆寫 `didUpdateWidget`：比對新舊 `_summaryInfos`，若不同則呼叫 `_updateMarkers()` 並使用 `setState()` 更新 UI。

## 2. 檔案異動 (File Modifications)

*   **修改檔案**：`lib/flow/main/view/map_widget.dart`
    *   **提取方法**：在 `_MapPageState` 中新增 `_updateMarkers()`。
    *   **更新 `initState`**：將原有的邏輯替換為呼叫 `_updateMarkers()`。
    *   **新增生命週期方法**：實作 `didUpdateWidget`，其內部條件式判斷 `widget._summaryInfos != oldWidget._summaryInfos`，成立時執行 `setState(() { _updateMarkers(); })`。

## 3. 任務拆分 (Task Breakdown)

此功能範疇單一，不需多工並行，將於一個 STAGE 2 的任務中完成：

*   **Task 1: 重構與實作 `didUpdateWidget` (序列執行)**
    - 將 `map_widget.dart` 中的標記生成邏輯抽離為 `_updateMarkers`。
    - 確認 `_myLocMarker` 會在重新載入餐廳清單後正確保留於 `_markers` 集合。
    - 實作 `didUpdateWidget`，加入狀態變更比對邏輯。
    - 驗證編譯無誤且程式碼符合 `dart format` 與 lint 規範。
