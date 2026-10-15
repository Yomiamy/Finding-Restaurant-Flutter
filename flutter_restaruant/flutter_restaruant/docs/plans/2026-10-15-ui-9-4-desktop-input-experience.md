# 實作計畫：UI-9.4 桌面輸入體驗（滑鼠拖曳、Hover 反饋與鍵盤發送）

- **建立日期**：2026-10-15
- **對應規格**：`docs/features/2026-10-15-ui-9-4-desktop-input-experience.md`
- **狀態**：等待確認 (Pending Confirmation)

---

## 1. 簡介與目標 (Overview & Goals)

落實功能項目 `UI-9.4`，大幅改善 macOS、桌面與 Web 環境下的輸入與操作手感：
1. **全域滑鼠拖曳**：解除 Flutter 預設對滑鼠滾動拖曳的封鎖，使橫向 `PageView` 與列表均可透過滑鼠直接拖曳捲動。
2. **卡片 Hover 與游標反饋**：主頁餐廳列表與地圖卡片支援 Material 3 Hover 效果與 `SystemMouseCursors.click` 手型游標。
3. **AI Foodie 鍵盤捷徑**：輸入框支援 1～4 行多行擴展，實體鍵盤 Enter 送出、Shift+Enter 換行。

---

## 2. 檔案異動清單 (File Changes)

### 2.1 新增檔案
- `lib/features/foundation/style/app_scroll_behavior.dart`：自訂 `AppScrollBehavior`，在 `dragDevices` 中包含 `mouse`、`touch`、`trackpad` 等。
- `test/features/foundation/style/app_scroll_behavior_test.dart`：針對 `AppScrollBehavior` 的單元測試。
- `test/flow/ai_foodie/view/ai_foodie_sheet_keyboard_test.dart`：針對 AI Foodie 鍵盤快捷發送的 Widget 測試。

### 2.2 修改檔案
- `lib/features/foundation/style/style_barrel.dart`：匯出 `app_scroll_behavior.dart`。
- `lib/main.dart`：於 `PlatformApp.builder` 與 `MaterialAppData` 注入 `AppScrollBehavior`。
- `lib/flow/main/view/restaurant_info_list_widget.dart`：將 `GestureDetector` 改為 `InkWell`。
- `lib/flow/main/view/map_widget.dart`：將 PageView 卡片之 `GestureDetector` 改為 `InkWell`。
- `lib/flow/ai_foodie/view/ai_foodie_sheet.dart`：設定多行伸縮與 `CallbackShortcuts`（Enter 送出）。

---

## 3. 實作任務拆分 (Tasks)

### 任務 1：建立並注入全域 `AppScrollBehavior`
- **內容**：
  - 在 `lib/features/foundation/style/app_scroll_behavior.dart` 中建立 `class AppScrollBehavior extends MaterialScrollBehavior`。
  - 覆寫 `dragDevices`，回傳 `{PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.stylus, PointerDeviceKind.invertedStylus, PointerDeviceKind.trackpad}`。
  - 在 `lib/features/foundation/style/style_barrel.dart` 匯出。
  - 在 `lib/main.dart` 中的 `PlatformApp.builder` 透過 `ScrollConfiguration(behavior: const AppScrollBehavior(), ...)` 注入，並在 `MaterialAppData` 設定 `scrollBehavior: const AppScrollBehavior()`。
- **驗證**：編寫單元測試驗證 `dragDevices` 集合完整包含 `mouse`。

### 任務 2：優化餐廳列表與地圖卡片之 Hover 與游標反饋
- **內容**：
  - `lib/flow/main/view/restaurant_info_list_widget.dart`：卡片包裝改用 `InkWell`，提供 M3 點擊波紋、hoverColor 與手型游標。
  - `lib/flow/main/view/map_widget.dart`：地圖浮動卡片外層包裝改用 `InkWell`，設定適當圓角。
- **驗證**：既有 `map_widget_test.dart` 與 `main_page_content_widget_test.dart` 測試無回歸。

### 任務 3：優化 AI Foodie 聊天輸入框之鍵盤互動
- **內容**：
  - `lib/flow/ai_foodie/view/ai_foodie_sheet.dart`：
    - 將 `TextField` 調整為 `minLines: 1`、`maxLines: 4`、`keyboardType: TextInputType.multiline`。
    - 包裹 `CallbackShortcuts`，綁定 `SingleActivator(LogicalKeyboardKey.enter)` 執行 `_sendMessage()`。
    - 保持行動裝置軟體鍵盤上的 Send 動作相容性。
- **驗證**：編寫 Widget 測試，模擬實體鍵盤 Enter 發送與 Shift+Enter 換行。

### 任務 4：整合驗收與回歸測試
- **內容**：
  - 執行 `flutter analyze .` 確保無任何 lint 錯誤與警告。
  - 執行 `flutter test` 確保所有測試（含既有 313+ 個測試與新增測試）全數綠燈。
  - 驗收 macOS 本機建置。

---

## 4. 驗收標準 (Acceptance Criteria)

1. 全域啟用滑鼠拖曳（`AppScrollBehavior` 包含 `mouse`）。
2. 卡片點擊元件具備手型游標與 Hover 反饋。
3. AI Foodie 對話輸入框支援 Enter 發送與多行展開。
4. 全套單元與 Widget 測試 100% 通過，靜態分析 0 警告。
