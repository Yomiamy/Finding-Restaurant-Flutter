# 實作計畫：調整側選單功能項目順序

## 1. 異動檔案
- `lib/flow/main/view/main_page.dart`

## 2. 實作細節 (How)
這是一個單純的 UI 佈局調整。在 `_buildDrawer` 方法中，有一個 `ListView`，裡面包含了 `DrawerHeader` 與數個 `ListTile`。
我們需要將這些 `ListTile` 的順序重新排列如下：
1. `appLocalizations.keyword_search` (搜尋)
2. `appLocalizations.filter_rules` (篩選)
3. `appLocalizations.map_mode` / `appLocalizations.list_mode` (地圖/列表切換)
4. `appLocalizations.map_my_loc_title` (我的位置)
5. `appLocalizations.favorite_store_add` (口袋名單)
6. `appLocalizations.settings_title` (設定)

無須修改任何回呼函數（`onTap`）的內部邏輯，僅剪下貼上調整順序。

## 3. 任務拆分
- **Task 1**: 修改 `lib/flow/main/view/main_page.dart` 內的 `_buildDrawer` 方法，依據上述順序重排 `ListTile`。
- **Task 2**: 進行建置與視覺驗收，確認順序變更無誤。

## 4. 並行模式判斷
- 任務皆為單一檔案的線性修改，無需並行處理。
