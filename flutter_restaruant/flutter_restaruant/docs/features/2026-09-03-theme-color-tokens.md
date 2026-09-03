# Feature: S2 Theme Token 覆寫 (在 theme_color.dart 定義 16 進位色票常數)

## 1. 背景與動機 (Why)

在 UI 視覺重塑計畫（§6）中，既有設計原擬於 `theme_data.dart` 透過 Material 3 的 `ColorScheme.fromSeed` 與 `copyWith` 覆寫顏色。然而在實務與實查中發現：
1. `ColorScheme.fromSeed` 會透過色彩學演算法把品牌色 `#D84A20` 稀釋為暗濁的棕橘色 `#8F4B38`，產生色差。
2. 透過 `Theme.of(context)` 取得顏色會引入對 `BuildContext` 的依賴，且導致所有使用處喪失 `const` 編譯期優化。
3. 本專案已明確決策不做深色模式（見 §6.8 D-3），動態主題系統在此屬於過度工程。

因此決策直接在 `lib/features/foundation/style/theme_color.dart` 中建立編譯期靜態常數，並嚴格遵循既有的 `color` + 16 進位小寫色碼命名（如 `colorffffff`），提供直觀、零失真且支援 `const` 的色彩基礎。

## 2. 規格需求 (What)

在 `ThemeColor` 類別中新增定義以下 16 進位顏色常數：
- **`colord84a20`**：`Color(0xFFD84A20)`（品牌主橘色）
- **`colorfffbf7`**：`Color(0xFFFFFBF7)`（奶油白主背景與卡片底色，原 T-6 決策）
- **`colorffffff`**：`Color(0xFFFFFFFF)`（純白色，既有）
- **`color00000000`**：`Color(0x00000000)`（完全透明色）
- **`color9e9e9e`**：`Color(0xFF9E9E9E)`（灰色）
- **`colorf44336`**：`Color(0xFFF44336)`（紅色）
- **`color8a000000`**：`Color(0x8A000000)`（54% 半透明黑色）

依使用者明確指示：**不保留 `appPrimary` 別名**，後續將全面以 `colord84a20` 替代。

## 3. 驗收條件 (Acceptance Criteria)

- [ ] `lib/features/foundation/style/theme_color.dart` 正確導出上述 7 個 `static const Color` 常數。
- [ ] 命名格式全數吻合 `color[hex]` 小寫規格。
- [ ] 靜態分析 `flutter analyze` 維持零警告（No issues found）。
- [ ] 現有單元測試 `flutter test` 維持全綠。

## 4. 範圍邊界 (Scope Boundary)

- **In-Scope**：
  - `lib/features/foundation/style/theme_color.dart` 的常數宣告與註解更新。
  - `theme_color_test.dart` 單元測試驗證各色值精準度。
- **Out-of-Scope**：
  - 全專案 11 檔的呼叫點大規模替換（此為批次清單中第二項 S4 的職責，分開執行以確保 atomic commit 與獨立回滾安全）。
