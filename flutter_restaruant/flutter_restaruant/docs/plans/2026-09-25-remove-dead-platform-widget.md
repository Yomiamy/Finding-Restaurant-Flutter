# Implementation Plan: 刪除死碼 `PlatformWidget` (Remove Dead `platform_widget.dart`)

> 項目編號：**UI-8.2**  
> 優先級別：**P1（技術債清理）**，effort 0.1d  
> 關聯規格：[`docs/features/2026-09-25-remove-dead-platform-widget.md`](../features/2026-09-25-remove-dead-platform-widget.md)  
> 建立日期：2026-09-25  
> 狀態：草稿（待確認）

---

## 1. 簡介與目標 (Overview)

刪除無任何引用的 `abstract class PlatformWidget<I, A>`（`lib/component/platform_widget.dart`）及其 barrel export，消除與 `package:flutter_platform_widgets` 同名 `PlatformWidget` 的潛在 ambiguous import 衝突。

## 2. 實作方向與 Trade-off

| 方向 | 內容 | 評估 |
|------|------|------|
| **A. 刪檔 + 刪 export（採用）** | 移除檔案與 `component_barrel.dart` 第 5 行 | 最短 diff、根除衝突，零行為變更 |
| B. 只刪 export、保留檔案 | 衝突消失但留下孤兒檔案 | 死碼仍在，沒解決問題 |
| C. 改名（如 `AppPlatformWidget`） | 保留抽象避免撞名 | 為 0 引用的程式碼維護名稱，YAGNI |

## 3. 檔案異動清單 (File Changes)

- **刪除** `lib/component/platform_widget.dart`
- **修改** `lib/component/component_barrel.dart`：刪除第 5 行 `export 'platform_widget.dart';`

不動：`pubspec.yaml` 與所有 `package:flutter_platform_widgets` 使用處。不新增測試（純刪除，靠 analyze + 既有測試驗證）。

## 4. 任務拆分 (Tasks Breakdown)

- [ ] **Task 1: 刪除 `platform_widget.dart` 與其 export**（複雜度：極低）
  1. 前置確認僅剩 barrel 一處引用：
     ```bash
     rtk grep -rn "platform_widget.dart" lib test
     ```
     預期：只命中 `lib/component/component_barrel.dart:5`。
  2. 刪檔：
     ```bash
     git rm lib/component/platform_widget.dart
     ```
  3. 編輯 `lib/component/component_barrel.dart`，刪除 `export 'platform_widget.dart';`，結果為：
     ```dart
     export 'ad/ad_barrel.dart';
     export 'cell/cell_barrel.dart';
     export 'empty_data_widget.dart';
     export 'loading_widget.dart';
     ```
  4. 驗證（見 §5）。
  5. Commit 訊息建議：
     ```
     refactor(component): remove dead PlatformWidget abstraction

     lib/component/platform_widget.dart had zero subclasses or callers and
     shadowed flutter_platform_widgets' PlatformWidget via component_barrel,
     a latent ambiguous-import error. Delete the file and its barrel export.
     ```

## 5. 驗證與退出標準 (Exit Criteria)

```bash
test ! -e lib/component/platform_widget.dart && echo OK   # 檔案已不存在
rtk grep -rn "platform_widget.dart" lib test              # 無結果
rtk flutter analyze                                       # No issues found
rtk flutter test                                          # 全綠
```

## 6. 執行方式 (Execution Options)

- **Subagent-driven（建議）**：單一任務、單一 commit，交由一個 implementer subagent 執行並回報驗證輸出即可。
- **Parallel session**：不適用——只有一個任務，無可平行化的工作。
