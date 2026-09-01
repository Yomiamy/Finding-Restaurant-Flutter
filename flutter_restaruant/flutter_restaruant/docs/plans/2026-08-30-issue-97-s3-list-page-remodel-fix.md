# Issue #97 — 實作計畫

## 1. 架構與資料流變更 (Architecture & Data Flow)
純 UI 呈現層修改與文件同步，無架構與資料流變更。

## 2. 任務拆解 (Tasks)

### 任務 1: 消除頁面層級的硬編碼顏色
- **目標檔案**：
  - `lib/flow/main/view/main_page.dart`
  - `lib/flow/restaurant/view/restaurant_detail_page.dart`
- **實作內容**：
  - `main_page.dart`：
    - 將 `_buildAppBar` 方法增加 `BuildContext context` 參數。
    - 將 `AppBar` title 的 `TextStyle` 顏色從 `Colors.white` 改為 `ThemeColor.colorffffff`。
    - 將 `AppBar` leading Icon 的顏色改為 `ThemeColor.colorffffff`。
    - 將 `DrawerHeader` 內文字顏色改為 `ThemeColor.colorffffff`。
  - `restaurant_detail_page.dart`：
    - 將 `AppBar` title 的 `TextStyle` 顏色改為 `ThemeColor.colorffffff`。

### 任務 2: 同步修正 §S3 原始規劃文件
- **目標檔案**：
  - `docs/features/2026-08-27-remodel-page-level-views.md`
  - `docs/plans/2026-08-27-remodel-page-level-views.md`
- **實作內容**：
  - 修改 `docs/features` 內 Task 3 的描述，移除「間距與 padding 全量對齊 ThemeSize」的不實描述，改為描述 AppBar 與 Header 的硬編碼顏色修正。
  - 修改 `docs/plans` 內 Task 3 的實作細節，與上述變更對齊。

### 任務 3: 驗證與測試 (Verification)
- **實作內容**：
  - 執行 `grep` 確認無遺漏的 `Colors.white`。
  - 執行 `flutter analyze` 與 `flutter test`。
