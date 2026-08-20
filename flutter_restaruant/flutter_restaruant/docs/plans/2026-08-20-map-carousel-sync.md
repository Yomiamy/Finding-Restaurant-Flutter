# 實作計畫：地圖與 BottomSheet 雙向連動 Carousel（F-1.2 補完）

- 日期：2026-08-20
- 規格：`docs/features/2026-08-20-map-carousel-sync.md`
- 影響檔案：`lib/flow/main/view/map_widget.dart`（主要）、`lib/features/foundation/style/theme_size.dart`（補常數）

## 資料結構分析

本次**不改動任何資料結構**。既有狀態已足夠：

| 欄位 | 型別 | 擁有者 | 用途 |
|---|---|---|---|
| `_validRestaurants` | `List<RestaurantEntity>` | `_MapPageState` | 有座標的餐廳，index 即 carousel 頁碼 |
| `_selectedIndex` | `int` | `_MapPageState` | 目前選中項，決定 Marker 顏色與 carousel 頁 |
| `_pageController` | `PageController` | `_MapPageState` | carousel 控制 |
| `_mapController` | `GoogleMapController?` | `_MapPageState` | 相機控制 |

`_validRestaurants` 的 index 是 Marker、carousel 頁、選中態三者的**唯一共同 key**——雙向連動不需要新增任何映射結構，這是既有設計的好處，保留它。

## 關鍵設計決策

### D-1：相機平移統一由 `onPageChanged` 負責（消除特殊情況）

規格 AC-5 的循環觸發風險，最笨也最清楚的解法是**不在 Marker `onTap` 內呼叫 `animateCamera`**。

理由：`onTap` 已呼叫 `_pageController.animateToPage(index)`，該動畫**必然**觸發 `onPageChanged(index)`，而 `onPageChanged` 內已有 `animateCamera`。因此相機平移是「免費」得到的——只要不重複呼叫，就沒有兩路相機指令打架的問題，也不需要任何 `_isProgrammaticScroll` 之類的抑制旗標。

一個特殊情況（Marker tap 要不要另外移相機）被資料流本身消滅，而非用旗標補丁。

> 邊界：`animateToPage` 到**當前頁**時不觸發 `onPageChanged`（`page_view.dart` 的 `if (currentPage != _lastReportedPage)` 守衛），所以點擊已選中的 Marker 走不到上述相機路徑。原先假設「此時相機本就已在該餐廳」是錯的——手動拖曳地圖只更新 `_centerPos`，不動 `_selectedIndex`，相機因此可能早已離開該餐廳。故 `onTap` 需在 `index == _selectedIndex` 時補一次相機平移，與 `onPageChanged` 共用 `_focusCameraOn()`。這是本設計唯一保留的條件分支：它換來「絕不重複下相機指令」，比一律呼叫再靠 `animateCamera` 自行覆蓋更明確。

### D-2：`DraggableScrollableSheet` 的手勢分工

Sheet 需要吃 `scrollController` 的可捲動子項才拖得動；內容卻是水平 `PageView`。
作法：`SingleChildScrollView(controller: sheet 的 controller)` 包住固定高度的 `PageView`。
- 垂直手勢 → `SingleChildScrollView` → Sheet 拖曳
- 水平手勢 → `PageView` 自行處理

不引入任何套件，不自訂手勢辨識器。

### D-3：snap 尺寸

以螢幕高度比例定義（`DraggableScrollableSheet` 的 API 即為比例）：
- `minChildSize` / `initialChildSize`：收合，露出一張卡片（約 `0.22`）
- `maxChildSize`：展開（約 `0.45`），不遮蔽整個地圖
- `snap: true` + `snapSizes: [min, max]`

實作時以 `ThemeSize` 常數承載卡片高度，比例值以具名常數宣告於 `_MapPageState`，不散落魔術數字。

## 任務拆分

### T1：補相機平移 + RepaintBoundary（AC-1 / AC-3 / AC-5）
- 複雜度：**機械性**（快/便宜）
- 檔案：`lib/flow/main/view/map_widget.dart`
- 內容：
  1. 確認 Marker `onTap` **不新增** `animateCamera`（依 D-1，靠 `animateToPage` 連鎖觸發既有 `onPageChanged`）。
  2. 將 carousel 區塊（`PageView.builder` 外層）包上 `RepaintBoundary`。
- 驗收：`flutter analyze` 無新增 warning；點 Marker 後相機平移且卡片同步。

### T2：`Positioned` 換成 `DraggableScrollableSheet`（AC-2 / AC-4）
- 複雜度：**標準**（多處協調：佈局、手勢、既有連動不可壞）
- 檔案：`lib/flow/main/view/map_widget.dart`、`lib/features/foundation/style/theme_size.dart`
- 內容：
  1. `theme_size.dart` 補卡片高度常數（沿用既有命名慣例 `sizeNNN`）。
  2. `Positioned(bottom:20, left:0, right:0, height:130, child: PageView...)`
     → `DraggableScrollableSheet(snap: true, snapSizes: [...], builder: (ctx, ctrl) => SingleChildScrollView(controller: ctrl, child: SizedBox(height: 卡片高, child: RepaintBoundary(child: PageView...))))`
  3. 保留 `if (_validRestaurants.isNotEmpty)` 的條件包覆。
  4. 既有 `onPageChanged`、`itemBuilder`、`GestureDetector` → 詳情頁導航**原封不動搬移**。
- 驗收：Sheet 可拖曳吸附；横滑仍平移地圖；點卡片仍進詳情頁；列表變更時 Marker 仍重建。

### T3：驗證（AC-4 / AC-5 回歸）
- 複雜度：**機械性**
- 內容：`flutter analyze`、`flutter test`（既有測試不得退步）。
- 註：本功能為互動式地圖 UI，無現成 widget test 基礎設施可低成本涵蓋 GoogleMap；以 analyze + 既有測試 + 人工驗收清單為準，不為此新建 mock GoogleMap 測試骨架。

## 破壞性分析

| 既有行為 | 風險 | 對策 |
|---|---|---|
| 横滑 carousel 平移地圖 | 低（邏輯不動） | 原封搬移 `onPageChanged` |
| 點卡片進詳情頁 | 低（邏輯不動） | 原封搬移 `GestureDetector` |
| `didUpdateWidget` 重建 Marker | 無（不觸及） | — |
| 列表模式 | 無（`_isListMode` 分支不觸及） | — |
| 底部卡片可見高度 | 中（改由比例決定，不同螢幕可能不同） | snap 比例以卡片實高換算校準 |

## 執行順序

T1 → T2 → T3（序列。同檔案寫入，無並行空間）
