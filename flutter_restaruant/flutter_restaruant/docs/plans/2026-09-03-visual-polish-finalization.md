# Implementation Plan: S4 視覺重塑收尾 (全專案顏色替換與組件清理)

## 1. 簡介與目標 (Overview)
本階段是批次任務的第 2 階段。基於 S2 中建立的色票系統，本次將全面掃蕩全專案，消滅對 `Theme.of(context)` 色彩的依賴以及 `Colors.xxx` 裸字串。這不僅能確保色彩精準統一（消滅 M3 造成的 `fromSeed` 色偏），更因為全域採用靜態 `const` 色票，將連帶使數十個元件的建構式獲得升級至 `const` 的效能紅利。

## 2. 檔案異動清單 (File Changes)
- **`lib/features/foundation/style/theme_color.dart`**：移除 `appPrimary` 別名。
- **全域搜尋並替換 `ThemeColor.appPrimary`**：將所有 11 處出現替換為 `ThemeColor.colord84a20`。
- **全域搜尋並替換裸 `Colors.xxx`**：
  - `lib/flow/restaurant/view/restaurant_detail_page.dart` (Colors.white)
  - `lib/flow/restaurant/view/restaurant_info_cell.dart` (Colors.black54)
  - `lib/flow/restaurant/view/restaurant_head_cell.dart` (Colors.transparent, Colors.red)
  - `lib/flow/filter/view/filter_tags_widget.dart` (Colors.white)
  - `lib/flow/signinup/view/sign_in_page.dart` (Colors.white)
  - `lib/flow/signinup/view/sign_in_header_widget.dart` (Colors.transparent, Colors.black54)
  - `lib/flow/settings/view/settings_page.dart` (Colors.white)
  - `lib/flow/settings/view/settings_account_section_widget.dart` (Colors.white)
  - `lib/flow/splash/view/splash_page.dart` (Colors.white)
  - `lib/flow/photo/view/photo_viewer.dart` (Colors.white)
  - `lib/flow/main/view/components/banner_ad.dart` (Colors.grey)
- **`lib/flow/filter/view/filter_page.dart`**：
  - 將 AppBar `ThemeColor.appPrimary` 與按鈕 `theme.colorScheme.primary` 等皆替換為 `ThemeColor.colord84a20`，將底色替換為 `ThemeColor.colorffffff`。
- **`lib/flow/splash/view/splash_page.dart`**：移除第 29 行的 `await Future.delayed(...)` 假延遲。
- **`test/theme_color_test.dart`**：移除對 `ThemeColor.appPrimary` 的斷言。

## 3. 任務拆分 (Tasks Breakdown)
- **Task 1: 移除 `appPrimary` 且執行全域字串替換**
  - 利用腳本或正則表達式，對 `lib/` 執行全域替換 `ThemeColor.appPrimary` → `ThemeColor.colord84a20`。
  - 將 `lib/` 中所有的 `Colors.white`, `Colors.transparent`, `Colors.black54`, `Colors.grey`, `Colors.red` 替換為對應的 `ThemeColor` 變數。
  - 從 `theme_color.dart` 與 `theme_color_test.dart` 徹底刪除 `appPrimary` 相關程式碼。
- **Task 2: 修理 FilterPage 與 SplashPage 邏輯**
  - 在 `filter_page.dart` 拔除舊的 Theme 動態依賴。
  - 在 `splash_page.dart` 砍掉 3 秒假延遲。
- **Task 3: Const 補強與驗證分析**
  - 運行 `flutter analyze`，若發現外層元件因抽換常數而能升級為 `const`，利用 `dart fix --apply` 補上。
  - 運行 `flutter test`，確保 SplashPage 等相關測試通過（假延遲的移除可能會影響測試，若有錯誤需一併修補測試 `tester.pump` 的秒數）。

## 4. 驗收標準 (Verification)
- `flutter analyze` 應不出現任何遺留的 `Colors.xxx` (除測試代碼外) 或未加入的 `const`。
- `flutter test` 應全數通過，無 Regression。
