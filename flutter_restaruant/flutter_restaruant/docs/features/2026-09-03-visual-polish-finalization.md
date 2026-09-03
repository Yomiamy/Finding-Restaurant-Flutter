# Feature: S4 視覺重塑收尾 (全專案顏色替換與組件清理)

## 1. 背景與動機 (Why)

在上一階段的 S2 (PR #102) 中，我們已經在 `ThemeColor` 中確立了集中式、編譯期安全的 `color[hex]` 常數定義。
本次 S4 的目標是徹底清償全專案的技術債：
1. 消滅所有歷史遺留的裸 `Colors.xxx`（如 `Colors.white`、`Colors.transparent`），統一收斂至單一真相來源。
2. 廢除 `appPrimary` 的向後相容別名，全面切換為規範的 `colord84a20`。
3. 清理已不再需要的 `splash_page.dart` 假性 3 秒延遲，提升啟動體驗。
4. 修正 `filter_page.dart` 未對齊 M3 元件庫的 AppBar 與按鈕顏色宣告。

## 2. 規格需求 (What)

### 2.1. 色彩常數全面替換
將以下項目透過 IDE/腳本進行全域查找並精確替換：
- **`ThemeColor.appPrimary`** → **`ThemeColor.colord84a20`** (總計約 11~12 個檔案)
- **`Colors.white`** → **`ThemeColor.colorffffff`** (預估 13 處)
- **`Colors.transparent`** → **`ThemeColor.color00000000`** (預估 2 處)
- **`Colors.black54`** → **`ThemeColor.color8a000000`** (預估 2 處)
- **`Colors.grey`** → **`ThemeColor.color9e9e9e`** (預估 1 處，位於 `banner_ad.dart`)
- **`Colors.red`** → **`ThemeColor.colorf44336`** (預估 1 處，位於 `restaurant_head_cell.dart` 愛心圖標)

*附註：替換後，若使外層 Widget 滿足 `const` 條件，應主動為其加上 `const` 修飾符號以換取效能。*

### 2.2. FilterPage 修正
修改 `lib/flow/filter/view/filter_page.dart`：
- 將 AppBar 的 `backgroundColor: ThemeColor.appPrimary`（第 60 行）與返回鈕顏色替換為新的常數。
- 將底部「套用」按鈕 (`FilledButton`) 的顏色宣告由 `theme.colorScheme.primary` 替換為 `ThemeColor.colord84a20`，並斷開對 `Theme.of(context)` 的依賴。

### 2.3. SplashPage 移除假延遲
- 移除 `lib/flow/splash/view/splash_page.dart` 內 `await Future.delayed(const Duration(seconds: 3));`，使啟動畫面於初始化完成後即刻跳轉，不再空轉等待。

## 3. 驗收條件 (Acceptance Criteria)

- [ ] 全專案搜尋不到任何 `ThemeColor.appPrimary`（包含 `theme_color.dart` 內的宣告本身也被徹底刪除）。
- [ ] 全專案 `lib/` 原始碼內不存在任何裸 `Colors.xxx` 呼叫。
- [ ] `flutter analyze` 靜態分析無警告。
- [ ] `flutter test` 單元與整合測試全綠。
- [ ] `splash_page.dart` 不再存在人為延遲，啟動流程順暢。

## 4. 範圍邊界 (Scope Boundary)

- **In-Scope**: 全專案 `.dart` 的顏色替換、`FilterPage` 顏色綁定修正、`SplashPage` 假延遲移除。
- **Out-of-Scope**: 新增未規劃的色彩定義（僅使用 PR #102 既有的 `ThemeColor.color[hex]` 常數）。
