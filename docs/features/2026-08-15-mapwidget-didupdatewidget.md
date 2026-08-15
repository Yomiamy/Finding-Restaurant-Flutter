# 功能規格：MapWidget 實作 didUpdateWidget 使 Marker 連動列表

## 1. 使用者故事 (User Story)
作為一名 App 使用者，當我在列表模式與地圖模式之間切換，或是進行餐廳篩選與搜尋時，我希望地圖上的標記 (Marker) 能即時更新，精確反映出最新的餐廳列表，避免看到與篩選結果不符的舊標記。

## 2. 背景與問題 (What & Why)
目前 `MapWidget` (定義於 `lib/flow/main/view/map_widget.dart`) 在 `initState` 時會根據傳入的 `_summaryInfos` 建立地圖 `Marker` 的初始集合。然而，當父元件 `MainPage` 狀態更新（例如：載入更多餐廳、套用新的過濾條件、輸入關鍵字搜尋）並將新的 `_summaryInfos` 傳遞給 `MapWidget` 時，`MapWidget` 並沒有覆寫 `didUpdateWidget` 來捕捉屬性的變更。這導致地圖上的標記始終維持在第一次初始化的狀態，不會隨著使用者的操作而連動更新。

## 3. 驗收條件 (Acceptance Criteria)
1. **動態更新 Marker**：當 `MapWidget` 接收到新的 `_summaryInfos` 屬性時，應正確產生新的 `Marker` 集合並更新地圖。
2. **效能考量**：必須在 `didUpdateWidget` 中比較 `oldWidget._summaryInfos` 與 `widget._summaryInfos` 是否不同，只有在資料實際發生變動時才重新計算 `Marker`。
3. **維持使用者位置**：更新地圖標記時，不能清除或遺失使用者當前定位的 `_myLocMarker`（如果有的話）。

## 4. 範圍與邊界 (Scope & Boundaries)
* **In Scope**:
  - 於 `_MapPageState` 中新增 `didUpdateWidget` 方法。
  - 將原本位於 `initState` 的 Marker 產生邏輯抽離成一個獨立的方法（例如 `_updateMarkers`），以便在 `initState` 與 `didUpdateWidget` 中重複使用。
* **Out of Scope**:
  - `MainPage` 中關於資料抓取、篩選與狀態管理的邏輯修改（僅修改 MapWidget 內部的 UI 反應機制）。
  - 對 Google Map 的視角 (Camera) 移動行為進行變更。
