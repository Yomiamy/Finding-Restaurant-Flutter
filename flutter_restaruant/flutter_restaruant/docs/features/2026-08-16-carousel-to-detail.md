# 功能規格：地圖 Carousel 卡片點擊跳轉餐廳詳情

## 1. What
當使用者在地圖模式中，點擊底部的 Carousel 餐廳卡片時，能夠順利跳轉至該餐廳的詳細資訊頁面 (`RestaurantDetailPage`)。

## 2. Why
目前地圖上的 Carousel 僅提供單向與雙向的視覺連動，缺乏進一步探索餐廳詳細資訊的入口，導致地圖模式的體驗斷層。我們需要對齊首頁列表 (`RestaurantInfoListWidget`) 的跳轉行為，提供直覺的 UX。

## 3. 驗收條件
1. **觸發條件**：點擊地圖底部 Carousel 中的任一 `RestaurantItemCell`。
2. **預期行為**：
   - 觸發 Navigator 跳轉至 `RestaurantDetailPage`。
   - 傳遞對應的 `RestaurantEntity` 作為路由參數。
3. **無副作用**：不可影響既有的「滑動卡片連動地圖」與「點擊地圖 Marker 捲動卡片」功能。
