# 實作計畫：列表底部載入更多指示器

- **對應規格**：`docs/features/2026-08-18-load-more-indicator.md`
- **產出日期**：2026-08-18

---

## 核心判斷（Linus 式）

**這是真問題**：`LoadMoreSuccess` state 存在、`_isLoading` 併發保護存在、
`ScrollEndNotification` 觸發存在——整條鏈路只缺**一個進行中的狀態**。
不是加功能，是補上狀態機被跳過的那一格。

**資料結構才是重點**：`main_bloc.dart:30` 那行
```dart
if (!isLoadMore) { emit(const InProgress()); }
```
是用「不發訊號」來區分兩種載入。正確做法是**兩種載入都發訊號，發不同的訊號**——
特殊情況（`if (!isLoadMore)`）就此消失，UI 端變成單純的狀態映射。

**最笨但最清楚的實作**：新增 `LoadMoreInProgress` state，帶著**當前已有的清單**。
帶清單是關鍵——UI 才能在顯示指示器的同時繼續渲染既有項目，
不需要 widget 自己緩存上一份資料。

---

## 資料結構變更

```dart
// main_state.dart 新增
class LoadMoreInProgress extends MainState {
  final List<RestaurantEntity> summaryInfos;   // 當前已載入的清單，UI 照常渲染
  const LoadMoreInProgress({required this.summaryInfos});

  @override
  List<Object> get props => summaryInfos;
}
```

`RestaurantInfoListWidget` 新增一個 `isLoadingMore` 參數（bool），
**不新增任何 class、不新增 controller、不引入套件**。

---

## 任務拆分

### T1 — 補上 `LoadMoreInProgress` 狀態並讓 bloc 發出它
- **複雜度**：快/便宜（機械性，規格完整）
- **寫入 scope**：
  - `lib/flow/main/bloc/main_state.dart`
  - `lib/flow/main/bloc/main_bloc.dart`
- **內容**：
  1. `main_state.dart` 新增 `LoadMoreInProgress`（結構如上）。
  2. `main_bloc.dart:30-33` 改為兩路都 emit：
     ```dart
     if (isLoadMore) {
       emit(LoadMoreInProgress(summaryInfos: _mainRepository.summaryInfoSet.toList()));
     } else {
       emit(const InProgress());
     }
     ```
- **驗收**：`flutter analyze` 零警告；`FetchSearchInfo` 在已有資料時先 emit
  `LoadMoreInProgress` 再 emit `LoadMoreSuccess`。

### T2 — 列表尾端渲染指示器，並收斂 `atEdge` 為僅底部
- **複雜度**：快/便宜
- **寫入 scope**：
  - `lib/flow/main/view/restaurant_info_list_widget.dart`
  - `lib/flow/main/view/main_page.dart`
- **內容**：
  1. `RestaurantInfoListWidget` 建構式新增 `required bool isLoadingMore`。
  2. `itemCount` 改為 `_summaryInfos.length + 2 + (isLoadingMore ? 1 : 0)`。
  3. `itemBuilder` 尾端補一個分支：`index == _summaryInfos.length + 2` 時回傳
     置中的 `CircularProgressIndicator`（外包 `Padding`，走 `ThemeSize` token）。
  4. **順帶修正 `atEdge` 誤觸**：`onNotification` 的條件由
     `_scrollController.position.atEdge` 改為
     `_scrollController.position.extentAfter == 0`，只在底部觸發。
     （§規格「已知風險」第 1 項；不修的話頂端也會冒指示器，是本功能引入的可見退化）
  5. `main_page.dart` 的 `builder`：
     - `state is LoadMoreInProgress` 時一併更新 `_summaryInfos`
     - 傳 `isLoadingMore: state is LoadMoreInProgress`
- **驗收**：AC-1～AC-5 全數手動驗證通過。

### T3 — 測試
- **複雜度**：快/便宜
- **寫入 scope**：`test/`（依既有 bloc test 慣例放置）
- **內容**：用 `bloc_test` 驗證
  - 首次載入：`[InProgress, Success]`
  - 已有資料再載入：`[LoadMoreInProgress, LoadMoreSuccess]`
- **驗收**：`flutter test` 全綠。

---

## 並行判定

**🔴 序列**。T1 定義 state，T2 消費 state，有資料依賴；T3 依賴 T1/T2 的最終行為。

---

## 破壞性評估

| 項目 | 等級 | 說明 |
| :--- | :---: | :--- |
| 新增 state 子類 | 🟢 | `MainState` 是 abstract class 非 sealed，新增子類不會讓既有 switch 編譯失敗 |
| `main_page.dart` builder 新增分支 | 🟢 | 純增量，既有 `Success` / `LoadMoreSuccess` 路徑不變 |
| `RestaurantInfoListWidget` 建構式新增必填參數 | 🟡 | **僅 `main_page.dart:133` 一處呼叫**（已 grep 確認），同批修改 |
| `atEdge` → `extentAfter == 0` | 🟡 | 行為變更：滑到**頂端**不再觸發載入。這是修正既有誤觸，非退化——但若有人依賴「滑到頂重新載入」，需知悉 |
| 首次載入骨架屏 | 🟢 | `InProgress` 路徑完全未動（AC-3） |

---

## 明確不做

- ❌ 「已無更多資料」結束態 — 需改 repository 契約回傳 `total`，另案
- ❌ 抽出 `LoadMoreIndicator` 獨立 widget — 只有一處使用，YAGNI；
  超過一處使用時再抽
- ❌ `shimmer` 尾端骨架 — `CircularProgressIndicator` 已足夠，
  加骨架要多一個 widget 且與首次載入的骨架屏語意重疊
- ❌ `ScrollController` 未 dispose 的洩漏 — 屬既有缺陷（`StatelessWidget` 持有
  controller），**修它要把 widget 改成 `StatefulWidget`**，diff 會大於本功能本身。
  已記錄於待辦清單，另案處理

---

## 驗證方式

- **靜態**：`flutter analyze` → `No issues found!`（不得回退）；`dart format` 通過
- **單元**：`flutter test` 全綠（含 T3 新增的兩個 bloc test）
- **手動**：模擬器實跑，滑到底確認指示器出現→消失→新項目接上；
  滑到頂確認**不**觸發載入；切地圖模式確認無異常
