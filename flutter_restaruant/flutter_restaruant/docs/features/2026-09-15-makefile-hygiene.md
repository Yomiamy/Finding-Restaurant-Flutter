# Feature: Makefile 健全化與指令契約收斂 (Makefile Hygiene & Contract Standardization)

> 項目編號：**E-8.3**  
> 優先級別：**P1（核心改進 / 開發工程規範）**  
> 建立日期：2026-09-15  
> 參考文檔：`docs/brainstorm/2026-09-12-features-brainstorm.md` §8.3.2 [E-8.3]  
> 狀態：草稿（待確認）

---

## 1. 背景與動機 (Why)

### 1.1 現狀痛點
1. **指令契約缺失（無 test / test_coverage）**：
   - 專案根目錄的 `Makefile` 是團隊本地開發與自動化執行的統一進入點，但目前竟然**完全未定義 `test` 與 `test_coverage` target**。
   - 開發者在本地需自行拼寫 `flutter test` 或記住複雜的覆蓋率輸出指令。
2. **懸掛無效目標 (Dangling Target)**：
   - `.PHONY` 與 `help` 宣告了 `analyze_custom`（宣稱使用 custom_lint），但檔案內**零實作代碼**，且專案並未引入 `custom_lint` 套件，形成欺騙性介面。
3. **複製貼上殘留之異構樣板 (Foreign Boilerplate Slop)**：
   - 檔案末尾殘留 `mason_feature: @mason make clean_architecture_feature_riverpod`。
   - 本專案核心架構為 **BLoC**，完全未採用 Riverpod。此 target 屬其他專案複製貼上之死代碼與認知噪音。

### 1.2 改造目標 (Linus 實用主義模式)
- **消滅認知負擔與死代碼**：
  - 拔除 `analyze_custom` 與 `mason_feature`，保持 Makefile 斯巴達式精簡。
  - 提供直觀的 `test` 與 `test_coverage` 契約。
- **好品味防護**：
  - `test_coverage` 自動執行測試並生成 `coverage/lcov.info`；若系統已安裝 `lcov` 則印出摘要報告，若未安裝則友善提示路徑而不報錯 crash。
  - 新增 `analyze` 作為 `analyze_lint` 之標準別名，符合現代 CLI 呼叫直覺。

---

## 2. 規格需求 (What)

### 2.1 目標清單調整
1. **移除 (Delete)**：
   - `analyze_custom`（.PHONY, help, 與任何殘留）
   - `mason_feature`（.PHONY, help, 與 target）
2. **新增 (Add)**：
   - `test`: 執行 `@flutter test`。
   - `test_coverage`: 執行 `@flutter test --coverage`，若有 `lcov` 則調用 `lcov --summary coverage/lcov.info`。
   - `analyze`: 轉發至 `analyze_lint`。
3. **更新 (Update)**：
   - `.PHONY` 聲明清單同步更新。
   - `make help` 輸出資訊同步對齊。

---

## 3. 邊界與非目標 (Out of Scope)

- 不調整既有的 `gen`、`watch`、`run_*` 等成熟指令。
- 不強制作業系統強制安裝 `lcov` 工具（由腳本做條件判斷）。

---

## 4. 驗收條件 (Verification)

1. `make help` 輸出清晰，無 `analyze_custom` 與 `mason_feature`，且包含 `test` 與 `test_coverage`。
2. 執行 `make test` 成功跑完測試。
3. 執行 `make test_coverage` 能正確產出 `coverage/lcov.info`。
4. 執行 `make analyze` 能正確執行分析。
