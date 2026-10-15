# 實作計畫：UI-9.2 fluttertoast 遷移至 SnackBar（含 ScaffoldMessenger 補齊）

- **建立日期**：2026-10-15
- **對應規格**：`docs/features/2026-10-15-ui-9-2-migrate-fluttertoast-to-snackbar.md`
- **狀態**：等待確認 (Pending Confirmation)

---

## 1. 簡介與目標 (Overview & Goals)

落實功能項目 `UI-9.2`：
1. **補齊 ScaffoldMessenger**：於 `lib/main.dart` 的 `PlatformApp.builder` 注入全域 `ScaffoldMessenger`，確保 Material 與 Cupertino 分支皆具備 SnackBar 支援。
2. **遷移提示訊息至 SnackBar**：將 `sign_in_page.dart` 與 `restaurant_detail_page.dart` 中的 4 處 Toast 提示全數轉換為 Material 3 SnackBar。
3. **移除淘汰相依**：徹底自 `pubspec.yaml` 移除 `fluttertoast`，消滅 macOS 平台未實作警告與潛在 AGP 建置包袱。

---

## 2. 檔案異動清單 (File Changes)

### 2.1 新增檔案
- `lib/features/foundation/extension/snackbar_extension.dart`：封裝 `BuildContext.showAppSnackBar(String message)` 擴充方法。
- `test/features/foundation/extension/snackbar_extension_test.dart`：針對 SnackBar 擴充方法之 Widget 測試（含 Cupertino 與 Material 容器驗證）。

### 2.2 修改檔案
- `lib/features/foundation/extension/extension_barrel.dart`：匯出 `snackbar_extension.dart`。
- `lib/main.dart`：於 `PlatformApp.builder` 注入 `ScaffoldMessenger`。
- `lib/flow/signinup/view/sign_in_page.dart`：將 `Fluttertoast.showToast` 改為 `context.showAppSnackBar`，移除套件導入。
- `lib/flow/restaurant/view/restaurant_detail_page.dart`：將 `Fluttertoast.showToast` 改為 `context.showAppSnackBar`，移除套件導入。
- `pubspec.yaml`：移除 `fluttertoast: ^9.1.0` 相依。

---

## 3. 實作任務拆分 (Tasks)

### 任務 1：全域 ScaffoldMessenger 注入與 SnackBar 擴充函式
- **內容**：
  - 在 `lib/features/foundation/extension/snackbar_extension.dart` 定義 `extension BuildContextSnackBarX on BuildContext`，實作 `showAppSnackBar(String message)`，自動調用 `hideCurrentSnackBar()` 與 `showSnackBar(SnackBar(content: Text(message)))`。
  - 在 `lib/features/foundation/extension/extension_barrel.dart` 匯出。
  - 在 `lib/main.dart` 的 `builder:` 內包覆 `ScaffoldMessenger(child: scrollable)`。
- **驗證**：語法與型別檢查無誤。

### 任務 2：遷移 Sign-In 與 Restaurant Detail 頁面的 Toast 呼叫
- **內容**：
  - `lib/flow/signinup/view/sign_in_page.dart`：
    - 登入成功：`context.showAppSnackBar(S.current.signin_success_msg)`
    - 註冊成功：`context.showAppSnackBar(S.current.email_signup_success_hint_msg)`
    - 登入失敗：`context.showAppSnackBar(state.reason.localizedMessage)`
    - 移除 `import 'package:fluttertoast/fluttertoast.dart';`
  - `lib/flow/restaurant/view/restaurant_detail_page.dart`：
    - 收藏切換：`context.showAppSnackBar(favorToggleMsg)`
    - 移除 `import 'package:fluttertoast/fluttertoast.dart';`
- **驗證**：編譯通過，呼叫端乾淨無殘留。

### 任務 3：自 pubspec.yaml 移除 fluttertoast 相依
- **內容**：
  - 自 `pubspec.yaml` 刪除 `fluttertoast: ^9.1.0`。
  - 執行 `flutter pub get`。
- **驗證**：依賴解析正常，全專案無任何 `fluttertoast` 符號引用。

### 任務 4：編寫測試與回歸驗證
- **內容**：
  - 撰寫 `test/features/foundation/extension/snackbar_extension_test.dart`，驗證在 `CupertinoApp` 及 `MaterialApp` 環境下調用 `showAppSnackBar` 皆能正確渲染 `SnackBar` 且不拋異常。
  - 執行 `flutter analyze .`。
  - 執行 `flutter test`，確保既有 316+ 個測試全綠。

---

## 4. 驗收標準 (Acceptance Criteria)

1. `pubspec.yaml` 不再包含 `fluttertoast`，專案內無任何 `Fluttertoast` 符號。
2. `PlatformApp.builder` 具備 `ScaffoldMessenger`，CupertinoApp 分支呼叫 SnackBar 零崩潰。
3. 測試套件 100% 通過，靜態分析 0 警告。
