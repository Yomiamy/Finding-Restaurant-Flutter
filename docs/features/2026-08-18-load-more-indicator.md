# 功能規格：列表底部載入更多指示器

- **來源**：`docs/brainstorm/2026-08-18_features_brainstorm.md` §6.6.3、§2.5 第 7 項
- **產出日期**：2026-08-18
- **RICE**：18.0（Reach 9 / Impact 1.0 / Confidence 100% / Effort 0.5）｜優先級 P1

---

## What & Why

### 使用者故事

> 作為使用者，當我把餐廳列表滑到底部觸發載入下一頁時，我希望看到明確的載入指示，
> 這樣我才知道「還有資料正在來」，而不是誤以為列表已經到底或 App 卡住了。

### 問題現況（實查於 2026-08-18）

| 層級 | 現況 | 檔案位置 |
| :--- | :--- | :--- |
| UI | 滑到底觸發 `FetchSearchInfo`，但列表尾端**完全沒有任何視覺回饋** | `restaurant_info_list_widget.dart:26-38` `itemCount: length + 2` |
| State | 只有 `InProgress`（首次載入用）與 `LoadMoreSuccess`（完成用），**缺少「載入更多進行中」的狀態** | `main_state.dart` |
| Bloc | `isLoadMore == true` 時**刻意不 emit 任何中間狀態**，直接 `await` 後 emit `LoadMoreSuccess` | `main_bloc.dart:30-41` |

**根因**：不是 UI 忘了畫，是**狀態機裡沒有可畫的狀態**。`main_bloc.dart:30` 的
`if (!isLoadMore) emit(InProgress())` 這行明確跳過了 load-more 的進行中訊號——
UI 端就算想畫也沒有依據。因此本功能的核心不是「加一個 spinner」，是**補上缺失的狀態**。

### 併發保護現況

`main_repo.dart:45-48` 已有 `_isLoading` 旗標：重入時直接回傳既有快取結果、不重複打 API。
所以**重複觸發不會造成重複請求**，本功能不需要另外做防抖；但這也代表使用者連續滑動時
會看到指示器閃現又消失，屬可接受行為。

---

## 驗收條件

1. **AC-1**：列表滑到底觸發載入下一頁時，列表**最後一列**顯示載入指示器。
2. **AC-2**：新資料回來後，指示器消失，新項目接在列表尾端。
3. **AC-3**：首次載入（尚無任何資料）仍走既有的 `RestaurantItemSkeleton` 全頁骨架屏，
   **行為不變**——不因本功能而改變首次載入的觀感。
4. **AC-4**：地圖模式（`_isListMode == false`）不受影響。
5. **AC-5**：載入失敗（`Failure`）時指示器消失，不無限轉圈。
6. **AC-6**：`flutter analyze` 維持 `No issues found!`；既有測試全綠。

---

## 範圍邊界

### 做

- 新增「載入更多進行中」狀態，並在 `main_bloc` 於 load-more 路徑 emit 它
- `RestaurantInfoListWidget` 依該狀態於列表尾端渲染指示器
- 指示器樣式沿用既有設計系統 token（`ThemeSize` / `colorScheme`），不硬編色值

### 不做（YAGNI）

- ❌ **「已無更多資料」的結束態**：Yelp API 回應目前未保留 `total`，判斷是否到底需要
  額外改 repository 契約，超出本功能範圍。另案處理。
- ❌ **下拉重新整理（pull-to-refresh）**：與本功能無關的獨立需求。
- ❌ **載入失敗的重試按鈕**：AC-5 只要求指示器消失，重試 UI 屬錯誤處理專案。
- ❌ **`RestaurantItemCell` 版面改造（§6.5.1）**：同檔案但不同關注點，另案（見清單 A-3）。
- ❌ **`ScrollController` 未 dispose 的洩漏**：實查途中發現的既有缺陷，
  雖在同一檔案，但屬既有 bug 而非本功能，於實作計畫中列為「順帶修正」由使用者決定是否納入。

---

## 已知風險

| 風險 | 等級 | 說明 |
| :--- | :---: | :--- |
| `ScrollEndNotification` 的 `atEdge` **在列表頂端也為 true** | 🟡 | `restaurant_info_list_widget.dart:28` 現況即如此，滑到頂也會觸發載入。本功能會讓這個既有行為**變得可見**（頂端也冒出指示器）。實作時應一併以 `pixels > 0` 或 `extentAfter == 0` 收斂為僅底部觸發。 |
| `LoadMoreSuccess` 的 `props` 用 list 內容比對 | 🟢 | 若兩次載入回傳完全相同的清單，BLoC 會因 `Equatable` 判定相等而不重建。既有行為，不因本功能改變。 |
