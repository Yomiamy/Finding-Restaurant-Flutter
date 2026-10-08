# 實作計畫：A-9.1 平台判斷 API 由 `dart:io` `Platform` 改為 `foundation` 的 `defaultTargetPlatform`

- **項目編號**：A-9.1
- **日期**：2026-10-07
- **對應規格**：`docs/features/2026-10-07-a-9-1-platform-detection-api.md`（已確認，含 §4.1 範圍變更）
- **Effort**：0.1d
- **工作目錄**：`/Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant`

> 本文件只談 **How**。What / Why 見規格，不在此重述。

---

## 0. 實作前基線（2026-10-07 實測，已複查）

本計畫撰寫時實跑確認，作為「改動後沒有退步」的比較基準：

| 指標 | 基線實測值 | 目標值 |
| :--- | :--- | :--- |
| AC-1 `lib/` 的 `import 'dart:io'` 行數 | **6** | 0 |
| AC-2 `lib/` 的 `dart:io` / `Platform.` 命中行數 | **12**（6 import + 6 使用點） | 0 |
| AC-3 `flutter analyze` | `No issues found!`（6.6s） | 同（維持零警告） |
| AC-4 `flutter test` | **All tests passed!（290 passed, 0 failed）** | 同或更多，0 failed |

🟢 **基線全綠**。這點很重要：AC-4 的「既有測試全綠」不是靠放寬標準達成，而是改動前後都該是 290+ passed / 0 failed。任何新出現的 failure 都是本次改動造成的，沒有既有雜訊可以推託。

---

## 1. 置換對照表（逐檔逐行：現狀 → 目標）

全部 6 檔的 `dart:io` 皆**僅**用於 `Platform`（`File` / `Directory` / `Socket` / `HttpClient` / `Process` / `exit` 掃描為 0），故 `import 'dart:io';` 一律**整行移除**，不會有符號失去來源。

### 1.1 檔案 A：`lib/features/utils/utils.dart`（刪除，非置換）

依規格 §4.1，本檔由「置換」改為「刪除死碼」。

| 行 | 現狀 | 目標 |
| :--- | :--- | :--- |
| 2 | `import 'dart:io';` | **整行刪除** |
| 73 | `  static bool isLocaleZh() => Platform.localeName.contains('zh');` | **整行刪除**（方法本體即單行 arrow function） |

- ✅ **不需**新增 `dart:ui` import（§4.1 已載明：刪除後不再需要 `PlatformDispatcher`）。
- ✅ `isLocaleZh` 在 `lib/` 與 `test/` 零呼叫（本計畫重新 grep 複查，唯一命中即第 73 行定義本身）。`utils_barrel.dart` 只 `export 'utils.dart'`，不逐符號匯出，故**不需**改 barrel。
- ✅ 第 1 行 `import 'dart:async';` 另有用途（`Future` 等），**保留**。
- ⚠️ 刪除後第 73 行上方的 `getCurrentPosition` 方法成為 class 最後一個成員，注意不要留下多餘空行（`dart format` 會處理，但 diff 要乾淨）。

### 1.2 檔案 B：`lib/component/ad/banner_ad_state.dart`

| 行 | 現狀 | 目標 |
| :--- | :--- | :--- |
| 1 | `import 'dart:io';` + 其後空行 | **整行刪除** |
| 12 | `String? get bannerAdUnitId => Platform.isAndroid` | `String? get bannerAdUnitId =>`<br>`    defaultTargetPlatform == TargetPlatform.android` |
| 13-14 | `? Constants.adAndroidBannerId : Constants.adIosBannerId;` | **不動**（AC-7：ID 的值一字未改） |

- ✅ 該檔**已** `import 'package:flutter/foundation.dart'`（第 3 行），無須補 import。
- ⚠️ 置換後該 arrow 運算式換行位置由 `dart format` 決定，不要手工硬凹。

### 1.3 檔案 C：`lib/component/ad/interstitial_ad_state.dart`

| 行 | 現狀 | 目標 |
| :--- | :--- | :--- |
| 1 | `import 'dart:io';` + 其後空行 | **整行刪除** |
| 9 | `String? get interstitialAdUnitId => Platform.isAndroid` | `defaultTargetPlatform == TargetPlatform.android` |
| 10-11 | `? Constants.adAndroidInterstitialId : Constants.adIosInterstitialId;` | **不動**（AC-7） |

- ✅ 該檔**已** `import 'package:flutter/foundation.dart'`（第 3 行）。

### 1.4 檔案 D：`lib/component/ad/app_open_ad_state.dart`（補 `foundation.dart` import）

| 行 | 現狀 | 目標 |
| :--- | :--- | :--- |
| 1 | `import 'dart:io';` | **替換為** `import 'package:flutter/foundation.dart';` |
| 11 | `String adUnitId = Platform.isAndroid` | `String adUnitId =`<br>`    defaultTargetPlatform == TargetPlatform.android` |
| 12-13 | 兩個字面值 ID（`ca-app-pub-7910179918263365/2058235863` / `.../5774119595`） | **不動**（AC-7） |

- ⚠️ ~~**這是唯一需補 `foundation.dart` import 的檔**~~ 更正：§1.5、§1.6 也需要明確 import `foundation.dart`（`material.dart` 不轉出 `defaultTargetPlatform`）。
- ⚠️ 該檔 import 區塊現為 `dart:io` / `google_mobile_ads` / `app_open_ad.dart` **三行無空行相隔**。依 `.claude/rules/flutter-styles.md` §3.1，`package:` 與相對路徑之間應有空行。本任務只要把 `dart:io` 換成 `package:flutter/foundation.dart` 並與 `google_mobile_ads` 同組即可；**不順手重排整個 import 區塊**（超出範圍，留給 `dart format` 與既有慣例）。
- ⚠️ **第 11 行是欄位初始化，不是 getter**。`defaultTargetPlatform` 是 `TargetPlatform` 型別的 top-level getter，可在非 `const` 的實例欄位初始化式中求值，無時序問題（規格 §5.4 已評估）。**不要**因此把欄位改成 `late` 或改成 getter——那是擴大範圍。

### 1.5 檔案 E：`lib/manager/fcm_manager.dart`

| 行 | 現狀 | 目標 |
| :--- | :--- | :--- |
| 3 | `import 'dart:io';` | **整行刪除** |
| 109 | `    if (Platform.isIOS) {` | `    if (defaultTargetPlatform == TargetPlatform.iOS) {` |

- ⚠️ **更正（PR #137 review）**：`material.dart` **不會** re-export `defaultTargetPlatform`（`widgets.dart:18` 只轉出 `foundation` 的 `Brightness`、`UniqueKey`）。實作時把第 7 行 `material.dart` 換成 `import 'package:flutter/foundation.dart';`（該檔無其他 material 依賴）。
- ✅ 第 1-2 行 `dart:async` / `dart:convert` 另有用途（`Future` / `JsonEncoder`），**保留**。
- ⚠️ enum 拼寫是 `TargetPlatform.iOS`（大寫 OS），**不是** `ios`。打錯 `flutter analyze` 會攔下。

### 1.6 檔案 F：`lib/flow/signinup/view/third_party_sign_in_widget.dart`（唯一的刻意行為變更）

| 行 | 現狀 | 目標 |
| :--- | :--- | :--- |
| 1 | `import 'dart:io';` + 其後空行 | **整行刪除** |
| 9 | `/// 第三方登入按鈕組。Apple 登入僅在 iOS 顯示。` | `/// 第三方登入按鈕組。Apple 登入在 iOS 與 macOS 顯示。`（AC-6） |
| 33 | `      if (Platform.isIOS) ...[` | `      if (defaultTargetPlatform == TargetPlatform.iOS \|\|`<br>`          defaultTargetPlatform == TargetPlatform.macOS) ...[` |

- ⚠️ **更正（PR #137 review）**：同 §1.5，`material.dart` 不提供 `defaultTargetPlatform`。實作時於第 1 行補 `import 'package:flutter/foundation.dart';`，`material.dart` 保留。
- ⚠️ 這是 **5 處置換中唯一不是布林等價**的一處：判準由「iOS」放寬為「iOS 或 macOS」（規格 §5.2，刻意變更）。行動版仍等價（Android 兩種判準皆 false、iOS 皆 true），差異只在尚不存在的 macOS target。
- ⚠️ 寫成兩個 `==` 的 `||` 比 `{TargetPlatform.iOS, TargetPlatform.macOS}.contains(...)` 更笨但更清楚，且不配置 Set——**採前者**。不要為了「優雅」引入集合。

### 1.7 置換語意速查

| 原寫法 | 目標寫法 | 等價性 |
| :--- | :--- | :--- |
| `Platform.isAndroid` | `defaultTargetPlatform == TargetPlatform.android` | 布林等價（B / C / D 三檔） |
| `Platform.isIOS` | `defaultTargetPlatform == TargetPlatform.iOS` | 布林等價（E 檔） |
| `Platform.isIOS` | `... == TargetPlatform.iOS \|\| ... == TargetPlatform.macOS` | **刻意放寬**（F 檔，AC-5） |
| `Platform.localeName` | — | **無目標**，隨 `isLocaleZh()` 一起刪除（A 檔，§4.1） |

---

## 2. 實作方向的 trade-off 分析

本項的 How 只有一個真正的決策點：**要不要為機械置換補測試、補到什麼程度**。其餘（用什麼 API、要不要抽象）規格 §4 Out of Scope 已鎖死，不是本計畫可開放的選項。

### 方向一：純置換 + 靠 `analyze` / 既有測試把關（不補任何測試）

- **做法**：6 檔改完，跑 AC-1～AC-4 四道機械驗證收工。
- **優點**：diff 最短、工時最省（真的就 0.1d）。布林等價的 5 處，`flutter analyze` 能攔下 enum 拼錯，既有 290 個測試能攔下編譯／行為崩壞。
- **缺點**：**AC-5 完全沒有自動化證據**。實測確認 `test/flow/signinup/sign_in_page_test.dart` 現有 3 個 test case 中，對 Apple 按鈕、對平台判斷**零斷言**（已 grep：`apple` / `Apple` / `ThirdParty` / `Platform` / `debugDefaultTargetPlatform` 全無命中）。這表示 macOS 顯示 Apple 按鈕這個**刻意的行為變更**，在 CI 裡沒有任何東西會驗證它，也沒有東西會在未來有人改回 `isIOS` 時叫出來。
- **風險**：AC-5 退化為純人工確認，而 macOS target 目前還不存在 → 實際上等於**沒有人會驗**。

### 方向二：純置換 + 只為 AC-5 補一個平台參數化 widget test（🟢 **採用**）

- **做法**：方向一 + 在既有 `sign_in_page_test.dart`（或 `third_party_sign_in_widget` 的獨立測試）用 `debugDefaultTargetPlatformOverride` 對 `android` / `iOS` / `macOS` 三個平台各驗一次 Apple 按鈕的有無。
- **優點**：
  - 測試量與風險成正比——**只為唯一的真實行為變更**（F 檔）付測試成本，布林等價的 4 處不補。
  - 專案**已有此模式的先例**：`test/app_theme_platform_test.dart:23,34,60` 就是 `for (final target in [...])` + `debugDefaultTargetPlatformOverride = target` + `finally` 復原。照抄既有慣例，零新概念、零新相依。
  - 這個測試同時**鎖住 AC-5 的三個分支**（iOS 顯示、macOS 顯示、Android 不顯示），比人工目視可靠，且在 macOS target 還不存在時就能驗證判準。
- **缺點**：多一個測試檔／多一個 test case 的工時（約 5 分鐘）。
- **為何值得**：`defaultTargetPlatform` 是執行期 getter，debug 模式下可用 Flutter SDK 內建的 `debugDefaultTargetPlatformOverride` 覆寫——**換成新 API 之後這個測試才寫得出來**。舊的 `Platform.isIOS` 在 widget test 裡無法覆寫（它讀真實 OS），這是置換順帶拿到的紅利，不拿反而浪費。

### 方向三：為全部 5 處置換補單元測試（❌ 不採用）

- **做法**：每個 ad state 的 `adUnitId` 各寫一個平台參數化測試，`fcm_manager.init()` 也 mock 出 iOS 分支。
- **為何不採用**：
  - 4 處是**布林等價的機械置換**，`analyze` 已能攔下唯一的真實失誤模式（enum 拼錯）。為它們寫測試是在測「`==` 有沒有壞」。
  - `fcm_manager.init()` 的 iOS 分支要測就得 mock `FirebaseMessaging.instance`，成本遠高於它防的 bug——而且那個分支的內容本次**一字未改**。
  - 違反規格 §5.4 與 Ponytail 規模自律：0.1d 的 API 置換不該長出一套平台測試矩陣。
- **結論**：測試策略要與規模相稱。這是教條式 TDD 會產出的答案，不是對的答案。

### 📌 決策

**採方向二**。置換照 §1 做滿，測試**只補一個**：AC-5 的平台參數化 widget test。理由一句話：**布林等價的部分交給編譯器，刻意的行為變更交給測試。**

---

## 3. 任務拆分

粒度 2–5 分鐘，每個任務標明寫入路徑與驗收方式。

### T1：刪除 `Utils.isLocaleZh()` 死碼
- **寫入**：`lib/features/utils/utils.dart`
- **動作**：刪第 2 行 `import 'dart:io';`；刪第 73 行整個 `isLocaleZh()` 方法。保留第 1 行 `dart:async`。
- **驗收**：`rtk proxy grep -n "dart:io\|isLocaleZh" lib/features/utils/utils.dart` → 0 命中。
- **對應 AC**：AC-1（-1）、AC-2（-2）
- **註記**：規格 §4.1 授權刪除；`lib/` + `test/` 零呼叫已複查；`utils_barrel.dart` 走 `export 'utils.dart'` 不需改。

### T2：置換 `banner_ad_state.dart`
- **寫入**：`lib/component/ad/banner_ad_state.dart`
- **動作**：刪第 1 行 `import 'dart:io';`；第 12 行 `Platform.isAndroid` → `defaultTargetPlatform == TargetPlatform.android`。三元運算子的兩個分支不動。
- **驗收**：`rtk proxy grep -n "dart:io\|Platform\.is" lib/component/ad/banner_ad_state.dart` → 0 命中；該檔 `Constants.adAndroidBannerId` / `adIosBannerId` 仍各出現 1 次（AC-7）。
- **對應 AC**：AC-1、AC-2、AC-7

### T3：置換 `interstitial_ad_state.dart`
- **寫入**：`lib/component/ad/interstitial_ad_state.dart`
- **動作**：刪第 1 行 `import 'dart:io';`；第 9 行 `Platform.isAndroid` → `defaultTargetPlatform == TargetPlatform.android`。
- **驗收**：同 T2 模式（grep 該檔 0 命中；兩個 Interstitial 常數仍在）。
- **對應 AC**：AC-1、AC-2、AC-7

### T4：置換 `app_open_ad_state.dart`（含補 import）
- **寫入**：`lib/component/ad/app_open_ad_state.dart`
- **動作**：第 1 行 `import 'dart:io';` → `import 'package:flutter/foundation.dart';`；第 11 行欄位初始化 `Platform.isAndroid` → `defaultTargetPlatform == TargetPlatform.android`。兩個字面值 ID 一字不動。
- **驗收**：grep 該檔 `dart:io` → 0；`foundation.dart` → 1；兩個 `ca-app-pub-7910179918263365/...` 字面值仍完整存在（AC-7）。
- **對應 AC**：AC-1、AC-2、AC-7、AC-8（import 來源為 Flutter SDK，`pubspec.yaml` 不動）
- **註記**：⚠️ 欄位初始化非 getter，不要改成 `late` 或 getter。

### T5：置換 `fcm_manager.dart`
- **寫入**：`lib/manager/fcm_manager.dart`
- **動作**：刪第 3 行 `import 'dart:io';`；第 7 行 `material.dart` 換成 `import 'package:flutter/foundation.dart';`；第 109 行 `if (Platform.isIOS)` → `if (defaultTargetPlatform == TargetPlatform.iOS)`。if block 內容不動。保留 `dart:async` / `dart:convert`。
- **驗收**：grep 該檔 `dart:io` → 0；`TargetPlatform.iOS` → 1。
- **對應 AC**：AC-1、AC-2

### T6：置換 `third_party_sign_in_widget.dart` + 更新 doc comment
- **寫入**：`lib/flow/signinup/view/third_party_sign_in_widget.dart`
- **動作**：
  1. 第 1 行 `import 'dart:io';` 換成 `import 'package:flutter/foundation.dart';`（`material.dart` 保留）
  2. 第 9 行 doc comment「Apple 登入僅在 iOS 顯示」→「Apple 登入在 iOS 與 macOS 顯示」
  3. 第 33 行 `if (Platform.isIOS)` → `if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)`
- **驗收**：grep 該檔 `dart:io` → 0；`TargetPlatform.iOS` 與 `TargetPlatform.macOS` 各 1；doc comment 不再含「僅在 iOS」。
- **對應 AC**：AC-1、AC-2、AC-5（程式碼面）、AC-6
- **註記**：程式碼與註解**同一任務內**完成，不拆兩個 task——拆開會製造「註解與程式碼相反」的中間狀態，正是 AC-6 要防的事。

### T7：補 AC-5 平台參數化 widget test
- **寫入**：`test/flow/signinup/third_party_sign_in_widget_test.dart`（新測試檔；屬測試，不違反「零新檔案」——Ponytail 規則針對的是 `lib/` 的生產抽象）
- **動作**：對 `ThirdPartySignInWidget` 以 `debugDefaultTargetPlatformOverride` 參數化三個平台，斷言 Apple 按鈕的有無：
  - `TargetPlatform.iOS` → Apple 按鈕 **存在**
  - `TargetPlatform.macOS` → Apple 按鈕 **存在**
  - `TargetPlatform.android` → Apple 按鈕 **不存在**
  - Google 按鈕三個平台皆存在（確認放寬判準沒誤傷既有按鈕）
- **實作要點**（照抄 `test/app_theme_platform_test.dart:23,34,60` 的既有慣例）：
  - `for (final target in [...])` 迴圈參數化
  - `debugDefaultTargetPlatformOverride = target;` 設於 pumpWidget 前
  - **`try { ... } finally { debugDefaultTargetPlatformOverride = null; }`**——測試中途失敗也必須復原，否則汙染後續 case
  - 需 `MaterialApp` 外殼（widget 用 `S.current` 多語系與 `ThemeSize`）；`S` 的初始化方式比照 `sign_in_page_test.dart` 既有做法
  - 按鈕辨識用 `find.byWidgetPredicate` 比對 `SignInButton` 的 `Buttons.apple` / `Buttons.google`，或以 `S.current.signinup_with_apple` 文字定位——取該檔既有測試已驗證可行的那一種
- **驗收**：`rtk flutter test test/flow/signinup/third_party_sign_in_widget_test.dart` → 全綠，且三個平台分支都實際跑到（4 條斷言分佈於 3 個 case）。
- **對應 AC**：AC-5（自動化證據）、間接鞏固 AC-6
- **註記**：⚠️ 此測試在置換**之後**才寫得出來——舊 `Platform.isIOS` 讀真實 OS，widget test 無法覆寫。這不是 TDD 倒序，是新 API 才解鎖的能力。

### T8：格式化
- **動作**：`rtk dart format lib/ test/`（或僅限改動的 7 檔）
- **驗收**：`rtk dart format --output=none --set-exit-if-changed lib/ test/` → exit 0
- **對應 AC**：AC-3 的前置（格式問題會被 analyze 或 CI 攔）
- **註記**：置換後 arrow 運算式與長條件式的換行位置交給 formatter 決定，不手工硬凹。

### T9：全套機械驗收（AC-1 ～ AC-4）
- **動作**：在 `flutter_restaruant/flutter_restaruant` 下依序執行規格 §3.1 的四道指令：
  ```bash
  # AC-1：預期 0（基線 6）
  grep -rn --include="*.dart" "import 'dart:io'" lib/ | wc -l

  # AC-2：預期 0（基線 12）
  grep -rn --include="*.dart" -e "dart:io" -e "Platform\." lib/ \
    | grep -v "defaultTargetPlatform\|TargetPlatform\.\|PlatformDispatcher\|PlatformApp\|platformViewRegistry" \
    | wc -l

  # AC-3：預期 No issues found!
  flutter analyze

  # AC-4：預期 All tests passed!（≥ 290 passed，0 failed）
  flutter test
  ```
- **驗收**：AC-1 = 0、AC-2 = 0、AC-3 零警告零錯誤、AC-4 全綠且總數 ≥ 基線 290（T7 會讓總數增加）。
- **註記**：⚠️ AC-1 / AC-2 的 grep 需**原文輸出**（數字是下判斷的證據），依 `.claude/rules/rtk-rules.md` 用 `rtk proxy grep` 或直接 `grep`，**不要**用 `rtk grep`（會壓成摘要、數字會不見）。

### T10：人工確認 AC-7 / AC-8
- **動作**：
  - AC-7：`rtk git diff` 檢視 diff，確認廣告單元 ID 的**值**（3 個 Constants 參照 + 2 個字面值）一字未改，只有選擇它們的條件式改了。
  - AC-8：確認 `pubspec.yaml` 不在 diff 中（零新相依）。
- **驗收**：diff 中 ID 字面值與常數名完全未出現在 `-`/`+` 的「值」位置；`pubspec.yaml` 未被修改。
- **對應 AC**：AC-7、AC-8
- **註記**：僅檢視，**不執行任何 git 寫入操作**。

---

## 4. 任務相依關係與並行策略

```
        ┌─ T1 (utils.dart)              ─┐
        ├─ T2 (banner_ad_state)         ─┤
 並行 ──┼─ T3 (interstitial_ad_state)   ─┼─→ T8 (format) ─→ T9 (AC-1~4) ─→ T10 (AC-7/8)
        ├─ T4 (app_open_ad_state)       ─┤
        ├─ T5 (fcm_manager)             ─┤
        └─ T6 (third_party_sign_in)     ─┘
                    │
                    └──→ T7 (AC-5 test)  ─┘
```

| 關係 | 說明 |
| :--- | :--- |
| **T1 ～ T6 可完全並行** | 6 個檔案彼此零交集：無共用符號、無 import 相互引用、無呼叫關係。每個任務只碰自己那一檔的 1 個 import + 1 個運算式。 |
| **T7 必須在 T6 之後** | 測試斷言 macOS 顯示 Apple 按鈕；T6 未完成時該測試必然失敗（舊 `Platform.isIOS` 在 widget test 中無法覆寫）。**唯一的真實序列相依。** |
| **T8 在 T1～T7 之後** | formatter 需看到最終內容，提前跑會白做。 |
| **T9 在 T8 之後** | AC-1 / AC-2 的 grep 必須對最終狀態計數；AC-3 對未格式化的碼可能噪音。 |
| **T10 在 T9 之後** | 確認 AC-3 / AC-4 綠燈後再人工審 diff，避免審到還要再改的版本。 |

**建議執行節奏**：T1–T6 一批平行改完（6 次獨立編輯，無序列限制）→ T7 → T8 → T9 → T10。

---

## 5. 測試策略

### 5.1 既有測試：不需修改任何期望值

規格 AC-4 要求「既有測試全綠，且**不得**以修改既有測試期望值達成」。實查結論：**無任何既有測試需要調整**。具名說明如下：

| 測試檔 | 與本項 6 檔的關係 | 是否需改 | 理由 |
| :--- | :--- | :--- | :--- |
| `test/component/ad/banner_ad_test.dart` | 唯一觸及 ad state 的測試。建構 `BannerADState(completer.future)`、驗佔位高度與 `createAdListener` 回呼 | ❌ **不需改** | 實查該檔：**對 `bannerAdUnitId` 零斷言**，`adUnitId` 唯一出現處是測試自建的 dummy `BannerAd(adUnitId: 'test_id')`，與 `BannerADState` 的 getter 無關。置換 getter 內部條件式不影響它。 |
| `test/di_test.dart` | 僅斷言 `GetIt.I.isRegistered<FcmManager>()` 與 `isA<FcmManager>()`（第 43-44 行） | ❌ **不需改** | 只驗註冊，不呼叫 `init()`，第 109 行的 iOS 分支根本不會跑到。 |
| `test/flow/signinup/sign_in_page_test.dart` | 掛載 `SignInPage`，間接 mount `ThirdPartySignInWidget` | ❌ **不需改** | 實查該檔：`apple` / `Apple` / `ThirdParty` / `Platform` / `debugDefaultTargetPlatform` **全無命中**，3 個 case 只驗輸入框、FilledButton、註冊／訪客按鈕與窄螢幕 overflow。測試在 flutter_test 預設平台（`android`）下跑，Apple 按鈕本來就不渲染，置換後 Android 判準仍為 `false` → **行為不變、測試不變**。 |
| `test/app_theme_platform_test.dart` | 不觸及本項 6 檔 | ❌ **不需改** | 但它是 T7 的**模式範本**（`debugDefaultTargetPlatformOverride` + `try/finally` 復原）。 |
| 其餘 43 個測試檔 | 零引用本項 6 檔的符號 | ❌ **不需改** | — |

> 📌 結論：AC-4 由「改動後重跑 290 個既有測試仍全綠」直接滿足，無需任何期望值讓步。若實作時有任何既有測試轉紅，那是 regression，必須回頭修程式碼，**不准改測試**。

### 5.2 新增測試：只補一個（T7）

| 項目 | 決策 | 理由 |
| :--- | :--- | :--- |
| AC-5 Apple 按鈕平台判準（iOS / macOS / Android） | ✅ **補**（T7） | 本項唯一的**刻意行為變更**（規格 §5.2），且既有測試零覆蓋。置換成 `defaultTargetPlatform` 後才可用 `debugDefaultTargetPlatformOverride` 覆寫 → 新 API 解鎖的能力，不拿浪費。 |
| 3 個 ad state 的 `adUnitId` 平台分支 | ❌ 不補 | 布林等價機械置換。唯一失誤模式（enum 拼錯）由 `flutter analyze`（AC-3）攔下。測這個等於測 `==`。 |
| `fcm_manager.init()` 的 iOS 分支 | ❌ 不補 | 布林等價，且 if block 內容一字未改。要測就得 mock `FirebaseMessaging.instance`，成本遠高於所防 bug。 |
| `Utils.isLocaleZh()` 的 `localeName` 跨型別置換 | ❌ **測試負擔已取消** | 規格 §4.1：方法改為**刪除**，沒有置換就沒有跨型別轉換。§5.1.1 的原始結論（「需具名測試」）已被 §4.1 明確取消。死碼刪除零測試負擔。 |

### 5.3 驗證層次

| 層次 | 手段 | 攔得住什麼 |
| :--- | :--- | :--- |
| 編譯期 | `flutter analyze`（AC-3） | `TargetPlatform` enum 拼錯（`ios` / `macos`）、import 缺漏、`dart:io` 移除後的孤兒符號 |
| 完整性 | AC-1 / AC-2 grep（期望值 **0**，非「少了幾個」） | 6 檔漏改任一處 |
| 行為回歸 | `flutter test` 290 個既有測試（AC-4） | 行動版語意跑掉 |
| 刻意變更 | T7 新測試（AC-5） | Apple 按鈕三平台判準錯誤、未來有人改回 `isIOS` |
| 人工 | AC-6 註解、AC-7 ID 值、AC-8 相依 | 文件與程式碼說法相反、ID 被誤改、偷加相依 |

---

## 6. 明確不做（守住範圍）

| 不做 | 依據 |
| :--- | :--- |
| 建 `PlatformInfo` wrapper / platform service / 包裝 `defaultTargetPlatform` 的 util | 規格 §4 Out of Scope。既有先例 `lib/firebase_options.dart:5,19,25` 就是直接用，照做。 |
| A-9.2 能力閘門；改「廣告在哪些平台初始化／顯示」 | 規格 §4 / §5.3。**A-9.1 完成後 macOS / Web 的廣告行為仍未定義**，3 個 ad 檔的 `else` catch-all 維持原結構（iOS ID 兜底），不改三分支、不加 `kIsWeb`。 |
| 動 `lib/firebase_options.dart` | 屬 A-9.3。 |
| 改廣告單元 ID 的**值**；把 `app_open_ad_state.dart` 字面值 ID 抽成常數 | AC-7 / 規格 §4（既有技術債，非本項）。 |
| 新增 `pubspec.yaml` 相依 | AC-8。所需 API 全為 Flutter SDK 內建。 |
| 把 `flutter build web` / `flutter build macos` 成功列入驗收 | 規格 §3.3：Yelp CORS、A-9.3、AdMob `MissingPluginException` 等阻擋未解，納入會讓本項無法收斂。 |
| 重排 `app_open_ad_state.dart` 整個 import 區塊 | 超出範圍；只換 `dart:io` 那一行。 |
| 任何 git 操作（add / commit / push） | 本階段僅規劃與實作，不觸碰版本控制。 |

---

## 7. 執行方式選項

| 方式 | 做法 | 適用情境 | Trade-off |
| :--- | :--- | :--- | :--- |
| **A. 單一 session 循序（🟢 建議）** | 一個 implementer 依 T1→T10 順序做完。T1–T6 在同一 session 內以平行工具呼叫批次編輯。 | **本項規模的預設選擇**：6 個單行改動 + 1 個測試，總 diff 約 15 行 | 最省 context 與協調成本。6 檔無交集，單人改完全不會打結。**協調開銷 > 改動本身**的任務不該拆。 |
| **B. subagent-driven** | 派 1 個 implementer subagent 執行 T1–T8，回報後由 caller 跑 T9–T10 驗收。 | 希望主 session 保持乾淨、或要把驗收與實作分離（實作者不驗自己的工） | 多一次交接；好處是 T9/T10 由不同角色執行，AC 驗證較客觀。**若在意「實作者自驗」的盲點，選這個。** |
| **C. parallel session** | T1–T6 拆 6 個 session 並行改檔，匯合後跑 T7–T10。 | ❌ **不建議** | 6 檔雖真正獨立（技術上可並行），但每檔只改 2 行。開 6 個 session 的啟動與匯合成本遠超收益，且 T7 仍得等 T6。**典型的為形式完整而過度並行。** |

**建議**：採 **A**；若需要實作與驗收分離，採 **B**。不要用 C。

---

## 8. 完成定義（DoD）

- [ ] T1–T8 全部完成，7 個檔案（6 個 `lib/` + 1 個新測試）已寫入
- [ ] AC-1 = `0`（基線 6）
- [ ] AC-2 = `0`（基線 12）
- [ ] AC-3 `flutter analyze` → `No issues found!`
- [ ] AC-4 `flutter test` → `All tests passed!`，總數 ≥ 290 且 0 failed，**且未修改任何既有測試的期望值**
- [ ] AC-5 T7 新測試涵蓋 iOS 顯示 / macOS 顯示 / Android 不顯示，全綠
- [ ] AC-6 `third_party_sign_in_widget.dart` doc comment 已改為「iOS 與 macOS」
- [ ] AC-7 diff 中廣告單元 ID 的值（3 常數 + 2 字面值）一字未改
- [ ] AC-8 `pubspec.yaml` 未被修改
- [ ] `dart format` 無待格式化變更
