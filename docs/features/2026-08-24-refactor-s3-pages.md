# Feature: S3 頁面改造 (詳情頁 / 登入頁 / 列表頁)

## 1. 使用者故事 (User Story)
作為開發者與設計師，我希望專案中核心頁面（餐廳詳情頁、登入頁、列表頁）的 UI 元件都能全面導入 Design System Token (ThemeData / ColorScheme / ThemeSize)，取代原先寫死的 `Colors.*` 與 `TextStyle` 常數。這將能確保未來在維護 UI 或導入新主題（如深色模式）時，全域元件具備最高的一致性，且不需要逐頁修改。

## 2. 驗收條件 (Acceptance Criteria)
* 登入頁 (`sign_in_page.dart`) 不得有寫死的 `Colors.*` 或字級，全面套用主題設計。
* 餐廳詳情頁 (`restaurant_detail_page.dart`) 及其所屬的 Sub-cells (`restaurant_head_cell.dart`, `restaurant_business_hour_cell.dart`, `restaurant_comment_cell.dart`, `restaurant_info_cell.dart`) 需汰換掉 `Colors.grey`, `Colors.blue`, `Colors.white` 等。
* 移除直接使用 `ThemeFontSize` 的作法，轉由 `Theme.of(context).textTheme` 取出語意化的 TextTheme。
* 確保套用後，元件不跑版，且視覺顏色與原本的設計高度一致。

## 3. 範圍邊界 (Scope)
* **In Scope**:
    * 詳情頁及其 Cell components (`lib/component/cell/restaurant_detail/` 內所有檔案)
    * 登入頁 (`lib/flow/signinup/view/sign_in_page.dart`)
    * 列表與主頁層面中被識別出帶有硬編碼的 widget (`lib/flow/main/view/` 下相關檔)
* **Out of Scope**:
    * 修改既有商業邏輯 (BLoC)。
    * S4 收尾階段的設定頁、篩選頁、圖庫頁 (將排入下一階段)。
