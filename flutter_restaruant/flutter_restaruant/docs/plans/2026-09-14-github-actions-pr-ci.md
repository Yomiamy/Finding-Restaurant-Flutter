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

## 5. 驗證與退出標準 (Exit Criteria)

1. `.github/workflows/pr-check.yml` 檔案結構完整且符合 GitHub Actions 語法規範。
2. 覆核本地執行分析與測試零報錯、全數通過。
