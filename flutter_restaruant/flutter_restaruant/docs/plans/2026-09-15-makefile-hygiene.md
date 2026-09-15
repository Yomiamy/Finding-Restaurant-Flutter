# Implementation Plan: Makefile 健全化與指令契約收斂 (Makefile Hygiene & Contract Standardization)

> 項目編號：**E-8.3**  
> 優先級別：**P1（工程規範改進）**  
> 關聯規格：[`docs/features/2026-09-15-makefile-hygiene.md`](../features/2026-09-15-makefile-hygiene.md)  
> 建立日期：2026-09-15  
> 狀態：草稿（待確認）

---

## 1. 簡介與目標 (Overview)

本計畫重構與收斂 `Makefile`，消滅殘留的 Riverpod 樣板與未實現的懸掛目標，補齊 Flutter 標準的 `test`、`test_coverage` 與 `analyze` 統一指令契約。

---

## 2. 檔案異動清單 (File Changes)

### 2.1 既有檔案修改
- **[`flutter_restaruant/flutter_restaruant/Makefile`](../../Makefile)**：
  - 更新 `.PHONY`：移除 `analyze_custom`、`mason_feature`；加入 `analyze`、`test`、`test_coverage`。
  - 更新 `help:`：對齊更新後的目標清單，移除無效說明。
  - 在 `Code Quality & Formatting` 區塊新增：
    - `analyze: analyze_lint`（別名）
    - `test`: `@flutter test`
    - `test_coverage`: `@flutter test --coverage` 搭配 `lcov` 摘要
  - 移除末尾 `## Tools` 區塊及 `mason_feature` target。

---

## 3. 任務拆分 (Tasks Breakdown)

- [ ] **Task 1: 重構與清理 `Makefile`**（複雜度：極低）
  - 編輯 `Makefile`，移除死代碼與懸掛宣告。
  - 補齊 `test`、`test_coverage` 與 `analyze` target。
  - 確保語意縮排使用標準 Tab 字元。

- [ ] **Task 2: 本地驗證指令運作**（複雜度：極低）
  - 執行 `make help` 檢查輸出格式。
  - 執行 `make analyze` 確保能正確呼叫分析。
  - 執行 `make test` 確保測試順利運行。
  - 執行 `make test_coverage` 確保覆蓋率檔案順利產生。

---

## 4. 驗證與退出標準 (Exit Criteria)

1. `make -n <target>` 語法無任何 Tab/語法解析錯誤。
2. `make test` 與 `make analyze` 執行回傳碼為 0。
3. `Makefile` 內不再包含 `riverpod` 或未實現之 `analyze_custom`。
