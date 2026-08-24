# Plan: S4 頁面與常數收尾實作計畫

## 階段 1: 樣式替換 (Style Replacement)
1. 針對 `settings_page.dart`, `filter_page.dart`, `favor_page.dart`, `photo_viewer.dart`：
   * 將 AppBar 等標題的 `TextStyle(color: Colors.white, fontSize: ThemeFontSize.*)` 換成 `Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.onPrimary)` 或是對應字級。
   * 將 Logout 或 Delete 的紅色按鈕 (`Colors.red`) 替換為 `Theme.of(context).colorScheme.error`。
2. 針對 `banner_ad.dart`：
   * 將背景的 `Colors.grey` 替換為 `Theme.of(context).colorScheme.outline` 或相近的次要色。
3. 針對 `view_utils.dart`：
   * 將預設字級替換為 `Theme.of(context).textTheme` 的合適級別，傳入 context 時需檢查 `const`。

## 階段 2: 移除假延遲 (Remove Fake Delay)
1. 檢查 `lib/flow/filter/` 相關的檔案，尋找 `Future.delayed` 或類似的假延遲，將其移除以提升效能與使用者體驗 (T-4 債務)。

## 階段 3: 驗證 (Validation)
1. 執行 `flutter format lib/` 與 `flutter analyze` 確保語法無誤且依賴正常。
2. 檢查 `git status` 與變更範圍，確認沒有遺漏。
3. Commit 變更至 `chore/202608/s4-finishing` 分支，並宣告 Design System UI 改造 100% 收斂完畢。
