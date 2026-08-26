# Problem
專案中仍存在寫死的 `ThemeColor.appPrimary` 與 `ThemeColor.backBtn`，導致 M3 Design System (`ColorScheme.fromSeed`) 的顏色與 UI 實體呈現色差。此外 `SplashPage` 還有無謂的 3 秒延遲。

# Root Cause
在之前的 S1 階段定案了 Design System，但沒有一併將舊頁面（如 `FilterPage`, `Splash` 等）的硬編碼常數切換為 `Theme.of(context).colorScheme`。

# Fix
1. 移除 `SplashPage` 3 秒延遲。
2. 替換 18 處 AppBar 等 UI 元素的 `ThemeColor.appPrimary` 為 `Theme.of(context).colorScheme.primary`。
3. 替換 `ThemeColor.backBtn` 為 `Theme.of(context).colorScheme.onPrimary`。

# Out of scope
其他尚未遷移至 M3 的完整頁面重塑（S3 頁面改造保留到其他 issue）。

# Verification
1. 確認 Splash 無 3 秒等待直接進 app。
2. 確認 `flutter analyze` 通過。
