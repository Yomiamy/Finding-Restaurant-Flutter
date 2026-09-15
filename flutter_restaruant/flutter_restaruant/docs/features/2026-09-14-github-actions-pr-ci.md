# Feature: GitHub Actions PR CI 門禁工作流 (PR CI Guardrail - GitHub Actions)

> 項目編號：**E-8.1**  
> 優先級別：**P0（阻擋級 / 基礎設施守衛）**  
> 建立日期：2026-09-14  
> 參考文檔：`docs/brainstorm/2026-09-12-features-brainstorm.md` §8.3.1 [E-8.1]  
> 狀態：草稿（待確認）

---

## 1. 背景與動機 (Why)

### 1.1 現狀痛點
1. **主幹品質缺乏自動化防線 (Zero CI Gate)**：
   - 目前專案僅存在 Tag 觸發之發布流水線（`.github/workflows/release.yml` 與 `.github/workflows/android-tag-build.yml`），在發起 Pull Request (PR) 或 Push 到 `main` 分支時，**完全沒有任何 CI 門禁機制**。
   - 開發者若漏跑本地靜態分析或單元測試，壞損的代碼（編譯錯誤、Lint 警告、邏輯回歸）可被直接合併進主幹 `main`，嚴重破壞穩定性。
2. **手動驗收不可靠且高成本**：
   - Code Review 者必須依賴本地 checkout 該分支跑測試驗證，耗時費力且無法作為 PR Merge 的硬性卡點（Branch Protection Rules）。

### 1.2 改造目標 (Linus 實用主義模式)
- **建立快速、低成本、確定性的 CI 門禁**：
  - 新增 `.github/workflows/pr-check.yml`。
  - 使用最輕量的 `ubuntu-latest` Runner（啟動速度最快、消耗 Action 額度最低）。
  - 配置 `concurrency` 策略，當開發者連續 push commit 時，自動取消舊的建置（`cancel-in-progress: true`），避免資源浪費。
- **嚴格守護兩大門禁**：
  1. `flutter analyze .`：確保零警告、零錯誤，杜絕語法與規範腐化。
  2. `flutter test`：確保所有單元測試與 Widget 測試 100% 通過，防範功能回歸。
- **消滅路徑特殊情況**：
  - 專案根目錄為 Mono-repo 結構，Flutter 應用位於 `flutter_restaruant/flutter_restaruant`。
  - 透過 Job 級別 `defaults.run.working-directory` 統一工作目錄，避免各 step 散落 `cd` 或路徑錯誤。

---

## 2. 規格需求 (What)

### 2.1 觸發條件 (Triggers)
```yaml
on:
  pull_request:
    branches: [ main ]
  push:
    branches: [ main ]
```
- **Pull Request**：向 `main` 分支發起 PR 或 PR 更新時觸發，作為 GitHub 分支保護規則的必要檢查項。
- **Push to main**：當 PR 合併或 direct push 到 `main` 時再次執行，確保主幹狀態永續為綠色。

### 2.2 並發控制 (Concurrency)
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### 2.3 工作流步驟規劃 (`pr-check.yml`)
- **Job 名稱**：`analyze-and-test`
- **Runner**：`ubuntu-latest`
- **逾時時間**：15 分鐘
- **預設目錄**：`flutter_restaruant/flutter_restaruant`
- **具體 Steps**：
  1. `actions/checkout@v4`：檢出程式碼。
  2. `subosito/flutter-action@v2`：
     - `channel: 'stable'`
     - `flutter-version: '3.44.1'`
     - `cache: true`
  3. `flutter pub get`：解析並下載依賴套件。
  4. `flutter analyze .`：靜態代碼分析。
  5. `flutter test`：執行全套單元與元件測試。

---

## 3. 邊界與非目標 (Out of Scope)

- **不做應用打包**：本工作流不打包 APK / AAB / IPA，保持 CI 極速反饋（目標 2~3 分鐘內完成）。
- **不做覆蓋率強校驗門禁**：測試覆蓋率基準線由後續提案 `[E-8.4]` 獨立處理，本工作流以全數測試通過為目標。
- **不涉及發布發信**：無須配置第三方通知渠道，由 GitHub PR 介面直接呈現 Check 狀態。

---

## 4. 驗收條件 (Verification)

1. **靜態語法**：YAML 格式正確，GitHub Actions 語法無任何瑕疵。
2. **本地等價驗證**：在 `flutter_restaruant/flutter_restaruant` 執行：
   - `flutter pub get` 通過
   - `flutter analyze .` 回傳 0 issues
   - `flutter test` 所有測試通過
3. **CI 行為驗證**：提交至 GitHub PR 時能正常觸發該 Check 並通過。
