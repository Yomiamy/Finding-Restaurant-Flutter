# Issue #97 — 補齊 §S3 列表頁視覺重塑與修正文件落差

## 1. 背景與問題 (Problem & Root Cause)
- **問題**：§S3 (PR #91) 的規格要求重塑列表頁 (`MainPage`, `RestaurantInfoListWidget`) 與 `RestaurantDetailPage` 的視覺，但實際交付的程式碼並未修改這些頁面級別的容器，導致視覺不一致。
- **根本原因**：§S3 實作過度聚焦於細部 Cell 元件，忽略了頁面層級的外圍容器，且文件中提及的「間距與 padding 全量對齊 ThemeSize」實際上已經滿足，真正的遺漏是硬編碼的顏色。

## 2. 目標 (Goals)
1. 消除 `main_page.dart` 與 `restaurant_detail_page.dart` 中殘留的 `Colors.white` 硬編碼，統一改為 `ThemeColor.colorffffff`。
2. 確保列表頁與詳情頁的 AppBar、Drawer 等外圍組件與 §S2/§S3 已重塑的元件在視覺上保持一致。
3. 修正 §S3 原始規劃文件 (`docs/features/2026-08-27-remodel-page-level-views.md` 及對應 plan) 中關於 Task 3 的描述，使其反映真實情況，消除文件與程式碼的背離。

## 3. 範圍邊界 (Scope)
### ✅ 包含 (In Scope)
- `lib/flow/main/view/main_page.dart`
- `lib/flow/restaurant/view/restaurant_detail_page.dart`
- `docs/features/2026-08-27-remodel-page-level-views.md`
- `docs/plans/2026-08-27-remodel-page-level-views.md`

### ❌ 明確排除 (Out of Scope)
- `lib/flow/main/view/restaurant_info_list_widget.dart` (已確認無需頁面級變更)
- 退回或修改 §S3 已經完成的 Cell 元件重塑。
- platform-adaptive 元件的收斂 (屬於 Issue #96 的範圍)。
- 深色模式支援。

## 4. 驗收條件 (Acceptance Criteria)
- `main_page.dart` 和 `restaurant_detail_page.dart` 無任何 `Colors.white` 等硬編碼顏色。
- 專案 `flutter analyze` 無警告，`flutter test` 成功。
- §S3 的文件準確描述 Task 3 實際只涵蓋「附屬 Cell 樣式對齊」及「AppBar 顏色修正」，不再提及已完成的間距修改。
