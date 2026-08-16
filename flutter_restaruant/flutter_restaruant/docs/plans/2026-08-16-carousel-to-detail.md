# 實作計畫：地圖 Carousel 卡片點擊跳轉餐廳詳情

## 1. 資料結構與設計決策
- **跳轉機制**：沿用現有 `RestaurantInfoListWidget` 的實作方式，藉由 `GestureDetector` 包裝 `RestaurantItemCell`，並使用 `Navigator.of(context).pushNamedAndRemoveUntil`。
- **參數傳遞**：傳入 `Tuple2<RestaurantEntity, dynamic>(summaryInfo, null)`。

## 2. 檔案異動清單
- **修改**：`lib/flow/main/view/map_widget.dart`

## 3. 任務拆分 (Tasks)
### Task 1: 實作卡片點擊跳轉
1. 在 `map_widget.dart` 的 `PageView.builder` 中，找到回傳 `RestaurantItemCell` 的地方。
2. 將其包裹在 `GestureDetector` 中。
3. 在 `onTap` 實作中，取得目前的 `_validRestaurants[index]`。
4. 建構 `Tuple2` argument，並呼叫 `Navigator.of(context).pushNamedAndRemoveUntil`。
5. 執行 `dart format` 與 `dart analyze` 進行驗證。
