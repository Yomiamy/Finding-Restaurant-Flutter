# 功能規格：共用元件重塑 (ItemCell / RatingStars / Skeleton / EmptyDataWidget)

## 1. What & Why (是什麼與為什麼)
- **ItemCell (`RestaurantItemCell`)**: 目前的實作存在深層巢狀（`SizedBox` -> `Container` -> `Row` -> `Expanded` ...），且佈局稍顯僵硬。我們需要透過現代 Flutter 佈局原則重構，減少層級，並增進代碼可讀性。
- **RatingStars**: 目前透過 `RatingHelper` 載入多張本地靜態圖片（如 `Star_rating_4.5_of_5.png`）來顯示星星，這種作法既不靈活，也不好維護，且增加 App 體積。將改為使用 Flutter 原生的 Icon 或繪製建立 `RatingStars` Widget。
- **Skeleton**: 目前載入資料時缺乏良好的過渡動畫。我們需要加入一套 Skeleton (骨架屏) 元件，特別是針對 `ItemCell` 的載入狀態，提供 shimmer 動畫，提升 UX。
- **EmptyDataWidget**: 目前僅是在畫面中央顯示單純文字。應加入圖示 (Icon) 或更柔和的視覺設計，使其符合現代 App 標準。

## 2. 驗收條件 (Acceptance Criteria)
1. **RatingStars 元件化**：
   - 建立獨立的 `RatingStars` Widget，支援傳入評分 (double)、大小。
   - 正確顯示實星、半星與空星。
2. **ItemCell 重構**：
   - 使用新的 `RatingStars` 取代 `RatingHelper`。
   - 簡化 Widget 樹結構。
3. **Skeleton 骨架屏引入**：
   - 建立共用的 `Skeleton` 基礎 Widget。
   - 提供 `RestaurantItemSkeleton`，外觀輪廓需與 `ItemCell` 一致。
4. **EmptyDataWidget 升級**：
   - 加入佔位圖示與說明的組合，並支援傳入自訂訊息。

## 3. 範圍邊界 (Scope & Boundaries)
- **In-Scope**: 上述四個 UI 元件的重構與建立；移除冗餘的本地星星圖片資源與 `RatingHelper`。
- **Out-of-Scope**: 不涉及 API 資料結構或架構級別的改變。
