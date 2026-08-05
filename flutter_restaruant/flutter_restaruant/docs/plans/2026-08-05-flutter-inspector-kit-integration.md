# F-0.1 — 整合 `flutter_inspector_kit` · 實作計畫

> STAGE 0b：How（資料結構、檔案異動、任務拆分）
> 規格來源：`docs/features/2026-08-05-flutter-inspector-kit-integration.md`（§4 範圍與 §3 AC 已由使用者拍板，本計畫不推翻）
> 撰寫日期：2026-08-05
> 基準 commit：`2890610`（branch `main`）
> 基準線實測：`flutter analyze` → `No issues found!`（已複驗）

---

## 0. 規格勘誤（實作前必讀）

實地複驗程式碼與 pub.dev metadata 後，發現規格書兩處記載與現況不符。**兩處都會直接改變實作方式**，故列在最前面。

### 0.1 🔴 勘誤 A：Dart SDK 下界不相容（規格 §5.2 記為「🟢 相容」，實為需修改）

`flutter_inspector_kit 1.9.0` 的 pubspec（pub.dev API 實測）：

```yaml
environment:
  sdk: "^3.10.1"      # 即 >=3.10.1 <4.0.0
  flutter: ">=3.10.0"
```

本專案 `pubspec.yaml:11` 為 `sdk: '>=3.5.0 <4.0.0'`。下界 `3.5.0 < 3.10.1`，**`flutter pub get` 會直接解不開**。

**緩解成本為零**：`pubspec.lock` 現已解析為 `dart: ">=3.11.0 <4.0.0"`，代表既有傳遞相依早已要求 3.11+，`3.5.0` 這個下界只是沒人維護的過時宣告。本機環境 Dart 3.11.5 / Flutter 3.41.9，滿足所有條件。

**處置**：T1 一併把 `pubspec.yaml:11` 提升為 `sdk: '>=3.10.1 <4.0.0'`。這是**追認既成事實**，非擴大範圍。

### 0.2 🔴 勘誤 B：Dio 接線點不在 `dio_client.dart`，而在 `api_clz.dart:42`

規格 §1.3 接線點 2 記為「`dio_client.dart:24`、`:29` 已有掛載點，沿用即可」。實測後這個判斷**不成立**：

| 事實 | 位置 | 後果 |
| :--- | :--- | :--- |
| `DioClient` 是**泛用容器**，不知道自己被誰用 | `lib/api/dio/dio_client.dart:4-35` | 在此硬塞 inspector 等於讓通用類別依賴 debug 工具，是錯的抽象層 |
| 實際被 DI 註冊的 `dioClient` 是 `api_clz.dart:42` 的**頂層 `final`** | `lib/api/api_clz.dart:42-54` | `injection.dart:12` 只是 `() => dioClient`，**沒有建立 Dio 的權力**；DI 層不是接線點 |
| `interceptWraps` 型別是 `List<InterceptorsWrapper>?` | `dio_client.dart:11` | `FlutterInspectorDioInterceptor extends Interceptor`（實測套件原始碼），**不是** `InterceptorsWrapper`，型別不符，無法從既有參數傳入 |
| 既有 auth header 由 `InterceptorsWrapper` 在 `api_clz.dart:46-53` 注入 | 同上 | inspector 必須排在**它之後**才錄得到真實 header（DS-2 / AC-2 的核心訴求） |

**處置**：接線改在 `api_clz.dart:42` 的 `dioClient` 初始化式旁，於 `dioClient` 建立**後**追加一行 `dio.interceptors.add(...)`。`dio_client.dart` **完全不動**——這反而更貼合規格 §4.2「不寫包裝抽象層」的原則。

> **這不是擴大範圍**：接線點數量仍是 4 個，只是其中一個的實際座標與規格書的記載不同。規格 §4.1 的四件事一件不多一件不少。

---

## 1. 實作策略總覽

**一句話**：加 1 個相依、提 1 行 SDK 下界、在 4 個既有位置各加一段 `kDebugMode` 分支，然後花力氣證明 release 裡什麼都沒有。

**核心資料結構**：一個 `FlutterInspector?` 型別的**頂層可空變數**，debug 時為實例、release 時恆為 `null`。全專案只有這一個持有點。

```
T1 相依與 SDK ─→ T2 inspector 持有點 ─┬─→ T3 Dio 接線 ────┐
   (pubspec)        (inspector.dart)   │   (api_clz.dart)  ├─→ T5 靜態驗證 ─→ T6 release 硬驗證
                                       └─→ T4 App 接線 ────┘     (AC-7/8/10)     (AC-4/5/6/9)
                                           (main.dart)
```

**並行性**：T3（`lib/api/api_clz.dart`）與 T4（`lib/main.dart`）寫入路徑完全不重疊，**可完全並行**。T1 → T2 → {T3, T4} 為強制序列（T3/T4 都要 import T2 產出的符號；T2 要 import T1 引入的套件）。T5 必須等 T3/T4 都完成。T6 是人工驗證，必須最後做。

---

## 2. 設計判斷

### 2.1 🔴 `kDebugMode` 的包法：**單一 nullable 持有點 + 呼叫端 null 檢查**

規格 §3.2 把這題列為 STAGE 0b 待決事項。三個候選：

| 方案 | 作法 | 判定 |
| :--- | :--- | :---: |
| **A. no-op stub** | 定義 `abstract class Inspector`，debug 註冊真實實作、release 註冊空實作 | ❌ |
| **B. 每個呼叫端各包 `if (kDebugMode)`**，各自 `FlutterInspector()` | 四處各建一個實例 | ❌ |
| **C. 單一頂層 `FlutterInspector?`，debug 賦值、release 為 `null`** | 呼叫端用 `?.` / null 檢查 | ✅ **採用** |

**否決 A 的理由**：規格 §4.2 明文「單一實作的抽象層是純負債」。而且 stub 方案**做不到 AC-6**——release 若仍註冊一個 stub，`FlutterInspector` 這個型別名仍可能被 interface 的型別宣告牽連進 bundle。抽象層在這裡不只是多餘，是**反效果**。

**否決 B 的理由**：`FlutterInspector` 內部持有 buffer（實測建構子有 `bufferSize: 500` 與 `InspectorRegistry`）。四個實例代表 Dio 錄到的請求跟 Navigator 錄到的導航**進不了同一個 dashboard**，AC-2 與 AC-3 會同時失敗。這是設計錯誤，不只是浪費。

**採用 C 的具體結構**（新檔 `lib/di/inspector.dart`）：

```dart
// 形狀示意，非最終程式碼
import 'package:flutter/foundation.dart';
import 'package:flutter_inspector_kit/flutter_inspector_kit.dart';

/// Debug-only 除錯工具實例。release build 中恆為 `null`，
/// 所有引用點因此成為 dead code 而被 tree-shaking 移除。
final FlutterInspector? inspector = kDebugMode ? FlutterInspector(...) : null;
```

**為什麼這樣就能達成 tree-shaking（AC-6）**：`kDebugMode` 是 `const bool`，Dart AOT 編譯器在 release 下把 `kDebugMode ? X : null` 常數摺疊為 `null`，`FlutterInspector(...)` 建構呼叫成為不可達程式碼；沒有任何地方構造該型別，其 `openDashboard` → `DashboardModal.show` 的整條 UI 呼叫鏈全部失去進入點，被 tree-shaker 摘除。

**為什麼不放 GetIt**：GetIt 是**執行期**註冊表，`getIt<T>()` 以 `Type` 為鍵做動態查表——這正好是 tree-shaker **無法**證明不可達的模式，等於親手保留 dashboard 符號，直接威脅 AC-6。頂層 `final` 是編譯期可見的，這裡「不用 DI」比「用 DI」更正確。同時也避免動到 `test/di_test.dart` 的斷言集合。

> **`ponytail:`** 一個頂層可空變數 + 三個 null 檢查，取代抽象層/工廠/DI 註冊。這是能同時滿足 AC-2、AC-3、AC-6 的最短結構。

### 2.2 為什麼呼叫端仍要**顯式** `if (kDebugMode)`（而非只靠 `?.`）

規格 §5.1 緩解手段 1 明訂「四個接線點無一例外必須位於 `kDebugMode` 判斷之內」。單靠 `inspector != null` 在語意上等價，但：

1. **可審閱性**：AC-5 的驗證方式是「檢視 release 路徑的接線是否全數位於 `kDebugMode` 判斷之內」。`grep kDebugMode` 要能一次撈出全部四處，這是驗收動作本身的需求。
2. **抵禦未來的漏包**（§5.1 殘餘風險）：日後有人把 `inspector` 誤改為非空，`if (kDebugMode)` 仍是第二道防線。

**結論**：`main.dart` 的兩處接線用 `if (kDebugMode)` 明寫；`api_clz.dart` 因為在頂層初始化式中，同樣以 `if (kDebugMode)` 起手。四處 grep 得到，零例外。

### 2.3 建構子參數的取捨（2026-08-05 修訂：使用者明確要求開啟四項 debug 專屬功能）

實測套件建構子有 13 個參數。規格 §4.2 明文「先用套件預設值」，原始判定為「幾乎全用預設值」；使用者事後複查要求開啟 `showNetworkNotification`／`captureUncaughtErrors`／`captureLifecycleEvents` 並關閉 `redactSensitiveData`，逐項改判如下：

| 參數 | 預設 | 決定 | 理由 |
| :--- | :--- | :--- | :--- |
| `slowRequestThreshold` | `2s` | **顯式設 `2s`** | DS-1 要證明「2 秒假延遲是多餘的」。閾值恰好對齊該數字，讓超標請求一眼可見。雖與預設同值，顯式寫出是**意圖宣告** |
| `redactSensitiveData` | `true` | **改為 `false`（2026-08-05 二次修訂：更正理由）** | ~~原理由「debug 時 Network 分頁完整顯示敏感欄位，不遮蔽」不成立~~：實測套件原始碼（`network_detail_view.dart:66`）確認**畫面顯示從未受此旗標影響**，headers 一律原樣顯示。此旗標唯一作用的是**匯出/分享/複製到剪貼簿**路徑（`buildCurl`／`buildPlainText`／`export_report_sheet.dart` 的 `redact:` 參數）。使用者已知悉此範圍後仍要求 `false`：**確實需要匯出/分享診斷報告時也不遮蔽敏感欄位**，是明確的知情決定，非除錯畫面需求。整個建構子仍在 `kDebugMode` 分支內，release 恆為 `null`，不影響 AC-9；§5.1 R-1 的「第二道防線」因此收斂為單靠 `kDebugMode` guard，殘餘風險見下方新增說明 |
| `showNetworkNotification` | `false` | **改為 `true`** | 使用者要求 debug 時網路請求跳系統通知。僅在 `kDebugMode` 分支內生效，release 不受影響，AC-9 不成立的風險僅限「debug build 需要通知權限」，不涉及 release 行為 |
| `navigatorKey` | `null` | **改為傳入 `main.dart` 既有的 `navigatorKey`** | 未設定時 `showNetworkNotification` 的 tap-to-open 為 no-op（套件 `_openNetworkFromNotification` 對 `null` context 直接返回）。既然通知已開啟（見上一列），點通知應能實際開啟 dashboard，故沿用 app 既有的 `GlobalKey<NavigatorState>`（`lib/main.dart:21`，已是 `PlatformApp.navigatorKey`），`lib/di/inspector.dart` 以 `import '../main.dart' show navigatorKey;` 取得，不新增第二把 key |
| `captureUncaughtErrors` | `false` | **改為 `true`** | 使用者要求 debug 時攔截未捕捉例外。已查證套件原始碼（`uncaught_error_handler.dart`）：`FlutterError.onError`／`PlatformDispatcher.onError`／`ErrorWidget.builder` 三處皆為 **chain/wrap**、非 override——記錄後接續呼叫原有 handler。且本專案未設定任何全域 error handler，無衝突可能。規格 §5.4「不劫持宿主錯誤處理」的安心前提由套件的 chain 機制保證，非規則本身禁止開啟 |
| `captureLifecycleEvents` | `false` | **改為 `true`** | 使用者要求 debug 時記錄生命週期事件。套件用 `WidgetsBinding.addObserver`，本就支援多 observer 並存，不影響既有生命週期邏輯 |
| `magicalTapCount` | `5` | **不動** | 5 連點的誤觸機率已足夠低 |
| 其餘（`customTab` 等） | — | **不動** | 無需求 |

> **範圍仍受 `kDebugMode` 單一分支界定**：四項改動全部發生在 `FlutterInspector(...)` 建構子內部，該建構子本身只在 `kDebugMode == true` 時才會被求值（見 §2.1），release 恆為 `null`。因此本次修訂不影響 AC-4／AC-6／AC-9 的 release 安全性，僅改變 debug build 的除錯資訊豐富度。
>
> **殘餘風險更新**：`redactSensitiveData: false` 拿掉的是「匯出/分享/剪貼簿路徑即便漏進 release 仍遮蔽」這道防線（畫面顯示本就不受此旗標影響，見上表更正後的理由），現在完全依賴 `kDebugMode` guard 這唯一一層。此風險與 §6 R-1 的既有殘餘風險描述（「未來新增接線點可能漏包」）性質相同，緩解手段不變：T5 的 `grep kDebugMode` 接線點齊全檢查、T6 的實機硬驗證。額外殘餘風險：即使 `kDebugMode` guard 正常運作，debug build 中使用者若把匯出的診斷報告（含未遮蔽的 `Authorization` 等敏感欄位）分享到外部管道（issue、聊天工具），內容本身仍是明碼——這是使用者已知情並接受的取捨，非本功能的安全缺陷。

### 2.4 Dio 攔截器的**插入順序**

`api_clz.dart:45-54` 的 `interceptWraps` 注入 `Authorization` header。dio 的 `onRequest` 依 `interceptors` 順序執行，因此：

```
LogInterceptor (dio_client.dart:24, isLogEnabled 預設 true)
  → InterceptorsWrapper (注入 Authorization)      ← api_clz.dart:46
    → FlutterInspectorDioInterceptor              ← 必須在這個位置
```

若排在 auth wrapper **之前**，錄到的 `requestHeaders` 會缺少 `Authorization`，**DS-2 與 AC-2 直接失敗**。由於 `DioClient` 建構子內部先 `.add(LogInterceptor)` 再 `.addAll(interceptWraps)`，只要在 `dioClient` **建構完成後**追加 `.add(...)`，順序自然正確——這也是勘誤 B 選擇「建構後追加」而非「傳參進去」的另一個理由。

`sourceDio:` 參數傳 `dioClient.dio`（實測簽章 `FlutterInspectorDioInterceptor(this._inspector, {this.sourceDio})`，用途為 request replay）。

### 2.5 `main.dart` 的接線形狀

- **`navigatorObservers`**：`PlatformApp` 目前未使用此參數（實測 `main.dart:51-82` 確認）。新增 `navigatorObservers: kDebugMode && inspector != null ? [inspector!.navigatorObserver] : const []`。
  > **`!` 的正當性**：專案 style guide 禁止無法證明非空的 `!`。此處 `inspector != null` 已在同一表達式中證明，屬 Dart 型別提升可接受範圍；但為徹底避免 lint 摩擦，**優先採用區域變數提升**寫法（見 T4 描述）。
- **喚起手勢**：既有 `builder:` 回傳 `Theme(data:..., child: child ?? const SizedBox.shrink())`。改為在 debug 時把 `Theme(...)` **再包一層** `FlutterInspectorMagicalTap`。實測其簽章為 `FlutterInspectorMagicalTap({required this.child, required this.onTap, this.tapCount = 5, this.timeout = ...})`——`child` 與 `onTap` 皆為 **required named**。內部是 `GestureDetector(behavior: HitTestBehavior.translucent)`，不吃掉子樹的點擊事件，對 AC-9 無影響。

  **🔴 已修正的錯誤判斷（原文保留刪除線以留紀錄）**：~~`onTap` 回呼需要的 `context` 來自 `builder` 的第一個參數，而 dashboard 需要能找到 `Navigator`——`builder` 的 context 位於 `Navigator` 之下，可用。~~ 此判斷**錯誤**：`PlatformApp.builder` 的 `context` 語意上位於 `Navigator` **之上**（`builder` 存在的目的正是包裹整個 Navigator 樹的外殼），`openDashboard` 內部呼叫 `showGeneralDialog(context: context, ...)` 需要往上解析 `NavigatorState`，用這個 context 會在每次觸發時丟 `Navigator operation requested with a context that does not include a Navigator` assertion error。**實際修法**：改用 `navigatorKey.currentContext`（`NavigatorState` 自身的 context，位於 `Navigator` 之下）取代 `builder` 傳入的外層 `context`。

- **常駐 FAB（2026-08-05 新增，與五連點並存；2026-08-05 修訂接線位置）**：套件另提供 `FlutterInspector.attach({required BuildContext context, bool visible = true})`，把可拖曳的 `InspectorFab` 插入最近的 `Overlay`。這是**命令式** API（非 declarative widget），且同樣需要位於 `Overlay`（隨 `Navigator` 建立）之下的 context，與喚起手勢踩到同一個「`builder` context 位置不對」的坑。原始版本放在 `main()` 的 `runApp(...)` 之後用 `navigatorKey.currentContext`；**改為放在 `lib/flow/splash/view/splash_page.dart` 的 `_SplashPageState.initState()` 既有 `addPostFrameCallback` 回呼的最後**——`SplashPage` 本身是 `routes` 表掛載的路由 widget，其 `build(context)` 的 `context` 天生位於 `Navigator`/`Overlay` 之下，比 `navigatorKey.currentContext`（時序上更早、依賴 key 是否已附著）更直接可靠，且該頁面本就有 `addPostFrameCallback` 可複用，不需在 `main.dart` 額外起一個回呼。呼叫本身冪等（`_overlayEntry != null` 時 no-op），不需要 `detach()`——app 存活期間 FAB 常駐是預期行為。

---

## 3. 檔案異動清單

| # | 檔案 | 位置 | 動作 |
| :---: | :--- | :--- | :--- |
| 1 | `pubspec.yaml` | `:11` | `sdk: '>=3.5.0 <4.0.0'` → `'>=3.10.1 <4.0.0'`（勘誤 A） |
| 2 | `pubspec.yaml` | `dependencies:` 末段（`crypto: ^3.0.3` 之後，`# Standard Flutter SDK` 註解之前，約 `:71-72`） | 新增註解區塊 `# 開發除錯工具 (Developer Tooling — debug only)` + `flutter_inspector_kit: ^1.9.0` |
| 3 | **`lib/di/inspector.dart`**（新檔） | — | 頂層 `final FlutterInspector? inspector = kDebugMode ? FlutterInspector(slowRequestThreshold: const Duration(seconds: 2)) : null;` + doc comment |
| 4 | `lib/di/di_barrel.dart` | `:1` 之後 | 新增 `export 'inspector.dart';` |
| 5 | `lib/api/api_clz.dart` | import 區、`:42-55` 之間 | `dioClient` 建立後、`apiInstance` 建立前，插入 `kDebugMode` 分支呼叫 `dioClient.dio.interceptors.add(FlutterInspectorDioInterceptor(inspector!, sourceDio: dioClient.dio))` 的等價安全寫法 |
| 6 | `lib/main.dart` | `:52` 附近（`navigatorKey:` 之後） | 新增 `navigatorObservers:` 參數 |
| 7 | `lib/main.dart` | `:79-82` `builder:` | `_` → `context`，debug 時外包 `FlutterInspectorMagicalTap`；`onTap` 用 `navigatorKey.currentContext`（非 `builder` 傳入的 `context`，見 §2.5 已修正的錯誤判斷） |
| 8 | `lib/flow/splash/view/splash_page.dart`（2026-08-05 新增） | `_SplashPageState.initState()` 既有 `addPostFrameCallback` 回呼最後 | `inspector.attach(context: context)`，掛上常駐 FAB；`context` 為 `SplashPage` 自身、已在 Navigator/Overlay 之下（見 §2.5） |

**不動的檔案**（明確聲明，避免 implementer 誤觸）：
- ❌ `lib/api/dio/dio_client.dart` — 勘誤 B 已說明理由，`LogInterceptor` 一併保留（規格 §4.2）
- ❌ `lib/di/injection.dart` — §2.1 已說明不走 GetIt
- ❌ `test/` 下任何檔案 — 規格 §4.2「不為 inspector 本身寫測試」
- ❌ `lib/features/foundation/constants/constants.dart` — 規格 §4.2「不順便修既有缺陷」

**平台設定**：`share_plus`（唯一新增傳遞相依）在 iOS/Android 上為純 Dart + 標準 platform channel，**無需**手動改 `AndroidManifest.xml` 或 `Info.plist`。若 `flutter build` 報缺設定，才依錯誤訊息處理（屬 T6 的例外處置，不預先做）。

---

## 4. 任務拆分

> 複雜度分級依 `gen-dev-workflow` STAGE 2 判準：
> **快/便宜** = 觸及 1-2 檔案且規格完整、機械性 ｜ **標準** = 觸及多檔需整合協調 ｜ **最強推論** = 需設計判斷或廣泛理解

### T1 — 引入相依並提升 SDK 下界

| 項目 | 內容 |
| :--- | :--- |
| **觸及檔案** | `pubspec.yaml`（+ 產出的 `pubspec.lock`） |
| **複雜度** | 🟢 **快/便宜** |
| **對應 AC** | 前置（R-2 的早期失敗信號） |
| **並行性** | 無法並行，所有任務的前置 |

**動作**：
1. `pubspec.yaml:11` → `sdk: '>=3.10.1 <4.0.0'`
2. `crypto: ^3.0.3`（`:71`）之後新增：
   ```yaml
   # 開發除錯工具 (Developer Tooling — debug only)
   flutter_inspector_kit: ^1.9.0 # App 內除錯儀表板 (網路/導航/日誌)，全數以 kDebugMode 圍住
   ```
   > 放 `dependencies:` 而非 `dev_dependencies:` 是**必要**的：`dev_dependencies` 不會被打包進 app，`lib/` 下的程式碼無法 import。安全性由 `kDebugMode` + tree-shaking 保證（§2.1），不靠相依區塊分類。

**驗收**：`flutter pub get` 成功結束；`pubspec.lock` 出現 `flutter_inspector_kit` 與 `share_plus`。
**失敗處置**：若版本解不開，**立即停下回報**，不要自行放寬其他套件版本（R-2 的早期可見失敗）。

---

### T2 — 建立 inspector 唯一持有點

| 項目 | 內容 |
| :--- | :--- |
| **觸及檔案** | `lib/di/inspector.dart`（新）、`lib/di/di_barrel.dart` |
| **複雜度** | 🟢 **快/便宜**（設計判斷已在本計畫 §2.1/§2.3 定案，實作為機械性） |
| **對應 AC** | AC-5、AC-6（結構性前提）、AC-7、AC-10 |
| **並行性** | 依賴 T1；為 T3/T4 的前置 |

**動作**：新建 `lib/di/inspector.dart`，內容為 §2.1 的形狀，`slowRequestThreshold` 依 §2.3 顯式設為 `const Duration(seconds: 2)`，其餘參數全用預設。加繁體中文 doc comment 說明「release 恆為 null」與該設計的 tree-shaking 理由。於 `di_barrel.dart` 加一行 export。

**驗收**：`flutter analyze` 零警告。

---

### T3 — Dio 攔截器接線

| 項目 | 內容 |
| :--- | :--- |
| **觸及檔案** | `lib/api/api_clz.dart` |
| **複雜度** | 🟡 **標準**（單一檔案，但需正確處理頂層初始化順序與攔截器排序，見 §2.4） |
| **對應 AC** | AC-2、AC-5 |
| **並行性** | ✅ **可與 T4 完全並行**（寫入路徑不重疊） |

**動作**：在 `api_clz.dart` 的 `dioClient`（`:42`）與 `apiInstance`（`:55`）之間，用「先取得已建構的 dio、再條件式追加攔截器」的方式接線。因頂層 `final` 不能放語句，採用 IIFE 形式的初始化式（與 `dio_client.dart:12`、`:20` 專案既有慣例一致）或把攔截器追加移入既有的 `dioClient` 初始化鏈——**由 implementer 擇一，但必須滿足**：

1. inspector 攔截器排在 auth `InterceptorsWrapper` **之後**（§2.4）
2. 整段以 `if (kDebugMode)` 圍住，`grep kDebugMode lib/api/api_clz.dart` 撈得到
3. `apiInstance` 建立時攔截器已就位（`apiInstance` 引用 `dioClient.dio`，兩者共用同一 `Dio`，順序不影響正確性，但避免 lazy 初始化順序陷阱：確保追加動作屬於 `dioClient` 的初始化式而非獨立頂層語句）
4. 不使用未經證明的 `!`（用區域變數提升）

**驗收**：`flutter analyze` 零警告；T6 中 AC-2 實跑通過。

---

### T4 — `PlatformApp` 接線（observer + 喚起手勢）

| 項目 | 內容 |
| :--- | :--- |
| **觸及檔案** | `lib/main.dart` |
| **複雜度** | 🟡 **標準**（兩處接線 + `PlatformApp` 跨平台雙分支語意 + null-safety 寫法約束） |
| **對應 AC** | AC-1、AC-3、AC-4、AC-5、AC-9 |
| **並行性** | ✅ **可與 T3 完全並行** |

**動作**：
1. import 區加 `package:flutter/foundation.dart`（取 `kDebugMode`）。`di/di_barrel.dart` 已在 `:10` import，`inspector` 隨 T2 的 export 自動可見，**不需新增 import**。
   > 注意：`main.dart:4` 已 import `package:flutter/material.dart`，它**不會**傳遞出 `kDebugMode`（`kDebugMode` 在 `foundation.dart`，而 `material.dart` 確實 re-export `foundation.dart`）。實作時若 analyze 報 unused import 則移除該行——以 analyze 結果為準，不預設。
2. `navigatorKey:`（`:52`）之後加 `navigatorObservers:`，debug 且非 null 時給 `[inspector.navigatorObserver]`，否則 `const []`。
3. `builder:`（`:79`）的 `_` 改為 `context`；回傳值在 debug 時外包 `FlutterInspectorMagicalTap(onTap: () => inspector.openDashboard(context), child: Theme(...))`，release 維持原本的 `Theme(...)`。**`Theme` 必須在內層**（§2.5）。

**寫法約束**：為避免 `!` 與重複條件，建議先在 `build` 內取 `final ins = kDebugMode ? inspector : null;` 做型別提升，後續用 `ins == null ? 原樣 : 包一層`。

**驗收**：`flutter analyze` 零警告；T6 中 AC-1/AC-3 實跑通過；Android 與 iOS 兩個分支外觀皆無變化（AC-9）。

---

### T5 — 靜態驗證

| 項目 | 內容 |
| :--- | :--- |
| **觸及檔案** | 無（唯讀 + 可能的格式化） |
| **複雜度** | 🟢 **快/便宜** |
| **對應 AC** | AC-7、AC-8、AC-10，以及 AC-5 的程式碼審閱部分 |
| **並行性** | 必須等 T3 與 T4 皆完成 |

**動作**：執行 §5.1 的全部指令，任一不過即退回對應任務。

---

### T6 — Release 硬驗證（🔴 不可妥協）

| 項目 | 內容 |
| :--- | :--- |
| **觸及檔案** | 無（build 產物） |
| **複雜度** | 🔴 **最強推論**（需判讀 build 產物、判斷符號殘留是否為真陽性、評估行為差異） |
| **對應 AC** | **AC-4、AC-5、AC-6**（硬性）+ AC-9 |
| **並行性** | 最後執行，不可並行 |

**動作**：執行 §5.2 的全部步驟。**任一不過 → 不得合併**（規格 §3.2）。

---

## 5. 驗證步驟

### 5.1 靜態驗證（T5）

```bash
# AC-10 — 格式（範圍限定本功能異動檔案，避免把 base branch 既有格式化落差一併掃入 diff）
dart format --set-exit-if-changed lib/di/inspector.dart lib/di/di_barrel.dart lib/api/api_clz.dart lib/main.dart

# AC-7 — 靜態分析必須維持 "No issues found!"（基準線已實測為零警告）
rtk flutter analyze

# AC-8 — 既有 14 個測試檔全綠
rtk flutter test

# AC-5（程式碼審閱面）— 五個接線點必須全部 grep 得到 kDebugMode
# （2026-08-05 修訂：新增 FAB 進入點後由 4 處增為 5 處，見 §2.5）
rtk proxy grep -rn "kDebugMode" lib/di/inspector.dart lib/api/api_clz.dart lib/main.dart lib/flow/splash/view/splash_page.dart
# 預期：inspector.dart 1 處、api_clz.dart 1 處、main.dart 2 處（observer + builder）、
#       splash_page.dart 1 處（FAB attach）
# 少於 5 處 → 有接線點漏包，退回對應任務
```

### 5.2 Release 硬驗證（T6）

#### AC-6 — Tree-shaking 驗證（本計畫決定的具體指令）

Flutter release 的 Dart 程式碼編譯為 AOT 機器碼，**符號名不會以純文字保留**，直接 `strings` 掃 `.so` 不可靠（會有偽陰性）。採用**兩層驗證**：

**第一層（主要證據）— 對照 Dart AOT 的符號輸出**

```bash
# Android：產出 release APK 並輸出編譯後的符號地圖
rtk flutter build apk --release --split-debug-info=build/symbols-release

# 檢查 dashboard 的核心類別是否出現在符號地圖中
rtk proxy grep -ri "DashboardModal\|FlutterInspectorDashboard\|InspectorOverlayManager" build/symbols-release/ | head
# 預期：無輸出（0 筆）→ AC-6 通過
```

**第二層（對照組，證明檢測方法本身有效）**

```bash
# 對 debug 產物做同一檢查，必須「找得到」，否則代表上面的 grep 根本是無效檢查
rtk flutter build apk --debug
rtk proxy grep -ric "DashboardModal" build/app/intermediates/ 2>/dev/null | head
```

> **這一層不能省。** 一個永遠回傳 0 筆的檢查等於沒有檢查——AC-6 的價值取決於檢測方法被證明有辨識力。

**第三層（bundle 體積佐證）**

```bash
rtk flutter build apk --release --analyze-size --target-platform=android-arm64
# 於輸出中確認 flutter_inspector_kit 的 package 佔比。預期：不出現，或僅剩極小的 model 類別殘留
```

若第三層顯示 `flutter_inspector_kit` 佔用可觀體積，代表 tree-shaking **未生效**，須回頭檢查 §2.1 的 nullable 結構是否被破壞（最常見原因：有人把 `inspector` 改成非空、或把它塞進 GetIt/Map 等動態容器）。

**iOS 對應指令**（Android 通過後執行，兩平台皆須通過）：

```bash
rtk flutter build ios --release --no-codesign --split-debug-info=build/symbols-release-ios
rtk proxy grep -ri "DashboardModal\|InspectorOverlayManager" build/symbols-release-ios/ | head
```

#### AC-4 — Release 無進入點（🔴 必須實機驗證，不接受程式碼審閱）

```bash
rtk flutter install --release        # 或 flutter run --release 於實機
```

實機操作清單（逐項確認**無任何反應**）：

| # | 畫面 | 動作 | 預期 |
| :---: | :--- | :--- | :--- |
| 1 | 主列表 | 空白處 5 連點 | 無反應 |
| 2 | 餐廳詳情 | 空白處 5 連點 | 無反應 |
| 3 | 最愛 | 空白處 5 連點 | 無反應 |
| 4 | 設定 | 空白處 5 連點 | 無反應 |
| 5 | 任一畫面 | 全畫面掃視 | 無 FAB、無 overlay、無任何 debug 入口 |

#### AC-5 — Release 不註冊攔截器 / observer

由 §5.1 的 `grep kDebugMode` 四處齊全 + AC-4 實機無反應 + AC-6 符號不存在，三者共同構成證據。**不額外做**（規格 §4.2 排除 CI 自動化）。

#### AC-9 — Release 行為與外觀不變

同一台實機，整合前（`git stash` 或 `2890610` 的 build）與整合後的 release build，逐一比對：

| 流程 | 檢查點 |
| :--- | :--- |
| 餐廳搜尋 | 結果列表內容、載入時間主觀無差異 |
| 篩選 | 篩選標籤互動、結果更新 |
| 餐廳詳情 | 圖片、評論、地圖顯示 |
| 最愛 | 加入/移除、跨啟動持久化 |
| 訪客模式 | 登入引導行為 |
| 導航 | 全流程頁面切換無異常（**`navigatorObservers` 是唯一動到框架層的接線，重點觀察**） |
| 廣告 | Banner 正常顯示 |

#### AC-1 / AC-2 / AC-3 — Debug 功能驗證

```bash
rtk flutter run --debug
```

| AC | 步驟 | 通過標準 |
| :--- | :--- | :--- |
| AC-1 | 任一畫面空白處 5 連點 | dashboard modal 開啟 |
| AC-2 | 執行一次餐廳搜尋 → Network 分頁 | 找到 `/v3/businesses/search` 該筆，含 URL、method、狀態碼、**耗時**、request/response body，且 **request headers 含 `Authorization`**（驗證 §2.4 的攔截器順序正確；若被 `redactSensitiveData` 遮蔽為遮罩值，視為通過——欄位存在即滿足 DS-2） |
| AC-3 | 列表 → 詳情 → 返回 → Navigator 分頁 | 三筆導航事件（push / push / pop）齊全 |

---

## 6. 風險對應（規格 §5 → 實作落實）

### R-1 🔴 Inspector 進入 release（最大風險）

| 規格緩解手段 | 本計畫的具體落實 |
| :--- | :--- |
| `kDebugMode` guard 為強制設計約束 | **雙層**：①`lib/di/inspector.dart` 的 `kDebugMode ? ... : null` 讓 release 中實例根本不存在（§2.1）；②三個呼叫端各自顯式 `if (kDebugMode)`（§2.2）。任一層單獨即足夠，兩層同時失效才會出事 |
| 拒絕 GetIt 註冊 | §2.1 明確否決。GetIt 的 `Type`→`Object` 動態查表會阻止 tree-shaker 證明不可達，是 AC-6 的直接威脅 |
| 拒絕抽象層 / stub | §2.1 否決方案 A。單一實作的 interface 不只是負債，還會讓型別宣告把 dashboard 牽連進 bundle |
| AC-4～6 為合併前必過項 | T6 為獨立任務且標為不可妥協；§5.2 給出可執行指令 |
| 實機驗證非程式碼審閱 | §5.2 AC-4 的 5 項實機清單，明列「不接受程式碼審閱」 |
| 不因此延後缺陷 2 | 本計畫**不碰** `constants.dart`（§3 不動檔案清單）。硬編碼金鑰仍是獨立待辦，本功能不宣稱已緩解 |

**殘餘風險的實作層對應**：§5.1 提到「未來新增接線點可能漏包」。本計畫的 §5.1 驗證加入 `grep -rn kDebugMode` **並明列預期筆數為 4**——新增接線點時筆數不符會立刻暴露。這是零成本的紀律錨點，不違反 §4.2「不建 CI 自動化」。

### R-2 🟡 相依相容性

- **T1 為第一個任務且獨立驗收**：`flutter pub get` 失敗即刻停下，屬規格所稱「早期可見的失敗」。
- **勘誤 A 已把最可能的失敗點前移**：SDK 下界不合已在計畫階段查出，T1 一併處理，不會在實作中途才炸。
- `flutter_local_notifications ^22.1.0` 已是直接相依且主版本相同；`web` 已在 lock；唯一新增為 `share_plus`。
- AC-7 / AC-8 作為引入後的即時回歸信號（T5）。

### R-3 🟢 Debug 效能

**不做任何處理**（規格 §5.3 結論）。效能量測在 profile 模式進行，`kDebugMode` 為 `false`，`inspector` 為 `null`，不受影響。此處僅記錄：實作時**不得**因「怕慢」而加任何開關或設定——那是規格 §4.2 排除的「長期治理」。

### R-4 🟢 套件穩定性

- §2.3 明確**不開啟** `captureUncaughtErrors`，保證套件完全不觸碰宿主的 `FlutterError.onError` / `PlatformDispatcher.onError` / `ErrorWidget.builder`。這把規格 §5.4 的「chain 而非 override」進一步強化為「連 chain 都不做」。
- §2.3 **不開啟** `showNetworkNotification`，避免 `flutter_local_notifications` 的權限提示污染 AC-9。
- 移除成本：本計畫的異動集中在 1 個新檔 + 3 個既有檔的小段落，revert 成本等同一個小 PR（符合規格 §5.4 的預期）。

---

## 7. 執行方式選項

本計畫可用兩種方式推進，**建議 A**：

### A. Subagent-driven（建議）

單一 session，由 orchestrator 依序派發：

```
T1 (快/便宜) → T2 (快/便宜) → [T3 標準 ∥ T4 標準] → T5 (快/便宜) → T6 (最強推論)
```

- T3 與 T4 派給兩個並行 subagent（寫入路徑不重疊，無衝突風險）
- T6 需要人在場操作實機，orchestrator 在此**暫停**待人工回報
- **優點**：T1/T2 的相依與符號定義由同一上下文產出，T3/T4 拿到的是確定的 API 形狀，不會各自猜測
- **適用**：本任務總體積小（4 個檔案、約 30 行淨增），開 parallel session 的協調成本高於收益

### B. Parallel session

T3 與 T4 各開一個 session。**前提**：T1 + T2 必須已在 main 上完成並 commit，否則兩個 session 會各自對 `inspector` 的形狀做出不同假設。

- **適用**：若 T3 的 dio 頂層初始化寫法需要較長探索（§4 T3 的四項約束），與 T4 分離可避免互相等待
- **代價**：需要一次額外的 commit 同步點

**兩種方式都不改變**：T6 必須最後、單獨、由人工在實機執行。

---

## 8. 完成定義

對齊規格 §6：

1. ✅ AC-1～10 全數通過，其中 **AC-4～6 為不可妥協項**
2. ✅ DS-1 可實際執行：debug build 中 5 連點 → Network 分頁讀出 Yelp 搜尋的真實 round-trip 毫秒數
3. ✅ Release build 的行為、外觀與 bundle 內容與 `2890610` 無可觀測差異

**不包含**：任何 §1.2 缺陷的修復。溫度計裝好就該去量體溫（規格 §4.3）。
