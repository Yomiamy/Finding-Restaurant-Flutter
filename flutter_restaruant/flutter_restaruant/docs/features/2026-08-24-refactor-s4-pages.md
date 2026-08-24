# Feature: S4 頁面與常數收尾 (設定頁 / 篩選頁 / 圖庫頁 / 其他)

## 1. 使用者故事 (User Story)
作為開發者與設計師，我希望移除專案中剩餘所有寫死的 `Colors.*` 及直接呼叫的 `ThemeFontSize`，讓所有的 UI 元件（包含設定頁、篩選頁、最愛頁面與其他零星元件）都全面透過 `Theme.of(context)` 的 `colorScheme` 與 `textTheme` 來獲取樣式。這能達成百分之百的 Design System 收斂，徹底解決長期存在的樣式債務。

## 2. 驗收條件 (Acceptance Criteria)
* 剩餘的頁面（設定頁、篩選頁、圖庫頁、最愛頁面）與共用模組（BannerAd、ViewUtils）不得有任何未被拔除的 `Colors.white`, `Colors.grey`, `Colors.red` 等常數。
* 不得在 UI 內直接使用 `ThemeFontSize`；應轉用 `Theme.of(context).textTheme` (如 `titleLarge`, `bodyMedium` 等)。
* **移除假延遲**: 處理 Filter 流程中過時的假延遲邏輯（T-4 債務）。
* 確保替換過程不引發 `const` 建構子的語法錯誤，修改後 `flutter analyze` 須為 `No issues found!`。

## 3. 範圍邊界 (Scope)
* **In Scope**:
    * `lib/flow/settings/view/settings_page.dart`
    * `lib/flow/filter/view/filter_page.dart` (並移除裡面的假延遲)
    * `lib/flow/favor/view/favor_page.dart`
    * `lib/flow/photo_viewer/view/photo_viewer.dart`
    * `lib/component/ad/banner_ad.dart`
    * `lib/features/utils/view_utils.dart`
* **Out of Scope**:
    * 重構 BLoC 架構以外的深層商業邏輯。
    * 其他 Phase 的新功能（如動態聚類 Marker Clustering 等）。
