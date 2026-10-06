# 功能規格：A-9.1 平台判斷 API 由 `dart:io` `Platform` 改為 `foundation` 編譯期常數

- **項目編號**：A-9.1（沿用 `docs/brainstorm/2026-09-30-features-brainstorm.md` §9.5 編號）
- **日期**：2026-10-07
- **Effort（brainstorm 估計）**：0.1d
- **相關脈絡**：§9.3-2（阻擋級問題）、§9.4.1（共用調整）、§9.5（共用前置清理）、§9.8（D-9.2 採 M-B 原生 macOS target、D-9.1 採 W-B 精簡 Web）

---

## 1. 問題陳述與影響 (What & Why)

### 1.1 核心問題

`lib/` 目前有 **6 處**使用 `dart:io` 的 `Platform`。`dart:io` 在 Web 平台不存在，任何求值到 `Platform.xxx` 的路徑在 Web 上會直接拋例外（§9.3-2 列為**阻擋級**）。實查證據（2026-10-07 覆核，與 brief 一致）：

| # | 檔案:行 | 用法 | 觸發時機 |
| :--- | :--- | :--- | :--- |
| 1 | `lib/features/utils/utils.dart:2,73` | `Platform.localeName` | `Utils.isLocaleZh()` 被呼叫時 |
| 2 | `lib/component/ad/banner_ad_state.dart:1,12` | `Platform.isAndroid` | 取 banner 廣告單元 ID |
| 3 | `lib/component/ad/interstitial_ad_state.dart:1,9` | `Platform.isAndroid` | 取插頁廣告單元 ID |
| 4 | `lib/component/ad/app_open_ad_state.dart:1,11` | `Platform.isAndroid` | **欄位初始化**（物件一建立即求值） |
| 5 | `lib/manager/fcm_manager.dart:3,109` | `Platform.isIOS` | `FcmManager.init()` |
| 6 | `lib/flow/signinup/view/third_party_sign_in_widget.dart:1,33` | `Platform.isIOS` | 登入頁 `build()` |

> 📌 **數量更正**：brainstorm §9.3-2 標題寫「5 處」但條列實為 6 個 file:line（3 個 ad 檔被併成一列）。本規格以實查的 **6 處 / 6 檔**為準。

### 1.2 第二個問題：Apple 登入在 macOS 上消失

`third_party_sign_in_widget.dart:33` 以 `Platform.isIOS` 當作「要不要顯示 Apple 登入按鈕」的判準（檔案 doc comment 亦寫「Apple 登入僅在 iOS 顯示」）。Sign in with Apple **macOS 原生支援**，§9.8/D-9.2 已決議採 M-B 原生 macOS target，因此此判準會造成「平台支援但按鈕不出現」——使用者在 macOS 上找不到自己既有的 Apple 帳號入口。這不是 Web 相容性問題，是**既有判準本身用錯了維度**（把「作業系統是 iOS」當成「支援 Apple 登入」）。

### 1.3 為什麼現在做

- §9.5 將 A-9.1 列為**共用前置清理**：不論是否擴平台本身就有價值，擴平台讓它變成必做。
- A-9.2（能力閘門集中化）在 §9.6 明確**依賴 A-9.1**：先讓平台判斷在全平台可編譯、可求值，閘門才有東西可讀。
- 專案**已有正解先例**，不需發明新寫法：
  - `lib/firebase_options.dart:5,19,25` 已用 `kIsWeb` + `defaultTargetPlatform`
  - `lib/main.dart:40` 已用 `ui.PlatformDispatcher.instance.locale`

### 1.4 零新增相依

`flutter/foundation.dart` 的 `kIsWeb` / `defaultTargetPlatform` / `TargetPlatform` 全平台可用，`PlatformDispatcher` 來自 `dart:ui`。相依盤點：

- `banner_ad_state.dart`、`interstitial_ad_state.dart` **已** `import 'package:flutter/foundation.dart'`
- ~~`fcm_manager.dart`、`third_party_sign_in_widget.dart` **已** `import 'package:flutter/material.dart'`（re-export `foundation`）~~
  🔴 **此前提經實作時實測證偽（2026-10-07 更正）**：`material.dart` 轉出 `widgets.dart`，而
  `widgets.dart:18` 是 `export 'foundation.dart' show Brightness, UniqueKey;`——**窄 export**，
  `defaultTargetPlatform` 不在其中。兩檔皆報 `Undefined name 'defaultTargetPlatform'`，
  實際都必須明確補 `import 'package:flutter/foundation.dart';`。
  連帶發現：`fcm_manager.dart` 原本只為 `debugPrint` 而 import `material.dart`，
  而 `foundation` 也提供 `debugPrint`，故 `material.dart` 變為冗餘（`unnecessary_import`）並一併移除。
- `app_open_ad_state.dart`、`utils.dart` 需補 import，但來源為 Flutter SDK 內建

> ⚠️ **給 A-9.2 / 後續平台工作的教訓**：不要假設 `material.dart` 或 `widgets.dart`
> 能取得 `foundation` 的全部符號。它們的 re-export 是 `show` 白名單，只放了極少數型別。
> 需要 `defaultTargetPlatform`、`kIsWeb`、`kDebugMode` 等時，一律明確 import `foundation.dart`。

6 檔的 `dart:io` **僅**用於 `Platform`（`File` / `Directory` / `Socket` / `HttpClient` / `Process` / `exit` 掃描結果全為 0）→ `import 'dart:io';` 可整行移除，不留殘用。

---

## 2. 使用者故事 (User Stories)

1. **作為 macOS 使用者**，我開啟 App 時它不應該因為平台判斷而崩潰或行為異常；我在登入頁應該看到「使用 Apple 登入」按鈕，因為 macOS 本來就支援它。
2. **作為 Web 使用者**（W-B 精簡版），我在瀏覽器開啟 App、進到首頁廣告位或登入頁時，不應該因為 `dart:io` 不存在而拿到白屏或例外。
3. **作為既有 Android／iOS 使用者**，這次改動後我感受不到任何差異——廣告照常投放對應平台的單元 ID、iOS 前景推播顯示設定照常生效、Apple 登入按鈕照常出現在 iOS 上。
4. **作為維護者**，`lib/` 不再有 `dart:io` 殘留，後續 E-9.2 的 `flutter build web` 編譯閘門才能真正把「新的 `dart:io` 滲入共用程式碼」擋在 CI。

### 受影響的使用情境

| 情境 | 現況 | 改動後 |
| :--- | :--- | :--- |
| Android／iOS 啟動、看廣告、收推播、登入 | 正常 | **語意完全不變**（見 §5.1） |
| macOS 登入頁 | Apple 按鈕不顯示 | **顯示**（刻意變更，見 §5.2） |
| Web 任一觸發點 | 拋例外 | 可求值、不拋例外（能否顯示廣告／推播由 A-9.2 決定，非本項範圍） |

---

## 3. 驗收條件 (Acceptance Criteria)

### 3.1 可機械驗證（必須全數通過）

在 `flutter_restaruant/flutter_restaruant` 目錄下執行：

```bash
# AC-1：lib/ 零 dart:io import —— 預期輸出 0
grep -rn --include="*.dart" "import 'dart:io'" lib/ | wc -l

# AC-2：lib/ 零 dart:io Platform 使用 —— 預期輸出 0
#        （排除 defaultTargetPlatform / TargetPlatform. / PlatformDispatcher /
#          PlatformApp / platformViewRegistry 這些合法的同字根識別字）
grep -rn --include="*.dart" -e "dart:io" -e "Platform\." lib/ \
  | grep -v "defaultTargetPlatform\|TargetPlatform\.\|PlatformDispatcher\|PlatformApp\|platformViewRegistry" \
  | wc -l

# AC-3：靜態分析零警告零錯誤
flutter analyze

# AC-4：既有測試全綠（行動版語意不變的回歸證據）
flutter test
```

- **AC-1** 預期 `0`（基線為 6）
- **AC-2** 預期 `0`（基線為 12 行：6 個 import + 6 個使用點）
- **AC-3** `No issues found!`
- **AC-4** 全部通過，且**不得**以修改既有測試期望值的方式達成（若某測試需要調整，必須在 STAGE 0b 的計畫中具名說明理由）

### 3.2 需人工／情境確認

- **AC-5**：`third_party_sign_in_widget` 在 **iOS 顯示** Apple 登入按鈕、在 **macOS 顯示** Apple 登入按鈕、在 Android 不顯示。判準表達為「iOS 或 macOS」。
- **AC-6**：`third_party_sign_in_widget.dart` 的類別 doc comment（現為「Apple 登入僅在 iOS 顯示」）須同步更新，否則註解與程式碼說法相反。
- **AC-7**：廣告單元 ID 的**值**一字未改（`Constants.adAndroidBannerId` 等常數與 `app_open_ad_state.dart` 的兩個字面值 ID 保持原樣），只換選擇它們的條件式。
- **AC-8**：不新增任何 `pubspec.yaml` 相依。

### 3.3 不納入本項驗收

- `flutter build web` / `flutter build macos` **是否成功**：本項只移除 `dart:io` 這一個阻擋因素；§9.3 還有 Yelp CORS（P0 Broker）、`firebase_options.dart` 的 `UnsupportedError`（A-9.3）、AdMob `MissingPluginException`（A-9.2/§9.3-3）等其他阻擋級問題未解。把 build 成功當驗收條件會讓本項無法收斂。

---

## 4. 範圍與邊界 (Scope & Boundaries)

### In Scope

- 上表 6 處平台判斷 API 的置換，以及隨之可整行移除的 6 個 `import 'dart:io';`
- `third_party_sign_in_widget.dart` 的 Apple 登入判準由「iOS」放寬為「iOS 或 macOS」，含該檔 doc comment 同步
- 必要時補上 `foundation.dart` / `dart:ui` import（2 檔）
- 🔄 **刪除 `Utils.isLocaleZh()`（2026-10-07 使用者授權，見 §4.1）**

### Out of Scope

- ❌ **A-9.2 能力閘門集中化**：本項不建立任何集中式平台能力判斷點，不改變「廣告在哪些平台初始化／顯示」的行為。本項只讓既有判斷式在全平台可求值。
- ❌ **新增抽象層**：不建立 `PlatformInfo` wrapper、不建 platform service、不新增 util 方法來包裝 `defaultTargetPlatform`。既有先例（`firebase_options.dart`）就是直接用，照做。
- ❌ **`firebase_options.dart`**：其 Web／macOS `UnsupportedError` 屬 A-9.3。
- ❌ **廣告單元 ID 的值**，以及 `app_open_ad_state.dart` 字面值 ID 應否抽成常數（屬既有技術債，非本項）。
- ❌ **新增相依**。
- ❌ **其他平台相關調整**（§9.4.1 的版面、BottomSheet、輸入、`fluttertoast`、`ChromeSafariBrowser`、App Check）。

### 4.1 範圍變更紀錄：`Utils.isLocaleZh()` 改為刪除（2026-10-07）

本規格初版將此方法列為 Out of Scope（保留方法、只換內部實作），理由是刪除屬行為／API 面決策，
超出 brief 授權的「只換平台判斷 API」。**使用者已於 2026-10-07 明確授權刪除**，故改列 In Scope。

| 項目 | 初版（保留置換） | 現行（刪除） |
| :--- | :--- | :--- |
| `utils.dart` 的 `import 'dart:io'` | 移除 | 移除（同） |
| `isLocaleZh()` 方法本體 | 保留，內部改 `PlatformDispatcher.instance.locale.languageCode == 'zh'` | **整個方法刪除** |
| 跨型別轉換風險（§5.1.1） | 存在，需具名測試 | **消失**——沒有置換就沒有轉換 |
| 待置換處數 | 6 處 | **5 處**（皆為布林等價） |
| 需新增 import | 2 檔（`foundation.dart` + `dart:ui`） | **1 檔**（`app_open_ad_state.dart` 的 `foundation.dart`；`utils.dart` 不再需要 `dart:ui`） |

**刪除的正當性**：`lib/` 與 `test/` 零呼叫（唯一出現處即定義本身，已 grep 證實），
屬死碼；Ponytail 階梯第 1 階「這需要存在嗎」→ 不需要。刪掉比置換更省，
且一併消除本項唯一的實質行為風險。

🔴 **STAGE 0b 須據此調整**：§5.1.1 的 `localeName` 跨型別測試負擔**取消**；
AC-1 基線仍為 6、AC-2 基線仍為 12（兩者皆為**刪除前**的現況實測值，不因本決策改變），
目標值同為 0——差別只在 `utils.dart` 那 2 行（1 import + 1 使用點）由「置換」改為「隨方法一起刪除」；
`utils.dart` 的任務從「置換」改為「刪方法 + 移 import」。
若 `dart:io` 移除後 `utils.dart` 有其他符號失去來源，須在 0b 計畫中註明（實查：該檔 `dart:io` 僅用於 `Platform`，故不會發生）。

---

## 5. 風險與破壞性評估 (Never break userspace)

### 5.1 行動版必須語意等價（鐵律）

本項是對**既有上線行動版行為**的改動，唯一可接受的結果是 Android／iOS 行為零差異。等價性論證：

| 原寫法 | 置換目標 | 行動版等價性 |
| :--- | :--- | :--- |
| `Platform.isAndroid` | `defaultTargetPlatform == TargetPlatform.android` | ✅ 在 Android 皆為 `true`、在 iOS 皆為 `false`。`defaultTargetPlatform` 為編譯期可判定常數，release build 可 tree-shake 死分支（符合 `.claude/rules/flutter-styles.md` §Y.3 的編譯期常數紀律） |
| `Platform.isIOS` | `defaultTargetPlatform == TargetPlatform.iOS` | ✅ 同上（注意 enum 值拼寫為 `iOS`，非 `ios`） |
| `Platform.localeName` | `PlatformDispatcher.instance.locale` | ⚠️ **非字串等價**，見下方 5.1.1 |

#### 5.1.1 `localeName` 是本項唯一的實質行為風險

`Platform.localeName` 回傳作業系統字串（如 `zh_TW.UTF-8`、`en_US`），`isLocaleZh()` 以 `.contains('zh')` 比對。`PlatformDispatcher.instance.locale` 回傳 `Locale` 物件，兩者**型別與格式都不同**，不是機械替換：

- `Locale.languageCode` 對中文為 `'zh'`（結構化欄位），比 `.contains('zh')` 掃整個 locale 字串**更精確**——原寫法對假想的 `en_ZH...` 之類字串會誤判，新寫法不會。
- 但 `defaultTargetPlatform` 是編譯期常數、`PlatformDispatcher.instance.locale` 則是**執行期且可變**（使用者中途改系統語言會更新）。`Platform.localeName` 同樣是執行期值，故「每次呼叫重新求值」的時序特性一致，不引入快取語意變更。
- ⚠️ **這是本項最需要在 STAGE 0b 具名測試的一點**：其餘 5 處是布林等價的機械置換，此處是跨型別轉換。
- 🟢 **實際影響面極小**：`isLocaleZh()` 當前**零呼叫**（§4 Out of Scope 已記載），因此任何行為偏差都不會觸及線上使用者。但正因為沒有呼叫端保護它，置換時更不能憑感覺寫。

### 5.2 Apple 登入判準放寬是**刻意的行為變更**，不是 regression

| 項目 | 說明 |
| :--- | :--- |
| **性質** | ✅ **刻意變更**。brief Q3 已將「iOS 與 macOS 皆顯示 Apple 登入」列為成功標準；§9.3-2 亦註明「連帶 macOS 上 Apple 登入按鈕不會出現，但 macOS 其實支援」 |
| **行為差異** | 判準由 `isIOS` 改為 `iOS \|\| macOS` |
| **對既有使用者的影響** | **零**。既有上線平台只有 Android／iOS：Android 兩種判準都是 `false`（不顯示，不變）；iOS 兩種判準都是 `true`（顯示，不變）。差異只在 macOS——一個**目前尚不存在的 target** |
| **為何不等 A-9.2** | 這是「修正一個用錯維度的既有判準」，不是「新增能力閘門」。判準本身就該寫對；A-9.2 處理的是廣告／生物辨識／推播那種需要集中管理的能力矩陣 |
| **可逆性** | 單一條件式，回退成本接近零 |

### 5.3 `isAndroid ? android : ios` 的 else-branch 是 catch-all（須留意、但不在本項修）

3 個 ad 檔的寫法是「是 Android 就用 Android ID，**否則**用 iOS ID」。在只有兩個行動平台的世界裡這是正確的；平台擴張後，macOS／Web 會**落入 else 分支拿到 iOS 的廣告單元 ID**。

- 本項**維持此結構**（機械等價置換，Never break userspace 優先），不改成三分支、不加 `kIsWeb` 判斷。
- 真正的解法是 A-9.2：macOS／Web 根本不初始化 AdMob、不顯示廣告位，則這個 getter 永遠不會在那些平台被求值。
- 本規格明確記載此事，是為了避免 STAGE 0b 或 A-9.2 階段誤以為 A-9.1 已經處理掉廣告的平台安全性。**A-9.1 完成後，macOS／Web 的廣告行為仍未定義。**

### 5.4 其他風險

| 風險 | 評估 |
| :--- | :--- |
| `app_open_ad_state.dart:11` 是**欄位初始化**（非 getter），物件一建立即求值 | 置換後 `defaultTargetPlatform` 同樣可在欄位初始化求值（非 `const` 情境即可），無時序問題 |
| `TargetPlatform` enum 拼寫（`iOS` / `macOS` / `android`）易打錯 | `flutter analyze`（AC-3）會直接攔下，風險收斂於 CI |
| 置換後行動版出現回歸但測試未覆蓋 | `isLocaleZh` 零呼叫、ad unit ID 僅 `banner_ad_test.dart` 間接觸及。STAGE 0b 須為跨型別的 `localeName` 置換補測試（TDD-first），布林等價的 5 處以 `flutter analyze` + 既有測試即可 |
| 改動分散在 6 檔，漏改一處 | AC-1／AC-2 的 grep 判準即為完整性檢查（期望值 0，不是「少了幾個」） |

### 5.5 Linus 式核心判斷

- ✅ **值得做**：解決的是真實阻擋（`dart:io` 在 Web 不存在，不是臆想威脅）＋一個真實的判準錯誤（macOS 支援 Apple 登入卻不顯示）。
- 🟢 **關鍵洞察**：這不是「新增平台支援」，是**把用錯的 API 換成對的 API**。`Platform.isIOS` 問的是「OS 是不是 iOS」，而程式真正想知道的是「這個平台支不支援 Apple 登入」——後者在 macOS 上答案為是。換掉它，macOS 的特殊情況自然消失，不需要新增任何 `if`。
- ⚠️ **最大破壞風險**：`localeName` → `PlatformDispatcher.locale` 的跨型別轉換（§5.1.1）。其餘 5 處為布林等價。
- 🪶 **規模自律**：零新相依、零新抽象、零新檔案。6 行條件式 + 6 行 import 移除 + 2 行 import 新增 + 1 行註解更新。

---

## 6. 後續建議（不屬本項，留作記錄）

1. **`Utils.isLocaleZh()` 零呼叫**：建議另案評估刪除（YAGNI）。若確認為死碼，刪掉比置換更省——但該決策超出本 brief 授權範圍，故本項先保留並正確置換。
2. **A-9.2 能力閘門**：承接 §5.3 的 else-branch catch-all 問題，以及 §9.3-3 的 `MobileAds.instance.initialize()` 未受保護。
3. **E-9.2 CI 編譯閘門**：`flutter build web` 是唯一能機械性防止下一個 `dart:io` 滲入共用程式碼的手段（Guide → Sensor）。本項的 grep 判準（AC-1／AC-2）只是一次性檢查，建議由 E-9.2 轉為常駐。
