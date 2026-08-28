# Implementation Plan: §S4 體驗收尾與常數清理 (篩選頁 / Splash / 常數重構)

## 任務清單 (Task Breakdown)

- [ ] **Task 1: 篩選頁體驗升級 (`FilterPage`)**
  - 將「套用」按鈕改為底部固定 `bottomNavigationBar: SafeArea(...)` 之 `FilledButton`，套用 `Theme.of(context).colorScheme.primary`
  - 價格與排序採用卡片容器包裹與間距優化，消除深層巢狀
  - `CupertinoDatePicker` 外層加入 Card 裝飾與圓角

- [ ] **Task 2: Splash 頁面優化與常數清理 (`SplashPage`, `FavorPage`, `UIConstants`)**
  - `SplashPage` 圖片 fit 由 `BoxFit.fill` 改為 `BoxFit.cover`
  - `FavorPage` AppBar 標題由 `UIConstants.favorTitle` 改為 `S.current.favorite_stores`
  - `SignInPage` 中的 `UIConstants.emptyWidget` 替換為 `const SizedBox.shrink()`
  - 移除 `UIConstants` 廢棄未引用的常數

- [ ] **Task 3: 測試與品質驗證 (Tests & Quality Assurance)**
  - 新增 `test/flow/filter/filter_page_test.dart`（驗證初始載入、選擇變更、點擊套用回傳 FilterConfigs）
  - 新增 `test/flow/splash/splash_page_test.dart`（驗證 Splash 頁面渲染與計時後路由跳轉）
  - 執行 `flutter analyze`、`flutter test` 與 `dart format lib test` 確保零警告、全綠通過
