# Implementation Plan: S2 Theme Token 覆寫 (在 theme_color.dart 定義 16 進位色票常數)

## 1. 簡介與目標 (Overview)

本計畫為批次佇列中的第 1 階段。目標是將全專案所需的顏色在 `lib/features/foundation/style/theme_color.dart` 中建立為靜態編譯期常數，並對齊 `color[hex]` 小寫色碼命名規範。
本計畫確立色票單一真相來源，為後續 S4 的全專案呼叫端替換建立穩固地基。

## 2. 檔案異動清單 (File Changes)

| 檔案路徑 | 異動類型 | 說明 |
| :--- | :---: | :--- |
| `lib/features/foundation/style/theme_color.dart` | 修改 | 新增定義 16 進位小寫色碼常數 (`colord84a20`, `colorfffbf7`, `colorffffff`, `color00000000`, `color9e9e9e`, `colorf44336`, `color8a000000`) |
| `test/theme_color_test.dart` | 新增 | 單元測試，確保常數之 RGB/A 數值與對應十六進位完全一致 |

## 3. 任務拆分 (Tasks Breakdown)

- **Task 1: 定義色票常數**
  - 在 `ThemeColor` 宣告 `colord84a20`、`colorfffbf7`、`colorffffff`、`color00000000`、`color9e9e9e`、`colorf44336`、`color8a000000`。
  - 暫時保留 `appPrimary = colord84a20` 或依指示直接由 Task 2 測試覆蓋（註：本階段為避免破壞既有編譯，保留 `appPrimary = colord84a20` 作為過渡，在下一批次 S4 全域替換完成後立即徹底刪除）。
- **Task 2: 建立單元測試**
  - 建立 `test/theme_color_test.dart`，驗證各常數之 Hex、alpha、RGB 屬性。
- **Task 3: 驗證與靜態分析**
  - 執行 `flutter analyze` 確保零 warning。
  - 執行 `flutter test` 確保測試全數通過。

## 4. 驗收標準 (Verification)

- `flutter analyze`：No issues found!
- `flutter test`：全數測試通過（包含新增之 `test/theme_color_test.dart`）。
