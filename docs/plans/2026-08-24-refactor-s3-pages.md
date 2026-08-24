# Plan: S3 頁面改造 (詳情頁 / 登入頁 / 列表頁)

## 1. 資料結構與影響範圍
純 UI 展示層的重構。影響範圍：
- `lib/flow/signinup/view/sign_in_page.dart`
- `lib/flow/restaurant/view/restaurant_detail_page.dart`
- `lib/component/cell/restaurant_detail/restaurant_head_cell.dart`
- `lib/component/cell/restaurant_detail/restaurant_business_hour_cell.dart`
- `lib/component/cell/restaurant_detail/restaurant_comment_cell.dart`
- `lib/component/cell/restaurant_detail/restaurant_info_cell.dart`

## 2. 實作細節與對應表
將寫死的常數進行以下替換策略：
- `Colors.grey` (次要文字) -> `Theme.of(context).colorScheme.outline`
- `Colors.white` (文字/圖示) -> `Theme.of(context).colorScheme.onPrimary` 或 `Theme.of(context).colorScheme.surface` (依據背景)
- `Colors.blue` (連結或品牌動作) -> `Theme.of(context).colorScheme.primary`
- `Colors.red` (錯誤或警示) -> `Theme.of(context).colorScheme.error`
- 字級 `ThemeFontSize.fontSize14` 等 -> 使用 `Theme.of(context).textTheme.bodyMedium` 等語意化 text style。

## 3. 任務拆分
* **Task 1**: 建立獨立 Git Worktree `chore/202608/s3-refactor-pages` 並複製規劃檔。
* **Task 2**: 實作詳情頁 (Detail Page) 與其附屬的 Cell Components 的 Token 替換。
* **Task 3**: 實作登入頁 (Sign-in Page) 的 Token 替換。
* **Task 4**: 編譯驗證與 `flutter analyze` 檢查，確認 UI Token 置換無造成語法錯誤。
