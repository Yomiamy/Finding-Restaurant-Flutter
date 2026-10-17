# 功能規格：UI-9.2 fluttertoast 遷移至 SnackBar（含 ScaffoldMessenger 補齊）

- **建立日期**：2026-10-15
- **負責角色**：Flutter 跨平台專家
- **狀態**：規劃中 (Draft)
- **關聯**：
  - 需求來源：`docs/brainstorm/2026-10-12-features-brainstorm.md` §9.6 `UI-9.2`
  - 關聯問題：macOS 無 `fluttertoast` 實作；`CupertinoApp` 缺乏 `ScaffoldMessenger` 祖先導致無法顯示 SnackBar
  - 效益：移除淘汰套件，統一多平台即時反饋機制

---

## 1. 需求與背景 (Problem & Background)

### 1.1 現況與痛點
1. **macOS 平台無實作**：`fluttertoast` 為第三方外掛，僅針對 Android、iOS 及 Web 提供特定實作，在 macOS 上無原生實作，呼叫時靜默失效，導致 macOS 使用者無法獲得登入成功/失敗與收藏切換之即時通知。
2. **CupertinoApp 缺失 ScaffoldMessenger 祖先**：專案在 iOS 與 macOS 上採用 `PlatformApp` 的 `cupertino` 分支（即 `CupertinoApp`）。與 `MaterialApp` 不同，`CupertinoApp` 根節點**不會自動建立 `ScaffoldMessenger`**。若在頁面中直接調用 `ScaffoldMessenger.of(context).showSnackBar(...)`，將在 iOS/macOS 拋出 `No ScaffoldMessenger widget ancestor found` 致命異常。
3. **外部套件包袱**：`fluttertoast` 過去曾阻礙 Android Gradle Plugin 9+ 升級分析，且為外部依賴；全專案僅有 2 個檔案（共 4 處呼叫）使用該套件。

### 1.2 目標 (Goals)
1. **補齊 ScaffoldMessenger**：在 `lib/main.dart` 的 `PlatformApp.builder` 注入全域 `ScaffoldMessenger`，使 Material（Android）與 Cupertino（iOS/macOS/Web）皆能在任何子路由中無痛調用 `ScaffoldMessenger.of(context)`。
2. **完整遷移至 SnackBar**：
   - `lib/flow/signinup/view/sign_in_page.dart`：登入成功、註冊成功、驗證失敗訊息改以 `SnackBar` 呈現。
   - `lib/flow/restaurant/view/restaurant_detail_page.dart`：收藏新增與移除提示改以 `SnackBar` 呈現。
3. **移除套件相依**：自 `pubspec.yaml` 移除 `fluttertoast`，降低套件維護負擔與建置成本。
4. **健全測試保護**：編寫針對 `ScaffoldMessenger` 與 SnackBar 觸發之測試（包含 Cupertino 容器測試），確保零回歸。

---

## 2. 需求 Brief (gen-grill 審核)

- **Q1 問題定義**：`fluttertoast` 在 macOS 無法運作；`CupertinoApp` 分支缺少 `ScaffoldMessenger`，無法直接使用 `SnackBar`。
- **Q2 觸發場景**：使用者在登入頁登入/註冊/失敗，或在餐廳詳情頁切換收藏狀態時。
- **Q3 成功標準**：
  1. `PlatformApp.builder` 具備 `ScaffoldMessenger`。
  2. 全案消除所有 `Fluttertoast.showToast` 呼叫，改用 `SnackBar`。
  3. `pubspec.yaml` 徹底移除 `fluttertoast`。
  4. 既有 316+ tests 通過、新增 SnackBar 測試通過、`flutter analyze` 零錯誤。
- **Q4 範圍邊界**：
  - 不改變登入與收藏的 BLoC 狀態流。
  - 不導入其他重量級通知套件。
- **Q5 既有覆蓋實查**：
  - 查得 `fluttertoast` 僅存在於 `sign_in_page.dart` 與 `restaurant_detail_page.dart`。

---

## 3. 驗收條件 (Acceptance Criteria)

- **AC-1**：全域 ScaffoldMessenger 注入
  - `PlatformApp.builder` 包含 `ScaffoldMessenger`，在 `CupertinoApp` 下呼叫 `ScaffoldMessenger.of(context)` 正常運作不報錯。
- **AC-2**：提示訊息完整遷移
  - 登入成功、註冊成功、登入失敗與收藏切換均以 Material 3 風格的 `SnackBar` 顯示。
  - 呼叫新 SnackBar 前清除前一則（`hideCurrentSnackBar()`），防止訊息堆疊延遲。
- **AC-3**：依賴庫乾淨移除
  - `pubspec.yaml` 移除 `fluttertoast`，`flutter pub get` 與編譯完全無礙。
- **AC-4**：測試全綠
  - 單元測試與 Widget 測試 100% 通過。
