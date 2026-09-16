# Implementation Plan: AI 智能覓食助理與 GenUI 決策畫布 (AI Foodie Assistant & GenUI Canvas)

> 項目編號：**M4**  
> 優先級別：**P1（AI 創新體驗）**  
> 關聯規格：[`docs/features/2026-09-15-ai-foodie-assistant-genui.md`](../features/2026-09-15-ai-foodie-assistant-genui.md)  
> 建立日期：2026-09-15  
> 狀態：草稿（待確認）

---

## 1. 簡介與架構目標 (Overview)

本計畫為應用程式建立自然語言 AI 覓食對話畫布（M4 里程碑），透過 GenUI (A2UI) 宣告式元件體系，在底部彈性抽屜 (`AiFoodieSheet`) 渲染多店決策對比卡片 (`ComparisonMatrixComponent`)、互動行動標籤 (`ActionChipGroupComponent`) 以及原生繪製之命運轉盤 (`DecisionRouletteDialog`)，提供一站式餐飲推薦與趣味抽籤體驗。

---

## 2. 檔案異動清單 (File Changes)

### 2.1 領域層 (Domain Layer)
- **[`lib/domain/entities/a2ui_component.dart`](../../lib/domain/entities/a2ui_component.dart)**：
  - 擴充 `sealed class A2UIComponent`，加入 `ComparisonMatrixComponent`、`ActionChipGroupComponent`、`DecisionRouletteComponent`。
- **[`lib/domain/entities/ai_foodie_message.dart`](../../lib/domain/entities/ai_foodie_message.dart)**（新增）：
  - 定義對話訊息實體 `AiFoodieMessage`。
- **[`lib/domain/entities/entities_barrel.dart`](../../lib/domain/entities/entities_barrel.dart)**：
  - Export 新增之實體類別。
- **[`lib/domain/repositories/ai_foodie_repository.dart`](../../lib/domain/repositories/ai_foodie_repository.dart)**（新增）：
  - 宣告 `AiFoodieRepository` 抽象介面。
- **[`lib/domain/repositories/repositories_barrel.dart`](../../lib/domain/repositories/repositories_barrel.dart)**：
  - Export `AiFoodieRepository`。

### 2.2 資料層 (Data Layer)
- **[`lib/data_layer/repositories/ai_foodie_repo.dart`](../../lib/data_layer/repositories/ai_foodie_repo.dart)**（新增）：
  - 實作 `AiFoodieRepository`，封裝 Gemini 推薦與本地智慧兜底引擎。
- **[`lib/data_layer/repositories/ai_foodie_schema.dart`](../../lib/data_layer/repositories/ai_foodie_schema.dart)**（新增）：
  - 定義 Gemini 結構化輸出 JSON 綱要 `aiFoodieResponseSchema`，在 Token 採樣層約束合法元件型別。
- **[`lib/di/injection.dart`](../../lib/di/injection.dart)**：
  - 註冊 `AiFoodieRepository` 到 GetIt 容器。

### 2.3 表現層 (Presentation Layer)
- **`lib/flow/ai_foodie/`**（新增模組）：
  - `bloc/ai_foodie_event.dart`：宣告事件（`LoadInitialSuggestions`, `SendUserPrompt`, `TriggerActionChip`, `OpenRoulette`, `SpinRouletteWinnerSelected`, `CloseRoulette`, `ResetAiFoodie`）。
  - `bloc/ai_foodie_state.dart`：宣告狀態（`AiFoodieState`，包含 messages, isLoading, currentRouletteWinner 等）。
  - `bloc/ai_foodie_bloc.dart`：實作狀態流轉。
  - `view/comparison_matrix_card.dart`：橫向對比卡片 Carousel。
  - `view/action_chip_group_widget.dart`：行動標籤群組元件。
  - `view/decision_roulette_dialog.dart`：原生 CustomPainter 繪製之命運轉盤與旋轉動畫。
  - `view/ai_foodie_sheet.dart`：底部 DraggableScrollableSheet 對話畫布。
  - `ai_foodie_barrel.dart`：模組 Barrel export。
- **[`lib/flow/main/view/main_page.dart`](../../lib/flow/main/view/main_page.dart)**：
  - AppBar 加入 ✨ AI 覓食按鈕，點擊彈出 `AiFoodieSheet.show(context)`。

### 2.4 測試層 (Tests)
- **`test/data_layer/ai_foodie_repo_test.dart`**（新增）：驗證 AI Foodie 結構化輸出 Schema 與 Repository 解析。
- **`test/domain/entities/a2ui_component_test.dart`**（新增）：驗證新增元件序列化與防禦性解析。
- **`test/flow/ai_foodie/ai_foodie_bloc_test.dart`**（新增）：單元測試覆蓋對話與轉盤狀態流轉。
- **`test/flow/ai_foodie/decision_roulette_test.dart`**（新增）：Widget 測試驗證轉盤渲染與動畫觸發。

---

## 3. 任務拆分 (Tasks Breakdown)

- [ ] **Task 1: Domain Entities 擴充與 Repository 抽象契約**（複雜度：標準）
  - 在 `a2ui_component.dart` 擴充 `ComparisonMatrixComponent`、`ActionChipGroupComponent`、`DecisionRouletteComponent`。
  - 建立 `AiFoodieMessage` 與 `AiFoodieRepository`，更新 barrels。

- [ ] **Task 2: Data Layer 實作與 GetIt 依賴註冊**（複雜度：標準）
  - 實作 `AiFoodieRepo`，內建情境推論模板與 fallback 對策。
  - 在 `lib/di/injection.dart` 完成 LazySingleton 註冊。

- [ ] **Task 3: Presentation BLoC 狀態機實作**（複雜度：標準）
  - 建立 `AiFoodieEvent`, `AiFoodieState`, `AiFoodieBloc`。
  - 支援初次加載預設情境與使用者 Prompt 對話。

- [ ] **Task 4: GenUI 元件與對話畫布視窗實作（含命運轉盤）**（複雜度：標準）
  - 實作 `ComparisonMatrixCard`、`ActionChipGroupWidget`。
  - 實作 `DecisionRouletteDialog`（自訂輪盤扇區繪製與緩動動畫）。
  - 實作 `AiFoodieSheet`（支援拖曳拉伸與對話氣泡佈局）。

- [ ] **Task 5: 主頁進入點接線與全套單元測試覆蓋**（複雜度：標準）
  - 在 `MainPage` 掛載 ✨ 助理進入點。
  - 撰寫 Domain 與 BLoC 單元測試，跑通 `flutter analyze .` 與 `flutter test`。

---

## 4. 驗證與退出標準 (Exit Criteria)

1. 全套 `flutter analyze .` 零警告、零錯誤。
2. 新增單元測試與元件測試全數通過，無 regressions。
3. `AiFoodieSheet` 可在主頁正常展開，點擊轉盤可流暢旋轉抽獎。
