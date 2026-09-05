# Implementation Plan: 自訂地圖定位懸浮按鈕與 ThemeSize 常數重構 (Custom Map Locate Button & ThemeSize Alignment)

## 1. 簡介與目標 (Overview)

本計畫旨在改善首頁地圖探索模式（`MapWidget`）的使用者體驗與程式碼品質：
1. **關閉不可控原生按鈕**：停用 Google Maps 原生定位按鈕 (`myLocationButtonEnabled: false`) 與縮放控制 (`zoomControlsEnabled: false`)，消滅原生按鈕與底部 130dp 餐廳卡片 PageView 的佈局遮擋風險。
2. **實作自訂定位按鈕 (FloatingActionButton)**：在右上角（`top: ThemeSize.space20, right: ThemeSize.space16`）掛載自訂定位小按鈕，點擊時透過既有 [`Utils.getCurrentPosition()`](file:///Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant/lib/features/utils/utils.dart#L45) 獲取裝置真實 GPS 座標，並以 `CameraUpdate.newLatLngZoom(..., 15)` 平滑平移相機。
3. **擴充與對齊 Design System (`ThemeSize`)**：在 [`ThemeSize`](file:///Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant/lib/features/foundation/style/theme_size.dart) 定義 `size130 = 130;`，並將 `MapWidget` 內所有裸數字常數全數收斂為 `ThemeSize` token。

---

## 2. 檔案異動清單 (File Changes)

- **`lib/features/foundation/style/theme_size.dart`**：
  - 於「一般尺寸 (Size)」區塊新增 `static const double size130 = 130;`。
- **`lib/flow/main/view/map_widget.dart`**：
  - 引入 `dart:async` 與 `../../../features/foundation/style/style_barrel.dart`。
  - `GoogleMap` 屬性設定 `myLocationButtonEnabled: false`、`zoomControlsEnabled: false`。
  - `Stack` 內掛載 `Positioned(top: ThemeSize.space20, right: ThemeSize.space16, child: FloatingActionButton.small(...))`。
  - 點擊回呼調用 `Utils.getCurrentPosition()`，並透過 `_mapController.animateCamera` 移動視角至當前座標（Zoom 15）。
  - 將 `PageView` 的 `height: 130` 替換為 `height: ThemeSize.size130`。
  - 將其餘裸數值替換為 `ThemeSize.space20`、`ThemeSize.zero`、`ThemeSize.space4`。

---

## 3. 任務拆分 (Tasks Breakdown)

- [x] **Task 1: 擴充 `ThemeSize` 尺寸常數**（複雜度：快/便宜）✅
  - 新增 `size130` 定義。
- [x] **Task 2: 改造 `MapWidget` 原生設定與自訂定位按鈕**（複雜度：標準）✅
  - 關閉原生按鈕與縮放按鈕。
  - 新增自訂定位按鈕並介接真實 GPS 定位。
  - 替換所有裸數字為 `ThemeSize` 常數。
- [x] **Task 3: 全面靜態分析與單元測試**（複雜度：標準）✅
  - 執行 `flutter analyze` 確保零警告。
  - 執行 `flutter test` 確保既有 102 筆測試全綠。

---

## 4. 驗收標準 (Verification)

- [x] `ThemeSize.size130` 成功宣告並編譯通過。
- [x] `MapWidget` 完全無魔術數字，對齊 Style Guide。
- [x] 地圖上原生右下角按鈕消失，右上角自訂定位按鈕正常運作。
- [x] `flutter analyze` 維持 `No issues found!`。
- [x] `flutter test` 全數通過。
