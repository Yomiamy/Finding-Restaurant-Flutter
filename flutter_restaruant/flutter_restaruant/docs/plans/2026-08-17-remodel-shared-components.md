# 實作計畫：共用元件重塑 (ItemCell / RatingStars / Skeleton / EmptyDataWidget)

## 1. 架構與資料流分析
本任務純屬 Presentation 層的重構，無需變更任何 Entity、Repository 或 BLoC 狀態模型。我們將採用獨立元件開發，將共用的 UI 切割為可重複使用的 Widget。

## 2. 任務拆分

- **Task 1: 重構 `EmptyDataWidget`**
  - **目標**: 在 `lib/component/empty_data_widget.dart` 中，加入佔位 Icon (例如 `Icons.inbox`) 並調整排版與字體，增加可選的 custom message 參數。
  - **檔案**: `lib/component/empty_data_widget.dart`

- **Task 2: 建立 `RatingStars` 元件**
  - **目標**: 建立原生的星星評分 Widget，以取代對靜態圖檔的依賴。需支援傳入 `rating` 數值並精確計算顯示實星、半星與空星。
  - **檔案**: `lib/component/rating_stars.dart` (新建)

- **Task 3: 建立 `Skeleton` 與 `RestaurantItemSkeleton`**
  - **目標**: 建立具有 shimmer 動畫的 `Skeleton` 元件。並基於此元件建立 `RestaurantItemSkeleton` 以作為列表項目載入時的佔位符，其輪廓大小需與 `RestaurantItemCell` 相仿。
  - **檔案**: `lib/component/skeleton.dart` (新建), `lib/component/cell/main_page/restaurant_item_skeleton.dart` (新建)

- **Task 4: 重構 `RestaurantItemCell`**
  - **目標**: 簡化深層巢狀結構；將 `RatingHelper` 的使用替換為新的 `RatingStars` 元件；優化代碼寫法。
  - **檔案**: `lib/component/cell/main_page/restaurant_item_cell.dart`

- **Task 5: 清理舊資源與修正引用**
  - **目標**: 移除 `lib/features/utils/rating_helper.dart`。並從 `assets/images/` 目錄及 `pubspec.yaml` 中移除 `Star_rating_*.png` 系列圖片。修復專案中所有相關檔案引用。
  - **檔案**: `lib/features/utils/rating_helper.dart` (刪除), `pubspec.yaml`, 以及相關 `images` 目錄檔案。

## 3. 測試策略
- 針對新建立的共用 Widget (`RatingStars`, `EmptyDataWidget`)，編寫 Widget Tests 驗證其渲染是否正確，尤其驗證評分帶小數 (如 4.5) 時星星顯示邏輯無誤。
