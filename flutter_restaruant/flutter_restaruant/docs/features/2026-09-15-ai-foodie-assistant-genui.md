# Feature: AI 智能覓食助理與 GenUI 決策畫布 (AI Foodie Assistant & GenUI Canvas)

> 項目編號：**M4**  
> 優先級別：**P1（AI 差異化體驗）**  
> 建立日期：2026-09-15  
> 參考文檔：`docs/brainstorm/2026-09-12-features-brainstorm.md` §7.3, §7.4 情境 1  
> 狀態：草稿（待確認）

---

## 1. 背景與動機 (Why)

### 1.1 現狀痛點
1. **多維需求與自然語言篩選困難**：
   - 傳統分類過濾器（價格、距離、評分）無法處理複雜生活化情境（例如：「4 人中山站、想吃居酒屋聊天、預算每人 600」）。使用者需在多間餐廳詳情頁間反覆切換比對。
2. **最後一哩選擇困難 (Decision Paralysis)**：
   - 使用者在挑出 3~4 間候選名單後，常因各有優缺點陷入猶豫不決，缺乏趣味且直觀的決策收斂機制。

### 1.2 改造目標 (Linus 實用主義模式)
- **自然語言對話與決策畫布 (Conversational Foodie Canvas)**：
  - 在主頁搜尋列加入 ✨ AI 覓食助理進入點，點擊後展開 `DraggableScrollableSheet`（對話畫布）。
  - 支援自然語言對話輸入與預設情境快捷標籤（如「約會不踩雷」、「深夜下酒菜」、「CP值之王」）。
- **GenUI (A2UI) 宣告式元件擴充**：
  - **對比矩陣元件 (`ComparisonMatrixComponent`)**：橫向滾動卡片 Carousel，直觀比對餐廳評分、人均價位、亮點與特色。
  - **行動標籤群組 (`ActionChipGroupComponent`)**：支援「📍 在地圖上高亮」與「🎲 命運轉盤抽籤」等可點擊行動。
  - **命運轉盤元件 (`DecisionRouletteComponent`)**：原生繪製輪盤與平滑旋轉動畫，隨機從候選名單選出一間餐廳，解決聚餐選擇困難。
- **好品味與防護**：
  - 承襲 Dart 3 `sealed class A2UIComponent` 體系，編譯期窮盡檢查。
  - 網路或 API 異常時提供安全降級與本地智慧推薦，保證絕不崩潰 (Never break userspace)。

---

## 2. 規格需求 (What)

### 2.1 領域層資料結構 (Domain Entities)
1. **擴充 `A2UIComponent`**：
   - `ComparisonMatrixComponent`:
     - `title`: String
     - `items`: List<RestaurantComparisonItem> (id, name, rating, price, highlights, address)
   - `ActionChipGroupComponent`:
     - `chips`: List<ActionChipItem> (label, action, payload)
   - `DecisionRouletteComponent`:
     - `options`: List<String>
     - `title`: String?
2. **`AiFoodieMessage`**：
   - `id`: String
   - `isUser`: bool
   - `text`: String
   - `components`: List<A2UIComponent>
   - `createdAt`: DateTime

### 2.2 倉儲契約 (Repository Interface)
- `AiFoodieRepository`:
  - `Future<List<AiFoodieMessage>> getInitialSuggestions()`：取得歡迎語與預設情境標籤。
  - `Future<AiFoodieMessage> askAssistant(String prompt, {List<AiFoodieMessage>? history})`：發送使用者需求並取得結構化回應。

### 2.3 表現層 (BLoC & UI)
- **`AiFoodieBloc`**：
  - 事件：`LoadInitialSuggestions`, `SendUserPrompt`, `TriggerActionChip`, `SpinRoulette`。
  - 狀態：`AiFoodieState`（包含訊息列表、載入中旗標、當前轉盤抽籤狀態）。
- **元件視窗 (`AiFoodieSheet`)**：
  - 彈性底部對話畫布 (`DraggableScrollableSheet`)。
  - 對話訊息氣泡與動態 GenUI 元件組合（卡片橫向捲動、行動按鈕列）。
  - 互動命運轉盤彈窗 (`DecisionRouletteDialog`)：原生 `CustomPainter` 繪製扇形輪盤，搭配緩動減速旋轉動畫。

---

## 3. 邊界與非目標 (Out of Scope)

- 不在此階段實作跨使用者即時連線共編投票（由 Phase 2 社群美食地圖處理）。
- 不引入第三方未經審查的 heavy wheel packages，以 Flutter 原生動畫與自訂繪製完成。

---

## 4. 驗收條件 (Verification)

1. 主畫面點擊 ✨ 按鈕能順利由底部呼出 `AiFoodieSheet`。
2. 點擊預設推薦或輸入文字，能生成包含對話、對比卡片（ComparisonMatrix）與行動群組（ActionChipGroup）的 GenUI 介面。
3. 點擊「命運轉盤」能喚起旋轉動畫並隨機選出一間推薦餐廳。
4. 點擊卡片能導向餐廳詳情頁或觸發地圖連動。
5. 單元測試覆蓋 `AiFoodieBloc` 與元件解析邏輯，`flutter analyze .` 與 `flutter test` 全數通過。
