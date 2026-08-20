# 實作計畫：修復地圖底部列表 RenderFlex overflow

- **規格**：`docs/features/2026-08-20-rating-stars-overflow.md`
- **日期**：2026-08-20
- **狀態**：已實作並合併（Issue #72 / PR #73）

## 資料結構

**無資料結構變更。** 純 UI layout 的 flex 配置修正，不動 entity、repository、bloc。

## 核心判斷

問題不在「星星太寬」，而在**用 `Expanded` 去分配一個本質上固定寬度的東西**。

`Expanded` 的語意是「搶佔剩餘空間並可被壓縮」，但 `RatingStars` 是 5 個固定 16px `Icon`
組成、`mainAxisSize.min` 的 `Row` —— 它**不可壓縮**。把不可壓縮的東西宣告成可壓縮，
就是這個 bug 的全部。

**正解：讓固定的保持固定，讓可伸縮的去吸收剩餘空間。**

```dart
// 現況（restaurant_item_cell.dart:69-99）：三個等權 Expanded 硬三等分
Row(children: [
  Expanded(child: RatingStars(...)),   // 🔴 固定 80px 卻只分到 1/3
  Expanded(child: Align(...評論數)),
  Expanded(child: Align(...價位)),
])

// 修正後：星星不參與 flex 分配，文字吸收剩餘並可 ellipsis
Row(children: [
  RatingStars(...),                     // ✅ 佔它該佔的 80px
  const SizedBox(width: ThemeSize.space5),
  Expanded(child: Text(...評論數, overflow: ellipsis, textAlign: right)),
  const SizedBox(width: ThemeSize.space5),
  Expanded(child: Text(...價位, overflow: ellipsis, textAlign: right)),
])
```

以 `textAlign: TextAlign.right` 取代 `Align(alignment: centerRight)` 包裹 ——
`Expanded` 下的 `Text` 直接用 `textAlign` 即可靠右，少一層 widget。

> 🪶 這是**刪除**特殊情況，不是新增防禦。修正後 diff 應比原本更短：
> 移除 2 個 `Expanded` + 2 個 `Align` 包裹層。
> **不需要** `FittedBox`、`SingleChildScrollView` 或任何縮放補丁 —— 那些都是在
> 錯誤的 flex 配置上疊補丁，會讓星星在小螢幕上變形。

## 任務拆分

### T1 — 修正 `restaurant_item_cell.dart` 的 flex 配置

- **複雜度**：機械性（單檔、規格完整）→ **快/便宜**
- **寫入**：`lib/component/cell/main_page/restaurant_item_cell.dart`（僅 :69–99 那個 `Row`）
- **內容**：依上方「修正後」結構調整。星星移出 `Expanded`，兩個文字改
  `Expanded` + `textAlign: TextAlign.right` + `overflow: TextOverflow.ellipsis`，
  中間以 `const SizedBox(width: ThemeSize.space5)` 分隔。
- **禁止**：不動 `rating_stars.dart`、不動 `map_widget.dart`、不改樣式常數。

### T2 — 補回歸測試

- **複雜度**：機械性 → **快/便宜**
- **寫入**：`test/component/cell/main_page/restaurant_item_cell_test.dart`（**追加** case，不改既有 case）
- **內容**：新增一個 test case，把 `RestaurantItemCell` 放進 `SizedBox(width: 298)`
  （地圖卡片實測寬度）中渲染，斷言：
  1. `expect(tester.takeException(), isNull)` —— 無 overflow exception
  2. `RatingStars` 實際寬度 == 5 × `ThemeSize.size16`（星星完整未被壓縮）
- **沿用既有慣例**：`MaterialApp` + `localizationsDelegates: [S.delegate]`（既有 case 已示範）。

> ⚠️ widget test 中 overflow 會以 exception 形式被 `takeException()` 捕獲，
> 這是驗證此 bug 的標準手法，不需要 golden test。

## 驗證方式

```bash
flutter analyze                                                   # 須 No issues found!
flutter test test/component/cell/main_page/restaurant_item_cell_test.dart   # 新舊 case 皆須過
```

**回歸檢查**：`RestaurantItemCell` 有 3 個呼叫端，皆須確認版面未跑掉 ——
`map_widget.dart:184`（本次目標）、`restaurant_info_list_widget.dart:111`（一般列表）、
`favor_page.dart:76`（我的最愛）。前述修改讓寬度需求下降，理論上只會讓後兩者更安全，
但仍須跑測試確認無 exception。

## 破壞性評估

| 風險 | 評估 |
| :--- | :--- |
| 其他頁面版面跑掉 | **低**。三等分 → 固定+彈性，星星位置不變，文字仍靠右 |
| 既有測試失敗 | **低**。既有 case 測的是 `imageErrorBuilder`，與本次改動無交集 |
| 視覺回歸 | **低**。同樣的元素、同樣的順序與對齊，僅寬度分配策略改變 |
