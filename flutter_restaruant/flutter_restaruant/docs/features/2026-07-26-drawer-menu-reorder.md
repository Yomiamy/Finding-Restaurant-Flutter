# 功能規格：調整側選單功能項目順序

## 1. 使用者故事 (What & Why)
目前側邊選單（Drawer）的首位項目為「設定 (Settings)」，這不符合一般使用者的操作直覺。
為了提升使用者體驗，我們需要將「搜尋」、「篩選」與「口袋名單」等高頻率使用的核心功能移至上方，並將較少使用的「設定」移至選單最底部。

## 2. 驗收條件 (Acceptance Criteria)
- [ ] 側邊選單的項目順序應調整為以下優先級：
  1. 關鍵字搜尋 (Keyword Search)
  2. 篩選條件 (Filter Rules)
  3. 切換 地圖/列表 模式 (Map/List Mode)
  4. 我的位置 (Map My Loc)
  5. 口袋名單 (Favorite)
  6. 設定 (Settings)
- [ ] 所有項目的點擊功能 (`onTap`) 必須保持原有的導航與重置邏輯不變。
- [ ] 測試驗證：開啟 Drawer 時，視覺順序符合上述要求，且點擊各項目皆能正確進入對應功能。

## 3. 範圍邊界 (Out of Scope)
- 不改變 `DrawerHeader` 的樣式與內容。
- 不新增任何新的選單項目或更改現有的圖示、文字多國語系 (i18n) 鍵值。
- 本次僅針對 `lib/flow/main/view/main_page.dart` 中 `_buildDrawer` 方法內的 `ListTile` 順序進行調整。
