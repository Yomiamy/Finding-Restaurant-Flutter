# 修復地圖底部列表 RenderFlex overflow

- **日期**：2026-08-20
- **類型**：Bug fix（既有缺陷）
- **來源**：`docs/brainstorm/2026-08-18_features_brainstorm.md` — P0「修復地圖底部列表 UI 溢出 (RenderFlex overflow)」
- **RICE**：30.0 ／ **Effort**：0.5

## What & Why

### 使用者故事

> 身為使用者，當我在**地圖模式**瀏覽底部的餐廳卡片時，我希望看到完整的評分星星與評論數，
> 而不是畫面上出現黃黑條紋的 Flutter overflow 錯誤。

### 現象

Android 地圖模式下，底部 `PageView` 的餐廳卡片出現 `RenderFlex overflowed` 黃黑條紋，
影響 UI 視覺與可用性。

### 🔴 根因（實查修正文件描述）

腦力激盪文件記載此 bug 發生在 `rating_stars.dart`。**實查後確認該檔本身無誤**，
真正的根因在**呼叫端的 flex 配置**：

`lib/component/cell/main_page/restaurant_item_cell.dart:69` 的 `Row` 內有**三個等權重
`Expanded`**（flex 各為 1），強制三等分可用寬度：

| 子項 | 實際需求 | 分到的寬度 |
| :--- | :--- | :--- |
| `RatingStars` | **固定 80px**（5 × `ThemeSize.size16`） | 1/3 |
| 評論數 `Text` | 可伸縮 | 1/3 |
| 價位 `Text` | 可伸縮 | 1/3 |

`RatingStars`（`rating_stars.dart:14`）是 `mainAxisSize.min` 的 `Row` + 5 個
固定 16px `Icon`，**寬度不可壓縮**。當分配到的寬度 < 80px 時即 overflow。

### 為何只在地圖模式發生

寬度預算實測推算（360dp Android 裝置）：

| 情境 | 卡片寬 | 扣掉圖片 110 + padding 15 + 間距 10 | 三等分後 | 是否溢出 |
| :--- | ---: | ---: | ---: | :---: |
| 地圖底部 `PageView`<br>（`viewportFraction: 0.85`, 左右各 4px padding） | ~298px | ~163px | **~54px** | 🔴 **是**（缺 26px） |
| 一般列表 / 我的最愛（全寬） | ~360px | ~225px | ~75px | ⚠️ 臨界 |

`map_widget.dart:34` 的 `viewportFraction: 0.85` 是地圖模式獨有的寬度縮減，
這就是同一個 cell 只在地圖模式炸掉的原因。

> 一般列表在小螢幕上同樣逼近臨界值 —— 修正呼叫端的 flex 配置可**一併消除**該隱患，
> 這也是為什麼修 `restaurant_item_cell.dart` 而非在 `rating_stars.dart` 加防禦。

## 驗收條件

1. Android 地圖模式底部卡片**不再出現**黃黑 overflow 條紋。
2. 評分星星**完整顯示 5 顆**，不被裁切、不縮放變形。
3. 評論數與價位文字在空間不足時以 `ellipsis` 收尾，不 overflow。
4. **不得回歸**：一般餐廳列表、我的最愛頁的同一 cell 版面維持原有視覺。
5. `flutter analyze` 維持 `No issues found!`。

## 範圍邊界（Out of Scope）

- ❌ **不改** `rating_stars.dart` —— 該檔案本身正確，固定尺寸是刻意設計。
- ❌ **不動** `map_widget.dart` 的 `viewportFraction` —— 那是地圖 UX 的刻意設計。
- ❌ **不處理**「地圖定位按鈕遮擋」P0（同屬地圖但不同檔案、不同根因）。
- ❌ **不重構** cell 的整體版面或 Design System 樣式。
