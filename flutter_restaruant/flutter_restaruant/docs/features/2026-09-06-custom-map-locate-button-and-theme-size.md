# Feature: 自訂地圖定位懸浮按鈕與 ThemeSize 常數重構 (Custom Map Locate Button & ThemeSize Alignment)

## 1. 背景與動機 (Why)

在首頁地圖探索模式中（[`map_widget.dart`](../../lib/flow/main/view/map_widget.dart)），目前存在以下使用者體驗與架構維護問題：

1. **原生控制項遮蔽與不可控**：
   - `GoogleMap` 啟用 `myLocationEnabled: true` 時，預設會連帶開啟原生的「我的位置」按鈕 (`myLocationButtonEnabled: true`)。
   - 原生按鈕的位置由底層 Google Maps SDK 決定，無法在 Flutter 層自由設定錨點與對齊方式；且底部常駐 130dp 餐廳卡片 `PageView`，容易與原生按鈕產生佈局遮擋與誤觸。
2. **硬編碼數值與設計系統偏離**：
   - `MapWidget` 內部散落多處裸數字（`height: 130`、`bottom: 20`、`left: 0`、`right: 0`、`horizontal: 4.0`），未對齊專案的 [`ThemeSize`](../../lib/features/foundation/style/theme_size.dart) 規範，特別是底部卡片高度 `130` 缺乏對應的 token。
3. **定位體驗不佳**：
   - 預設原生按鈕外觀無法配合 Material 3 品牌色調與尺寸規範。

本功能旨在關閉原生地圖定位按鈕與縮放控制項，改用純 Flutter 自訂的 FloatingActionButton 進行精確佈局與流暢定位，並同步完成 `ThemeSize` 設計系統常數對齊。

---

## 2. 規格需求 (What)

### 2.1. 擴充 Design System 尺寸常數 (ThemeSize)
- 在 [`theme_size.dart`](../../lib/features/foundation/style/theme_size.dart) 的一般尺寸 (Size) 區塊新增 `static const double size130 = 130;`。
- 全面掃除 `MapWidget` 佈局中的魔術數字：
  - `bottom: 20` $\rightarrow$ `ThemeSize.space20`
  - `left: 0` / `right: 0` $\rightarrow$ `ThemeSize.zero`
  - `height: 130` $\rightarrow$ `ThemeSize.size130`
  - 卡片邊距 `horizontal: 4.0` $\rightarrow$ `ThemeSize.space4`

### 2.2. 停用 GoogleMap 原生按鈕
- 在 [`map_widget.dart`](../../lib/flow/main/view/map_widget.dart) 中設定：
  - `myLocationEnabled: true`：維持地圖藍色自身定位圖層（Blue Dot）。
  - `myLocationButtonEnabled: false`：關閉無法客製化且位置易衝突的原生定位按鈕。
  - `zoomControlsEnabled: false`：關閉 Android 原生縮放按鈕，讓版面保持純淨。

### 2.3. 實作自訂懸浮定位按鈕 (Custom Locate FAB)
- 於 `MapWidget` 的 `Stack` 右上角（`top: ThemeSize.space20`, `right: ThemeSize.space16`）掛載 `FloatingActionButton.small`：
  - 背景色：白色 (`Colors.white`)。
  - 圖示：`Icon(Icons.my_location, color: Colors.blue)`。
  - 點擊行為：非同步呼叫專案既有的 [`Utils.getCurrentPosition()`](../../lib/features/utils/utils.dart#L45) 獲取當前真實設備 GPS 座標，並透過 `_mapController.animateCamera` 結合 `CameraUpdate.newLatLngZoom(..., 15)` 平滑平移至目前位置並拉近視野。

---

## 3. 驗收條件 (Acceptance Criteria)

- [x] **ThemeSize 對齊**：`ThemeSize.size130` 成功定義，`MapWidget` 底部卡片高度與間距完全由 `ThemeSize` 常數管理，無裸數字。
- [x] **控制項停用**：Google 地圖畫面上不再出現原生右下角定位按鈕與縮放按鈕，且自身藍點圖層依然正常運作。
- [x] **自訂按鈕運作**：右上角自訂定位按鈕可點擊，點擊後相機平滑平移至當前真實位置（Zoom 15），無任何 unhandled exception。
- [x] **品質保證**：
  - `flutter analyze` 保持 `No issues found!`。
  - `flutter test` 全數通過。

---

## 4. 範圍邊界 (Scope Boundary)

- **In-Scope**:
  - `lib/features/foundation/style/theme_size.dart` 新增 `size130`。
  - `lib/flow/main/view/map_widget.dart` 控制項開關、自訂定位按鈕實作、常數替換。
  - 單元與靜態代碼測試驗證。
- **Out-of-Scope**:
  - 地圖標記聚合（Fluster Marker Clustering，已於 Issue #76 廢棄）。
  - 餐廳卡片 PageView 滑動至詳情頁的業務邏輯變更。
  - 離線地圖快取。
