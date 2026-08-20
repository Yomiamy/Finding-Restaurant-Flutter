# 功能規格：地圖與 BottomSheet 雙向連動 Carousel（F-1.2 補完）

- 日期：2026-08-20
- 來源：`docs/brainstorm/2026-08-18_features_brainstorm.md` F-1.2
- 狀態：待實作

## 背景：現況實查

`lib/flow/main/view/map_widget.dart` **已存在** PageView carousel 與雙向連動雛形，並非從零開始。
brainstorm 文件第 46 行「無 PageController」的敘述與程式碼實況不符，以程式碼為準。

| F-1.2 需求項 | 現況 | 缺口 |
|---|---|---|
| 全螢幕 `GoogleMap` 底層 | ✅ `Stack` 底層即 GoogleMap | — |
| 可展開之 `DraggableScrollableSheet` | ❌ 固定 `Positioned(bottom:20, height:130)` | **① 需補** |
| Marker tap → `animateToPage` 卡片 | ✅ 已實作 | — |
| Marker tap → 相機平移置中 | ❌ 只滾卡片，相機不動 | **② 需補** |
| `onPageChanged` → `animateCamera` | ✅ 已實作 | — |
| 點卡片進詳情頁 | ✅ 已實作 | — |
| `RepaintBoundary` 隔離繪製 | ❌ 無 | **③ 需補** |

## 範圍

**只補上述三項缺口**，不重寫既有連動邏輯，不新增展開後的垂直列表。

### 使用者故事

1. 身為使用者，我在地圖模式點擊某個餐廳 Marker 時，希望**地圖相機平移到該餐廳**，同時底部卡片滾動到對應項目——目前卡片會動但地圖不動，被點的 Marker 可能仍在畫面邊緣。
2. 身為使用者，我希望底部卡片區域**可以向上拖曳展開**、向下拖曳收合，而不是固定佔住畫面底部 130px。
3. 身為使用者，我在拖曳地圖時不希望因底部卡片重繪而掉幀。

### 驗收條件

- **AC-1（相機平移）**：點擊任一 Marker 後，地圖相機以動畫平移至該餐廳座標，底部 carousel 同步滾動至對應卡片，選中 Marker 變為藍色。
- **AC-2（可拖曳 Sheet）**：底部卡片容器改由 `DraggableScrollableSheet` 承載，可用手勢在收合／展開兩個 snap 尺寸間拖曳，放開後吸附至最近 snap 點。收合尺寸維持現有卡片可見高度，展開尺寸不遮蔽整個地圖。
- **AC-3（繪製隔離）**：carousel 區塊以 `RepaintBoundary` 包覆，使其重繪不觸發 Native Map View 重繪。
- **AC-4（零回歸）**：既有行為全數保留——横滑卡片仍平移地圖、點卡片仍進入詳情頁、`didUpdateWidget` 仍在列表變更時重建 Marker 並重設 `_selectedIndex`。
- **AC-5（無循環觸發）**：Marker tap 觸發的 `animateToPage` 會回呼 `onPageChanged`，該回呼內的 `animateCamera` 不得與 Marker tap 的相機平移互相打架或造成無限往返。

## 範圍邊界（Out of Scope）

- ❌ Sheet 展開時顯示完整垂直餐廳列表（收合／展開皆為同一 carousel）
- ❌ `fluster` 圖標聚類（F-1.3，獨立項目）
- ❌ 情境化探索標籤（F-1.1）
- ❌ Marker 自訂 Bitmap 圖示、星級繪製
- ❌ 列表模式（`_isListMode == true`）的任何改動

## 風險

- `PageView` 是水平捲動、`DraggableScrollableSheet` 需要垂直捲動子項才能拖曳，兩者手勢需明確分工，否則 Sheet 拖不動或 carousel 滑不動。
- AC-5 的雙向回呼互相觸發是本功能最主要的正確性風險。
