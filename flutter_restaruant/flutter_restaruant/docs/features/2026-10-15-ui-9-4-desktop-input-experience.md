# 功能規格：UI-9.4 桌面輸入體驗（滑鼠拖曳、Hover 反饋與鍵盤發送）

- **建立日期**：2026-10-15
- **負責角色**：Flutter UI/UX 專家
- **狀態**：規劃中 (Draft)
- **關聯**：
  - 需求來源：`docs/brainstorm/2026-10-12-features-brainstorm.md` §9.6 `UI-9.4`
  - 前置依賴：`A-9.6`（macOS 基礎適配）
  - 後續關聯：`UI-9.3`（響應式版面佈局）

---

## 1. 需求背景與痛點 (Problem & Background)

### 1.1 現況與痛點
- **滑鼠拖曳限制 (Mouse Dragging)**：Flutter 框架預設之 `MaterialScrollBehavior` 與 `CupertinoScrollBehavior` 僅將觸控（`touch`）與手寫筆（`stylus`）列入 `dragDevices`，滑鼠（`mouse`）預設被排除。這導致在 macOS 與 Web 平台上，地圖下方的橫向餐廳卡片列 `PageView`（`map_widget.dart:180`）與列表無法直接用滑鼠點擊拖曳捲動。
- **缺乏 Hover 與游標反饋 (Hover & Pointer Feedback)**：主頁餐廳列表（`restaurant_info_list_widget.dart:107`）與地圖卡片（`map_widget.dart:201`）使用 `GestureDetector` 封裝，滑鼠懸停 (hover) 時既無手型游標（`SystemMouseCursors.click`），亦無 Material 3 的 hover 背景高亮，桌面手感生硬如靜態元件。
- **AI 對話輸入體驗 (Desktop Chat Input)**：`ai_foodie_sheet.dart` 的對話輸入框目前為單行 `TextField`。在桌面情境下，使用者普遍習慣「Enter 直接送出訊息、Shift+Enter 插入換行」，且期望輸入框隨字數彈性展開至多行（1～4 行）。

### 1.2 目標 (Goals)
1. **全域滑鼠拖曳與平滑滾動**：
   - 建立並注入全域 `AppScrollBehavior`，在 `dragDevices` 中納入 `PointerDeviceKind.mouse` 與 `PointerDeviceKind.trackpad`，使全 App 之 `PageView`、`ListView`、`GridView` 等皆能順暢支援滑鼠拖曳。
2. **桌面互動 Hover 與手型游標**：
   - 將主頁餐廳卡片與地圖浮動卡片之互動容器重構為具備 M3 Hover 與手型游標反饋之元件（使用 `InkWell` 取代裸 `GestureDetector`）。
3. **AI Foodie 鍵盤 Enter 快捷發送**：
   - 輸入框升級為可伸縮多行（`minLines: 1`, `maxLines: 4`）。
   - 透過 `CallbackShortcuts` / 鍵盤事件監聽，實現桌面標準聊天體驗：單按 `Enter` 立即發送，`Shift + Enter` 插入換行。

---

## 2. 需求 Brief (gen-grill 審核)

- **Q1 問題定義**：Flutter 桌面/Web 預設禁用滑鼠拖曳滾動；主頁卡片無 hover 反饋；AI 輸入框缺乏多行 Enter 發送與 Shift+Enter 換行機制。
- **Q2 觸發場景**：桌面使用者用滑鼠點擊並拖曳地圖餐廳卡片列、瀏覽餐廳列表，或在 AI Foodie 聊天框輸入提示詞。
- **Q3 成功標準**：
  1. `AppScrollBehavior` 覆蓋全域，包含 `mouse` 裝置，`PageView` 與 `ListView` 可用滑鼠拖曳。
  2. 列表與地圖卡片具備點擊波紋、hover 高亮與 `SystemMouseCursors.click` 游標。
  3. AI 輸入框支援 1～4 行自動伸縮，實體鍵盤 Enter 發送、Shift+Enter 換行。
  4. 既有 313+ tests 通過、新增單元與 Widget 測試通過、`flutter analyze` 零警告。
- **Q4 範圍邊界**：
  - 不動多欄佈局與視窗尺寸調整（屬於 UI-9.3 響應式範疇）。
  - 不改動移動端觸控體驗與既有 BLoC 業務邏輯。
- **Q5 既有覆蓋實查**：
  - 現行 codebase 無任何自訂 `ScrollBehavior`。
  - 卡片處均為單純 `GestureDetector`。

---

## 3. 驗收條件 (Acceptance Criteria)

- **AC-1**：全域滾動配置
  - `lib/features/foundation/style/app_scroll_behavior.dart` 實作繼承 `MaterialScrollBehavior`，`dragDevices` 包含 `mouse` 與 `touch`。
  - 在 `PlatformApp` 全域注入，`PageView` 驗證可滑鼠拖曳。
- **AC-2**：卡片 Hover 與游標
  - 餐廳列表項目與地圖 PageView 卡片懸停時顯示手型游標與點擊波紋效果。
- **AC-3**：AI 輸入框快捷鍵
  - `ai_foodie_sheet.dart` 支援 Enter 送出訊息、Shift+Enter 插入換行，字數增加時高度在 1 至 4 行間自適應。
- **AC-4**：向後相容與回歸測試
  - 手機端觸控行為與外觀零回歸，所有單元測試與 Widget 測試綠燈。
