# Implementation Plan: GitHub Actions PR CI 門禁工作流 (PR CI Guardrail - GitHub Actions)

> 項目編號：**E-8.1**  
> 優先級別：**P0（基礎設施守衛）**  
> 關聯規格：[`docs/features/2026-09-14-github-actions-pr-ci.md`](../features/2026-09-14-github-actions-pr-ci.md)  
> 建立日期：2026-09-14  
> 狀態：草稿（待確認）

---

## 1. 簡介與目標 (Overview)

本計畫為專案主幹建立一道自動化且高效的 CI 門禁工作流（`.github/workflows/pr-check.yml`）。
在每次發起 Pull Request 到 `main` 分支或合併/推送至 `main` 時，自動在乾淨的 Linux 環境中執行靜態分析與全套單元/Widget 測試，杜絕任何語法、風格或測試破壞進入主幹。

---

## 2. 架構設計與 Trade-off 分析 (Design & Trade-offs)

### 2.1 Runner 選型：`ubuntu-latest`
- **對比 macOS Runner**：macOS Runner 成本極高且排隊等待時間長，只在需要跑 Xcode 打包時（如 `release.yml`）才使用。
- **純 Dart/Flutter 分析與測試**：在 `ubuntu-latest` 執行已足夠完整，啟動時間短、成本低、執行速度快。

### 2.2 工作目錄處理
- 專案根目錄為 Mono-repo 結構，Flutter 應用代碼位於 `flutter_restaruant/flutter_restaruant`。
- 採用 Job 層級的 `defaults.run.working-directory` 宣告，使所有 Flutter CLI 指令預設在正確目錄執行，消除各 Step 冗餘的 `working-directory` 宣告或 `cd` 邏輯。

### 2.3 並發與資源治理
- 啟用 `concurrency: group: ${{ github.workflow }}-${{ github.ref }}, cancel-in-progress: true`。
- 開發者頻繁 push 時自動中斷前一次未完成的檢查，防止 CI Runner 資源浪費。

---

## 3. 檔案異動清單 (File Changes)

### 3.1 新增檔案
- **[`.github/workflows/pr-check.yml`](../../../../.github/workflows/pr-check.yml)**：
  - 放置於 Git 根目錄之 `.github/workflows/` 下。
  - 定義 PR 與 main push 觸發條件、concurrency 控制、Flutter 環境配置及 analyze / test 檢查。

---

## 4. 任務拆分 (Tasks Breakdown)

- [ ] **Task 1: 建立 `.github/workflows/pr-check.yml`**（複雜度：低 / 機械性）
  - 依據規格配置觸發事件、並發策略與 Steps。
  - 使用 `subosito/flutter-action@v2` 鎖定 `flutter-version: '3.44.1'` 與 `channel: 'stable'`。
  - 加入 `cache: true` 加速 pub 依賴快取。

- [ ] **Task 2: 本地模擬與語法驗收**（複雜度：極低）
  - 使用 Python YAML 解析器或語法檢查工具驗證 `pr-check.yml` 格式。
  - 在本地 `flutter_restaruant/flutter_restaruant` 目錄執行 `flutter pub get`、`flutter analyze .` 與 `flutter test`，確保本地行為與 CI 完全對齊（綠燈）。

---

## 5. Branch Protection Rule 設定 (Repository Configuration)

Workflow YAML 本身**只負責執行檢查並回報結果**，不具備阻擋合併的能力。
要讓 CI 門禁真正生效，必須在 GitHub Repository 設定 Branch Protection Rule。

### 5.1 設定路徑

**Settings → Branches → Add branch ruleset** (或 Add rule)，對 `main` 分支套用以下規則：

### 5.2 建議啟用的規則

| 規則 | 說明 |
|---|---|
| **Require a pull request before merging** | 禁止任何人直接 push `main`，強制走 PR 流程 |
| **Require status checks to pass before merging** | CI 沒過就不能按 merge 按鈕 |
| **Require branches to be up to date before merging**（可選） | merge 前必須 rebase/merge 最新 main，避免多 PR 同時 merge 後互相衝突 |
| **Include administrators**（可選） | 連 repo owner / admin 也必須遵守，無人可繞過 |

### 5.3 指定 Required Status Check

勾選 "Require status checks to pass" 後，**必須在下方搜尋框指定具體的 check name**，否則 GitHub 不知道要等哪個 check，merge 按鈕可能直接啟用：

1. 在搜尋框輸入 **`Analyze & Test`**（對應 `pr-check.yml` 中 job 的 `name` 欄位）
2. 勾選該項目

### 5.4 設定後的 PR 行為

| CI 狀態 | Merge 按鈕 |
|---|---|
| 🟡 Running | 灰色，不可按 |
| ❌ Failed | 灰色，不可按 |
| ✅ Passed | 綠色，可以按 |

> [!IMPORTANT]
> 若未在 5.3 中指定 required check，即使大開關已開，GitHub 仍可能允許直接 merge。

---

## 6. 驗證與退出標準 (Exit Criteria)

1. `.github/workflows/pr-check.yml` 檔案結構完整且符合 GitHub Actions 語法規範。
2. 覆核本地執行分析與測試零報錯、全數通過。
3. Repository Branch Protection Rule 已設定，PR merge 按鈕在 CI 未通過時為不可操作狀態。
