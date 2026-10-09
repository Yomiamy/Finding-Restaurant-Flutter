# 功能規格：A-9.2 平台能力閘門（AdMob／推播／地圖模式）與 macOS App Check provider

- **項目編號**：A-9.2（沿用 `docs/brainstorm/2026-10-09-features-brainstorm.md` §9.6 編號）
- **日期**：2026-10-09
- **Effort（brainstorm 估計）**：0.5d
- **依賴**：A-9.1（已完成，2026-10-08 合併；`lib/` 已無 `dart:io` `Platform`，平台判斷一律用 `foundation.dart` 的 `defaultTargetPlatform`／`kIsWeb`）
- **相關脈絡**：§9.3-3（AdMob 初始化未受保護）、§9.4.1「能力閘門」「App Check」兩列、§9.6 A-9.2 列、§9.8 D-9.4／D-9.6／D-9.7／D-9.8、§9.9 末列（「一處閘門即可」）
- **實查基線**：`chore/202610/140-macos-deployment-target-14` @ `65a9852`（macOS deployment target 已上修至 14.0）

---

## 1. 問題陳述與影響 (What & Why)

### 1.1 核心問題：「這個平台有沒有這項能力」沒有任何判斷點

AdMob、推播（FCM）、Google 地圖三項能力只在原生 Android／iOS 有實作，但程式碼對它們是**無條件使用**。`lib/` 目前沒有任何集中式能力判斷（`capabilit`／`featureFlag` 等關鍵字實查為 0）。實查呼叫點（2026-10-09）：

| # | 檔案:行 | 行為 | 在 macOS／Web 的後果 |
| :--- | :--- | :--- | :--- |
| 1 | `lib/main.dart:32-33` | `MobileAds.instance.initialize()` 位於 `try`（`:35`）之外，回傳的 Future 交給 `BannerADState` 並註冊進 `getIt` | `google_mobile_ads` 9.1.0 的 `pubspec.yaml:24-27` 只宣告 `android`／`ios`，macOS／Web 無原生實作 → 預期 `MissingPluginException`，錯誤在 `banner_ad.dart:36` `await widget.adState.initialization` 時浮出（推論未實測）。Web 另有套件自身 `import 'dart:io'`（`ad_instance_manager.dart:23`） |
| 2 | `lib/flow/main/view/main_page.dart:81-84` | `bottomNavigationBar` 恆放 `BannerAD(adState: getIt<BannerADState>())` | `BannerAD` 不論有無廣告都渲染固定 50dp 容器（`banner_ad.dart:79-96`）→ 主頁底部永遠留一條空白廣告條 |
| 3 | `lib/flow/restaurant/view/restaurant_detail_page.dart:49-52` | 每進詳情頁 3 次（`AdCounterManager`）載入一次插頁廣告 | 同 #1 呼叫 AdMob API；`interstitial_ad.dart:11` 對單元 ID 用 `!`，且 macOS／Web 會落入 else 分支拿到 iOS 單元 ID（A-9.1 規格 §5.3 已記載、留給本項） |
| 4 | `lib/main.dart:64` | `await FcmManager().init()` | **macOS 為確定性失敗（原始碼已確認）**：`fcm_manager.dart:122-126` 的 `InitializationSettings` 只給 `android`／`iOS`，`flutter_local_notifications` 22.3.1 在 macOS 會拋 `ArgumentError('macOS settings must be set when targeting macOS platform.')`（`flutter_local_notifications_plugin.dart:158-162`），被 `main.dart:65` 的 `catch` 吞成一筆 `Initialization failed` log。D-9.7 原記「可能失敗或拖慢啟動——推論未實測」，此處更正為必失敗 |
| 5 | `main_page.dart:46` → `lib/flow/main/bloc/main_bloc.dart:91-97` | 主頁 `initState` 派發 `NotificationSetup` → `requestPermission()` ＋ 讀 `fcmToken` | macOS：為一個已決議不提供的功能（D-9.7）跳出系統通知權限詢問（推論未實測）；`fcmToken` getter（`fcm_manager.dart:31-32`）不在任何 `try` 內，無 APNs 時取 token 預期拋錯並進入 bloc 錯誤路徑（推論未實測） |
| 6 | `lib/flow/main/view/drawer_widget.dart:71-79` | 「地圖模式／列表模式」切換項恆顯示 | `google_maps_flutter` 2.18.1 無 macOS 實作；一旦切換即建構 `MapWidget`（`main_page_content_widget.dart:79`）→ `GoogleMap`（`map_widget.dart:110`）無法渲染 |

### 1.2 第二個問題：macOS release 的 App Check provider 選錯

`main.dart:53-56` 的 release 分支傳 `providerApple: const AppleAppAttestProvider()`。**`providerApple` 同時作用於 iOS 與 macOS**（`firebase_app_check` 0.4.8 `lib/src/firebase_app_check.dart:71-74`：「iOS/macOS: ... Use `providerApple`」），所以現在 macOS release 拿到的就是 App Attest。

實查 `firebase_app_check` 0.4.8 的 macOS 原生碼（`macos/firebase_app_check/Sources/firebase_app_check/FirebaseAppCheckPlugin.swift`）：

| provider 名稱 | 行 | 行為 |
| :--- | :--- | :--- |
| `appAttest`（`AppleAppAttestProvider`） | `:365-370` | 只以 `#available(macOS 14.0)` 判斷。deployment target 已為 14（`65a9852`），此條件恆真 → **一律**使用 `AppAttestProvider`，不檢查這台 Mac 是否支援 App Attest |
| `appAttestWithDeviceCheckFallback`（`AppleAppAttestWithDeviceCheckFallbackProvider`） | `:371-381` | 在 `activate` 時另檢查 `DCAppAttestService.shared.isSupported`，不支援即改用 `DeviceCheckProvider`。同處註解：App Attest 支援「is often false on macOS」，且 SDK 要到第一次取 token 才回報不支援 |

> **說法更正**：brainstorm §9.4.1 與 `65a9852` commit message 所述「`AppleAppAttestProvider` 會被**靜默換成 Debug provider**」只發生在 macOS 14 **以下**（`:368-369` 的 else 分支）。deployment target 上修後該分支已不可達。現行的真實風險變成：**不支援 App Attest 的 Mac 仍被指派 `AppAttestProvider`，取 token 時才失敗**。結論不變——macOS 必須改用 fallback provider（D-9.6）。

### 1.3 為什麼現在做

- 能力矩陣已全部由決策定案，只差落地：D-9.4（首版無廣告）、D-9.7（macOS 不做推播）、D-9.1 W-B（Web 不含廣告／推播）、D-9.6（macOS 14、採 fallback provider）。
- §9.7「建議動工順序」macOS 線第 2 步；A-9.6（macOS 地圖降級為靜態圖＋外部導航）依賴本項。
- A-9.1 規格 §5.3 明載「A-9.1 完成後，macOS／Web 的廣告行為仍未定義」，由本項承接。
- 基線 `flutter build macos` 已可成功（見 AC-3），macOS 目前卡在「能編譯、但啟動即有 AdMob／FCM 錯誤與無效 UI」。本項是讓它「啟動乾淨」的第一步。

### 1.4 核心資料：能力矩陣

| 能力 | Android | iOS | macOS | Web（不論瀏覽器所在 OS） | 依據 |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **AdMob**（初始化、Banner、Interstitial） | ✅ | ✅ | ❌ | ❌ | 套件只支援 android／ios；D-9.4 |
| **推播**（FCM 初始化、權限請求、token） | ✅ | ✅ | ❌ | ❌ | D-9.7；D-9.1 W-B 不含推播 |
| **地圖模式**（列表／地圖切換） | ✅ | ✅ | ❌ | ❌（暫定） | 套件無 macOS 實作；Web 有實作但需 Maps JS API key（E-9.3），且 repo 目前**沒有 `web/` 目錄**（Web target 尚未建立） |

**觀察**：三列的真值表目前完全相同——「原生 Android 或原生 iOS」。但三者成立的**理由不同**（套件限制／產品決策／暫缺設定），且 Web 地圖預期會在 E-9.3 翻轉。這決定了呼叫點應該讀「能力名稱」而不是「平台名稱」（見 §6）。

**換個角度看，兩個特殊情況自然消失**（不需加任何判斷）：

- `lib/flow/splash/view/splash_page.dart:35-36` 讀 `FcmManager().initialArguments`：這只是讀欄位。推播關閉時 `init()` 不執行、欄位恆為 `null`，既有邏輯自動走「無冷啟動參數」分支。
- `MapWidget`：`_isListMode` 初值為 `true`（`main_page.dart:34`），唯一翻轉點是 drawer 切換（`main_page.dart:124-130`，經 `drawer_widget.dart:78` 觸發）。切換項不出現，`MapWidget` 就永遠不會被建構，`main_page_content_widget.dart` 不需改。

### 1.5 零新增相依

- `AppleAppAttestWithDeviceCheckFallbackProvider` 已存在於 `firebase_app_check_platform_interface` 0.4.2+1（`lib/src/apple_providers.dart:52-55`，`const` 建構式），由 `firebase_app_check` 0.4.8 轉出——**無需升版**。
- `kIsWeb`／`defaultTargetPlatform` 來自 `flutter/foundation.dart`。沿用 A-9.1 的教訓：**必須明確 `import 'package:flutter/foundation.dart'`**，`material.dart` 的 re-export 是 `show` 白名單，不含這兩個符號。

---

## 2. 使用者故事 (User Stories)

1. **作為 macOS 使用者**，我啟動 App 時不該出現 AdMob／推播初始化錯誤，也不該被詢問一個 App 根本不提供的通知權限；主頁底部不該有一條永遠空白的廣告條；側邊選單不該出現點了會壞掉的「地圖模式」；連續看店家詳情也不該觸發插頁廣告的載入。
2. **作為 Web 使用者**（W-B 精簡版，Web target 建立後），不論我用桌機瀏覽器、Android Chrome 或 iPhone Safari，App 都不該因為「瀏覽器跑在 Android／iOS 上」就去初始化 AdMob 或 FCM。
3. **作為既有 Android／iOS 使用者**，我感受不到任何差異：Banner 照常在主頁底部、每 3 次進詳情頁照常出現插頁、推播照常收得到、地圖模式照常可切換、iOS 的 App Check 照常走 App Attest。
4. **作為維護者**，「這個平台有沒有廣告／推播／地圖」只有一個地方回答；呼叫點只讀結果，不散落 `if (平台)`。日後 E-9.3 讓 Web 開放地圖、或評估 AdSense 時，只改那一處。
5. **作為營運者**，macOS release 的 App Check 應在不支援 App Attest 的 Mac 上退回 DeviceCheck 取得有效 token，而不是指派一個必定失敗的 provider（前提：Console 登記與真實簽章，見 §4.3、§5.5）。

### 受影響的使用情境（觸發路徑：啟動 → 主頁 → drawer → 詳情頁）

| 情境 | Android／iOS | macOS：現況 → 改動後 | Web：現況 → 改動後（程式碼層面預期；Web target 尚未建立） |
| :--- | :--- | :--- | :--- |
| 啟動初始化 | **不變** | AdMob 初始化失敗、FCM `ArgumentError` → 兩者皆不呼叫 | 同 macOS |
| 主頁 `initState` 推播設定 | **不變** | 跳權限詢問、取 token 拋錯 → 不請求權限、不取 token | 同 macOS |
| 主頁底部 | **不變**（Banner） | 50dp 空白條 → 不佔位 | 同 macOS |
| Drawer | **不變**（6 項） | 有地圖切換 → 無地圖切換（5 項） | 同 macOS |
| 第 3 次進詳情頁 | **不變**（插頁） | 呼叫 AdMob → 不呼叫 | 同 macOS |
| App Check（release） | **不變**（iOS `AppleAppAttestProvider`／Android `AndroidPlayIntegrityProvider`） | `AppleAppAttestProvider` → `AppleAppAttestWithDeviceCheckFallbackProvider` | 不在本項（A-9.3b） |
| App Check（debug） | **不變** | **不變**（`AppleDebugProvider`） | 不在本項 |

---

## 3. 驗收條件 (Acceptance Criteria)

### 3.1 可機械驗證（必須全數通過）

在 `flutter_restaruant/flutter_restaruant` 目錄下執行：

```bash
# AC-1：靜態分析零警告零錯誤
flutter analyze

# AC-2：既有＋新增測試全綠
flutter test

# AC-3：macOS 本機建置成功（D-9.8：macOS 以本機 build 驗收）
flutter build macos

# AC-4：呼叫點不自行判斷平台 —— 預期輸出 0（基線 0）
grep -n -e "defaultTargetPlatform" -e "kIsWeb" -e "TargetPlatform\." \
  lib/flow/main/view/main_page.dart \
  lib/flow/main/view/drawer_widget.dart \
  lib/flow/restaurant/view/restaurant_detail_page.dart \
  lib/flow/main/bloc/main_bloc.dart \
  lib/flow/splash/view/splash_page.dart \
  | wc -l

# AC-5：平台判斷的檔案集合有上限 —— 基線 6 檔，改動後至多 8 檔
grep -rln --include="*.dart" -e "defaultTargetPlatform" -e "kIsWeb" lib/ | sort
```

- **AC-1** `No issues found!`
- **AC-2** 全部通過，且**不得**以修改既有測試期望值的方式達成。特別是 `test/flow/main/view/drawer_widget_test.dart:45` 的 `findsNWidgets(6)`（預設測試平台為 android）必須**原樣**通過——它是「行動版 drawer 不變」的回歸證據。
- **AC-3** 輸出 `✓ Built build/macos/Build/Products/Release/flutter_restaruant.app`。
  - **基線已實測**：2026-10-09 於 `65a9852` 執行 `flutter build macos --debug` 與 `flutter build macos`（release）**皆成功**，執行後工作樹無變動。
  - **為何可列為硬性條件**（與 A-9.1 §3.3 不同）：A-9.1 時 macOS 尚有 `firebase_options.dart` 等他項阻擋；如今基線已綠，而本項只改 Dart、零新相依、不動 `macos/` 原生設定，build 結果的任何差異只可能來自本項程式碼，範圍可控。
  - **例外**：若實作期間 `main` 合入他項導致建置失敗，先在未改動的基線重現；基線同樣失敗則不計入本項，於 PR 註明。
- **AC-4** 預期 `0`。這五個檔案是 §1.1 的呼叫點，能力判斷不得在此落地成平台條件式。
- **AC-5** 基線 6 檔：`firebase_options.dart`（產生碼）、`third_party_sign_in_widget.dart`（A-9.1 Apple 登入判準）、`banner_ad_state.dart`／`interstitial_ad_state.dart`／`app_open_ad_state.dart`（廣告單元 ID 選擇）、`fcm_manager.dart`（`:108` iOS 前景顯示設定）。改動後**最多新增 2 檔**：能力閘門所在檔 1 個，加上 `main.dart`（僅限 App Check 的 iOS／macOS 分岔，且若該分岔改由閘門提供則不新增）。新增檔不得是 AC-4 的任一呼叫點。

### 3.2 新增測試（TDD-first，納入 AC-2）

- **AC-6 能力矩陣單元測試**：
  - android、iOS（非 Web）→ 三項能力皆為 `true`
  - macOS → 皆為 `false`
  - windows、linux、fuchsia → 皆為 `false`（白名單 fail-closed，見 §6）
  - **Web ＋ android、Web ＋ iOS、Web ＋ macOS → 皆為 `false`**（行動瀏覽器陷阱，見 §5.2）
  - 平台覆寫一律用 `debugDefaultTargetPlatformOverride`，並在 `finally` 復原（沿用 `test/flow/signinup/third_party_sign_in_widget_test.dart` 的寫法）
  - Web 案例的測法由 STAGE 0b 決定（`kIsWeb` 是編譯期常數 `bool.fromEnvironment('dart.library.js_interop')`，Flutter SDK `foundation/constants.dart:83`，VM 測試下恆為 `false`、無法覆寫），但上述三個 Web 案例**必須真的被執行**，不得以「VM 下測不到」為由略過。
- **AC-7 Widget 測試**：`DrawerWidget` 在 macOS 覆寫下不出現地圖／列表切換項（`ListTile` 5 個），android 下維持 6 個。Banner 在不支援平台下不渲染 50dp 佔位——測試層級由 0b 依可行性決定（`MainPage` 牽涉 `BlocProvider` 與 `getIt`，可在較小單位驗證）。
- **AC-8 App Check provider 選擇**：

  | 建置 | iOS | macOS | Android |
  | :--- | :--- | :--- | :--- |
  | release | `AppleAppAttestProvider`（不變） | `AppleAppAttestWithDeviceCheckFallbackProvider`（變更） | `AndroidPlayIntegrityProvider`（不變） |
  | debug | `AppleDebugProvider`（不變） | `AppleDebugProvider`（不變） | `AndroidDebugProvider`（不變） |

  若選擇邏輯抽為可測的純函式，必須有對應測試鎖住上表；若就地寫在 `main.dart`，則以 code review 確認。

### 3.3 需人工／情境確認

- **AC-9 macOS 本機執行觀察**（`flutter run -d macos`，debug）：
  - console 無 `google_mobile_ads` 的 `MissingPluginException`，無 `Initialization failed` 伴隨 `macOS settings must be set when targeting macOS platform.`
  - 進主頁時**不**跳系統通知權限詢問
  - 主頁底部無 50dp 空白條
  - Drawer 無「地圖模式」項
  - 連續進詳情頁 3 次以上，無任何 AdMob 相關錯誤
  - 登入需等 E-9.4a（keychain），可用登入頁的訪客入口（`sign_in_actions_widget.dart`）進主頁；`fluttertoast` 無 macOS 實作（UI-9.2）、Yelp 資料是否載入，皆不影響上述觀察點。
- **AC-10 註解同步**：
  - `restaurant_detail_page.dart:50` 的「iOS DetailPage才有全屏AD」與事實不符（Android 同樣顯示）；該區塊若被修改須同步更正。
  - `DrawerWidget` 類別 doc comment（`drawer_widget.dart:7-9`）列舉了「檢視模式切換」；改為依平台顯示後須註明。
- **AC-11**：不新增任何 `pubspec.yaml` 相依、不升級 `firebase_app_check`。

### 3.4 不納入本項驗收

- **macOS 執行期 App Check token 實際取得成功**：需真實簽章（E-9.4a）與 Console 登記（§4.3）。本項只保證「指派的 provider 正確」。
- **Web 建置與執行**：repo 無 `web/` 目錄，Web target 尚未建立；Web 編譯閘門屬 E-9.2。本項的 Web 行為只以 AC-6 的單元測試驗證。
- **Android／iOS 真機回歸**：本項在行動版走的是與現況相同的程式路徑（三項能力恆為 `true`、App Check provider 不變），由 AC-2／AC-6／AC-8 鎖住；真機 smoke test 為建議，非必要。

---

## 4. 範圍與邊界 (Scope & Boundaries)

### 4.1 In Scope

- 一處集中的能力判斷：AdMob、推播、地圖模式三項，Android／iOS（非 Web）開啟，其餘一律關閉
- `main.dart`：AdMob 初始化與 `BannerADState` 註冊、`FcmManager().init()` 依能力略過
- `main.dart`：App Check release 的 `providerApple` 依 iOS／macOS 分岔（macOS 改 `AppleAppAttestWithDeviceCheckFallbackProvider`），debug 與 Android 不變
- 主頁 Banner、詳情頁 Interstitial、Drawer 地圖切換、`NotificationSetup` 推播權限與 token 依能力略過
- §3.2 的新增測試
- AC-10 的兩處註解同步

### 4.2 Out of Scope

- ❌ **生物辨識**：實查**無任何可見 UI 入口**——settings view 無開關，`BiometricSignInEvent` 只在 `sign_in_bloc.dart:37` 被 pattern match，`lib/` 無任何建構／派發點。`local_auth` 3.0.2 支援 macOS。（Web 上有一個啟動期的隱憂，見 §5.6，不屬本項）
- ❌ **App Open 廣告**：`AppOpenADState(` 在 `component/ad/` 以外零建構點，`AppLifecycleReactor` 零使用，屬死碼。`main_page.dart:31` 的 `implements AppOpenADEvent` 與 `:239-244` 空實作同屬之。不在本項刪除（見 §7）
- ❌ **Web 的 App Check provider**（`providerWeb`／reCAPTCHA Enterprise）：A-9.3b。本項不得改變 `activate` 在 Web 的現行行為
- ❌ **macOS 地圖降級為靜態圖＋外部導航、entitlements、Google 登入 URL scheme**：A-9.6。本項只「隱藏地圖切換」，不提供替代
- ❌ **為 macOS 補 `InitializationSettings.macOS`**：那等於在 macOS 做推播，違反 D-9.7
- ❌ **廣告單元 ID 的 else-branch catch-all**（A-9.1 §5.3）：閘門關閉後 macOS／Web 永遠不會求值這些 getter，結構維持原樣
- ❌ **`main.dart:65` 的裸 `catch`**（會連 `Error` 一起吞，違反 style guide §6.1）：既有技術債，不在本項
- ❌ **簽章後的執行期 App Check 驗證**：E-9.4a
- ❌ **新增相依、新增 interface／platform service／DI 註冊的抽象層**

### 4.3 部署前置注意事項（手動作業，非本項驗收）

- **Firebase Console → App Check → macOS app（`com.yomi.find-restaurant.macos`，`firebase_options.dart:85`）**：登記 DeviceCheck（需 Apple Developer 的 DeviceCheck private key `.p8`、Key ID、Team ID）與 App Attest。未登記前，macOS release 取得的 token 會被 Firebase 拒絕。
- **debug**：macOS 的 debug token 需另行登記（`AppleDebugProvider` 會於 console 印出 token，`FirebaseAppCheckPlugin.swift:357-364`）。
- 若 Firebase AI 已開啟 App Check **enforcement**，上述完成前 macOS release 的 Menu Vision／AI Foodie 不可用。

---

## 5. 風險與破壞性評估 (Never break userspace)

### 5.1 行動版必須零變化（鐵律）

| 項目 | 等價性論證 |
| :--- | :--- |
| 三項能力 | Android／iOS 上恆為 `true` → 每個呼叫點走與現況相同的路徑。AC-6 鎖住 |
| Drawer | android 下仍 6 項，`drawer_widget_test.dart:45` 原樣通過（AC-2） |
| App Check | iOS release 仍是 `AppleAppAttestProvider`、Android 不變、debug 不變（AC-8） |
| 啟動時序 | 行動版 `MobileAds.instance.initialize()` 仍在 `runApp` 前發出、`FcmManager().init()` 仍在 `runApp` 前 `await`（後者是 SplashPage 冷啟動跳頁的前提，見 `main.dart:62-63` 註解）。本項不得改變行動版的呼叫順序與是否 `await` |

### 5.2 最大正確性陷阱：Web 上的 `defaultTargetPlatform` 是「瀏覽器所在的 OS」

Flutter SDK（3.47.1）`foundation/_platform_web.dart:50-58`：Web 上 `defaultTargetPlatform` 由瀏覽器的作業系統推得——Android Chrome → `TargetPlatform.android`、iPhone Safari → `TargetPlatform.iOS`，**未知 OS 一律回 `android`**。

後果：若能力判斷只寫 `defaultTargetPlatform == android || == iOS`，**行動瀏覽器上的 Web 版會被當成原生行動版**，去初始化 AdMob 與 FCM——正好是 Web 使用者最主要的情境。**判斷必須先看 `kIsWeb`**。這是 AC-6 強制要求 Web ＋ android／iOS 案例的原因。

### 5.3 `BannerADState` 的註冊與取用是耦合的

`main.dart:33` 註冊、`main_page.dart:83` 以 `getIt<BannerADState>()` 取用。若只略過註冊而主頁仍建構 `BannerAD`，`getIt` 會拋 `StateError`，在不支援平台上**把主頁整個弄崩**——比現況更糟。兩端必須讀同一個能力來源。

### 5.4 `providerApple` 同時作用於 iOS 與 macOS

最省事的寫法「把 `AppleAppAttestProvider` 整個換成 fallback provider」會**改變 iOS 行為**：iOS 上不支援 App Attest 的裝置會改走 DeviceCheck，且 iOS app 也必須在 Console 登記 DeviceCheck 金鑰。這違反「iOS 維持 `AppleAppAttestProvider`」的成功標準，必須依平台分岔。

### 5.5 未實測推論（須在 E-9.4a 或實機驗證時確認）

| 推論 | 依據 | 影響 |
| :--- | :--- | :--- |
| DeviceCheck／App Attest token 綁開發者 Team；macOS 目前為 ad-hoc 簽章（`project.pbxproj` 三組 `CODE_SIGN_IDENTITY = "-"`，無 `DEVELOPMENT_TEAM`），執行期取 token 預期失敗 | brainstorm §9.6 A-9.2 列 | 本項只能驗證「provider 指派正確」，無法驗證「token 有效」 |
| fallback 的切換時點是 `activate` 當下的 `DCAppAttestService.shared.isSupported`，**不是** attestation 失敗後才退回 | `FirebaseAppCheckPlugin.swift:371-381` | 若機器回報支援 App Attest、但因簽章或 entitlement 問題 attestation 失敗，**不會**自動退回 DeviceCheck |
| iOS 與 macOS 的 entitlements 皆無 `com.apple.developer.devicecheck.appattest-environment`；macOS 的 App Attest 分支是否需要它未查證 | `ios/Runner/Runner.entitlements`、`macos/Runner/Release.entitlements` 實查 | 列入 E-9.4a 實測項目 |
| macOS 上 `requestPermission()` 會跳系統通知權限詢問；無 APNs 時 `getToken()` 會拋錯 | `firebase_messaging` 支援 macOS，`aps-environment` 未設定（D-9.7） | 本項關閉後即不再觸發，屬「消失的風險」，不需另行驗證 |
| macOS／Web 上 AdMob 呼叫產生 `MissingPluginException` | `google_mobile_ads` 9.1.0 僅宣告 android／ios | 同上，本項關閉後即不再觸發 |

### 5.6 實查發現（本項範圍外，需上報）：Web 啟動期的生物辨識呼叫

生物辨識依 brief 排除於本項（無 UI 入口），但實查發現它在**啟動期就會被觸發**：

- `main.dart:42` 於 `runApp` 前呼叫 `SignInManager().loadPrefs()` → 建構 `SignInManager` → 欄位初始化 `BiometricSignInManager()`（`sign_in_manager.dart:33`）→ 建構式呼叫 `initBioSignInInfo()`（`biometric_sign_in_manager.dart:17-19`）→ `_localAuth.getAvailableBiometrics()`（`:30`），且未 `await`、無錯誤處理。
- `local_auth` 3.0.2 的 `pubspec.yaml` 只宣告 `android`／`ios`／`macos`／`windows`，**無 Web**。`test/guest_mode_test.dart:50-53` 的註解也證實此呼叫在無原生實作時會噴 `MissingPluginException`。
- 推論（未實測）：Web 上每次啟動都會產生一個未捕捉的非同步錯誤。**macOS 不受影響**（`local_auth` 有 macOS 實作）。

這與「無 UI 入口」的排除理由無關——問題不在 UI，在啟動路徑。建議由 Web 線（Web target 建立時，或 E-9.2 首次 `flutter build web`／執行時）承接，或由使用者決定是否併入本項。

### 5.7 Linus 式核心判斷

- **值得做**：解決的是真實、可重現的問題——macOS 上 FCM 初始化是**確定性**拋 `ArgumentError`（原始碼已證），AdMob 無原生實作，地圖切換點下去就壞，App Check 在多數 Mac 上指派一個必定失敗的 provider。
- **關鍵洞察**：資料結構只是一張 3 能力 × 平台的布林表，而且三列目前長得一模一樣。真正的工作不是「加判斷」，而是**讓呼叫點問對問題**——問「有沒有廣告能力」，不問「是不是 macOS」。問對了，Splash 的冷啟動參數與 `MapWidget` 兩個特殊情況自動消失（§1.4）。
- **最大破壞風險**：(1) Web 上 `defaultTargetPlatform` 回報瀏覽器所在 OS（§5.2）；(2) 只略過 `BannerADState` 註冊卻沒略過取用（§5.3）；(3) 把 fallback provider 套到 iOS（§5.4）。
- **規模自律**：零新相依、零新抽象層。預期 1 個能力判斷處 ＋ 約 6 個呼叫點各讀一次結果 ＋ App Check 一處分岔 ＋ 測試。

---

## 6. 給 STAGE 0b 的設計約束與待決事項

### 6.1 約束（計畫必須遵守）

1. **白名單，不是黑名單**：能力 = 「非 Web」且「平台 ∈ {android, iOS}」。不寫成「非 macOS 且非 Web」——白名單讓 windows／linux／fuchsia 自動 fail-closed，日後新平台也不需新增特殊情況。
2. **`kIsWeb` 先判**（§5.2）。
3. **呼叫點讀能力名稱**（廣告／推播／地圖模式），不讀平台名稱（§1.4：三者理由不同，Web 地圖預期會先翻轉）。
4. **`BannerADState` 的註冊與取用同源**（§5.3）。
5. **行動版呼叫順序與 `await` 不變**（§5.1）。
6. **不新增 interface、platform service、DI 註冊**：一個實作不需要介面。沿用 A-9.1「直接用 `foundation`」的先例。

### 6.2 待 0b 分析 trade-off 的選擇

- **守衛放哪**：
  - (A) 守在呼叫點：閘門提供能力布林，`main.dart`、`main_page.dart`、`restaurant_detail_page.dart`、`drawer_widget.dart`、推播設定處各讀一次。改動點明確，但呼叫點數與能力使用點同步成長。
  - (B) 下沉到共用元件：`FcmManager` 的 `init`／`requestPermission`／`fcmToken`、`BannerAD`、`IntersitialAD.load` 各自在內部提早返回。呼叫點接近零改動，但需定義不支援時 `fcmToken` 的回傳值，且 `BannerAD` 的 50dp 佔位要在元件內改為不佔位；Drawer 仍須在呼叫點判斷。
  - (C) 混合。
- **Web 案例的測法**：能力判斷接受可注入的 `isWeb`／`platform` 輸入（預設 `kIsWeb`／`defaultTargetPlatform`），或改跑 `flutter test --platform chrome`（Web target 尚未建立，可行性待評估）。
- **`NotificationSetup` 守在派發點（`main_page.dart:46`）或 handler（`main_bloc.dart:91`）**。
- **App Check 的 iOS／macOS 分岔**：在 `main.dart` 就地寫，或由閘門所在處提供（影響 AC-5 的檔案數與 AC-8 的測試方式）。

---

## 7. 後續建議（不屬本項，留作記錄）

1. **Web 啟動期的生物辨識呼叫**（§5.6）：Web 線承接，或由使用者決定是否併入本項。
2. **E-9.3 完成後翻轉 Web 的地圖能力**：Maps JS API key 就緒後只需改能力判斷一處。
3. **刪除 App Open 廣告死碼**：`component/ad/app_open_ad.dart`、`app_open_ad_state.dart`、`app_lifecycle_reactor.dart`，以及 `main_page.dart:31,239-244` 的 `AppOpenADEvent` 空實作（另案，零呼叫已實查）。
4. **E-9.4a 實測清單補上**：macOS release 的 App Check token 取得、App Attest entitlement 是否必要、fallback 在 attestation 失敗時的實際行為（§5.5）。
5. **`main.dart:65` 裸 `catch`**：改為具體例外型別，避免吞掉 `Error`（如本項發現的 FCM `ArgumentError` 就是被它吞掉才一直沒人發現）。
