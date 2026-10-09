# 實作計畫：A-9.2 平台能力閘門（AdMob／推播／地圖模式）與 macOS App Check provider

- **項目編號**：A-9.2
- **日期**：2026-10-09
- **對應規格**：`docs/features/2026-10-09-a-9-2-platform-capability-gate.md`（已確認）
- **Effort**：0.5d
- **工作目錄**：`/Users/yomiry/StudioWorkspace/Finding-Restaurant-Flutter/flutter_restaruant/flutter_restaruant`
- **實查基線**：`chore/202610/140-macos-deployment-target-14` @ `65a9852`
- **已定案（不再討論）**：生物辨識（含規格 §5.6 Web 啟動期 `getAvailableBiometrics()`）不在本項；macOS 與 Web 都進閘門（先判 `kIsWeb`，白名單 android／iOS）；App Check 只有 macOS release 換成 `AppleAppAttestWithDeviceCheckFallbackProvider`，iOS 維持 `AppleAppAttestProvider`，debug 不動。

> 本文件只談 **How**。What／Why 見規格，不在此重述。

---

## 0. 實作前基線（2026-10-09 實測）

| 指標 | 基線實測值 | 目標值 |
| :--- | :--- | :--- |
| AC-1 `flutter analyze` | `No issues found!`（11.1s） | 同 |
| AC-2 `flutter test` | **All tests passed!（293 passed）** | ≥ 307 passed（新增 14 個 case），0 failed |
| AC-4 五個呼叫點的平台判斷行數 | **0** | 0 |
| AC-5 `lib/` 含 `defaultTargetPlatform`／`kIsWeb` 的檔案 | **6 檔**（同規格 §3.1 AC-5 清單） | 8 檔（＋閘門檔、＋`main.dart`） |
| 工作樹 | 僅 `?? docs/features/2026-10-09-a-9-2-...md` | 只多出本計畫列出的檔案 |

**測試骨架已先行驗證（probe）**：在 `test/` 放一個臨時 probe 跑完即刪，工作樹已確認還原。目的是確認 T3 的 `MainPage` 測試在**改動前**真的會紅、而且紅的原因正確：

- android 案例：現況即綠。`BannerAD` 存在，`NotificationSetup`、`FetchSearchInfo` 各派發 1 次。
- macOS 案例：現況**紅**，兩個失敗正好是要修的 bug：
  - `Bad state: GetIt: Object/factory with type BannerADState is not registered inside GetIt.`（規格 §5.3）
  - `Expected: empty / Actual: [NotificationSetup]`
- record 的結構相等比對可用（T1 的矩陣斷言會用到）。
- ⚠️ 踩到一個坑：註冊了 handler 的 bloc，若在 `testWidgets` 本體內 `await bloc.close()`，會在 fake async 下**永久卡住**。必須改用 `addTearDown(bloc.close)`。T3 程式碼已照此寫。

---

## 1. 資料結構：單一能力閘門

### 1.1 位置與形狀

- **檔案**：`lib/features/utils/platform_capabilities.dart`（新檔），由 `lib/features/utils/utils_barrel.dart` 轉出。
- **選這個位置的理由**：
  - 呼叫點裡，`main_page.dart:10`、`restaurant_detail_page.dart:9` 已經 import `utils_barrel`，零新 import。
  - `main.dart` 與 `drawer_widget.dart` 各需補 1 行 import。實查 `flutter_inspector_kit`／`flutter_platform_widgets`／`logger` 都沒有與 `Utils`／`ViewUtils`／`Tuple*` 同名的符號，不會撞名。
- **API**：一個純函式，回傳一筆 record，也就是能力矩陣的一列。

```dart
import 'package:flutter/foundation.dart';

/// 平台能力閘門：回答「此平台有沒有廣告／推播／地圖模式」的唯一一處。
///
/// 三項目前同為「原生 Android 或原生 iOS」，但成立理由不同（AdMob 套件只支援
/// android／ios；D-9.7 macOS 不做推播；Web 地圖待 E-9.3 的 Maps JS API key）。
/// 呼叫點只讀能力名稱、不讀平台名稱，日後翻轉某一項只改這裡。
///
/// [isWeb] 僅供測試注入：`kIsWeb` 是編譯期常數，VM 測試下恆為 false。
({bool ads, bool pushNotifications, bool mapMode}) platformCapabilities({
  bool isWeb = kIsWeb,
}) {
  final platform = defaultTargetPlatform;
  // 先判 Web：Web 上 defaultTargetPlatform 是瀏覽器所在 OS，行動瀏覽器會
  // 回報 android／iOS。白名單：windows／linux／fuchsia 與未來新平台一律關閉。
  final nativeMobile =
      !isWeb &&
      (platform == TargetPlatform.android || platform == TargetPlatform.iOS);
  return (
    ads: nativeMobile,
    pushNotifications: nativeMobile,
    mapMode: nativeMobile,
  );
}
```

### 1.2 為什麼是這個形狀

| 決策 | 理由 |
| :--- | :--- |
| **回傳 record，不是三個 getter** | 能力矩陣本身就是「平台 → 3 個布林」。一個函式回傳一整列，測試一行斷言就鎖住一整列：`expect(platformCapabilities(isWeb: true), (ads: false, pushNotifications: false, mapMode: false))`。E-9.3 要翻轉 Web 地圖時，只改這個函式裡 `mapMode:` 那一行。style guide §5.4 允許用 record 回傳多個值，這裡也是呼叫點讀完即丟的短生命週期組合值。 |
| **不用 class／interface／DI** | 規格 §6.1-6 已禁止。只有一個實作，不需要介面。 |
| **`isWeb` 以具名參數注入，預設 `kIsWeb`** | `kIsWeb` 是 `const`（Flutter SDK `foundation/constants.dart:83`），可以直接當預設值。正式程式碼一律不傳這個參數。 |
| **平台不另開參數** | 規格 AC-6 指定用 `debugDefaultTargetPlatformOverride`。`_platform_io.dart:35-37` 在 `kDebugMode` 下會讀這個覆寫，plain `test()` 也有效。多開一個 `platform` 參數是 YAGNI。 |
| **不快取（不用 `static final`）** | 快取後，widget 測試裡的平台覆寫就失效了。每次呼叫只是兩次比較。release AOT 下 `defaultTargetPlatform` 標了 `@pragma('vm:platform-const-if', !kDebugMode)`，連同 `kIsWeb` 都會被常數摺疊，執行期成本為零。 |
| **`\|\|` 兩個 `==`，不用 Set／switch** | 沿用 A-9.1 `third_party_sign_in_widget.dart` 的寫法：更笨，但更清楚。 |

### 1.3 測試怎麼注入 Web／平台

| 測試層級 | Web | 平台 |
| :--- | :--- | :--- |
| T1 單元（能力矩陣） | `platformCapabilities(isWeb: true / false)` 明確傳入 | `debugDefaultTargetPlatformOverride` ＋ `finally` 復原 |
| T2／T3 widget（Drawer、MainPage） | 不注入（走預設 `kIsWeb`，VM 下為 false）。Web 列已由 T1 鎖住，widget 測試只驗接線 | 同上 |
| T5 單元（App Check） | 不適用（Web 忽略 `providerApple`，見 §7） | 同上 |

**天花板**：預設值 `= kIsWeb` 本身沒有任何 VM 測試能驗。即使有人把它改成 `= false`，所有測試照樣綠燈。這部分由 code review 守住，等 E-9.2 首次 `flutter build web` 時才會被實際執行到。

---

## 2. trade-off 決策（規格 §6.2 逐項）

### 2.1 守衛放哪：採 (A) 守在呼叫點

| 方向 | 評估 |
| :--- | :--- |
| **(A) 呼叫點（🟢 採用）** | 實查每個平台限定 API **剛好只有 1 個呼叫點**，見下表。 |
| (B) 下沉到元件 | ❌ 守衛數量跟 (A) 一樣（都是 1 個呼叫點），卻要多發明語意：<br>- `fcmToken` 在不支援時要回傳什麼。<br>- `BannerAD` 的 `adState` 是 required，`main_page.dart:83` 的 `getIt<BannerADState>()` 照樣會拋錯（§5.3），所以 MainPage 還是得守。<br>- `BannerAD` 的 50dp 不變式（`banner_ad_test.dart:12-36`）要為了平台開例外。<br>- Drawer 仍然只能守在呼叫點。<br>結果 B 實際上會退化成 C。 |
| (C) 混合 | ❌ 沒有任何一項因為「多個呼叫者共用」而值得下沉，混合只會多一種模式。 |

| 平台限定 API | 唯一呼叫點 |
| :--- | :--- |
| `MobileAds.instance.initialize()` | `main.dart:32` |
| `BannerAD` | `main_page.dart:83` |
| `IntersitialAD.load()` | `restaurant_detail_page.dart:51` |
| `FcmManager().init()` | `main.dart:64` |
| `requestPermission()` 與 `fcmToken` | `main_bloc.dart:94-95`，只能經由 `main_page.dart:46` 派發的 `NotificationSetup` 觸發 |
| 地圖切換項 | `drawer_widget.dart:71-79` |

「一處守衛好過每個呼叫者各守一次」這個論點，前提是有多個呼叫者，這裡不成立。(A) 讓所有元件維持平台無關，既有元件測試一行都不用動。

### 2.2 Web 案例的測法：採「可注入 `isWeb`」

- `flutter test --platform chrome`：❌ 不採用。
  - repo 沒有 `web/`，CI 也沒有 Chrome。
  - 測試若 import 到廣告元件，會被 `google_mobile_ads` 的 `dart:io` 擋在 Web 編譯階段。
  - 就算跑得起來，測到的也只有「這台瀏覽器所在的 OS」，三個 Web 列跑不齊。
- 注入參數：零基礎設施、結果確定，而且三個 Web 案例**真的被執行**（AC-6）。天花板見 §1.3。

### 2.3 `NotificationSetup` 守在哪：採派發點 `main_page.dart:46`

| 選項 | 評估 |
| :--- | :--- |
| **派發點（🟢）** | - `main_page.dart` 本來就要為 Banner 改動，`main_bloc.dart` **零 diff**。<br>- 可以直接觀察：T3 的 `MainPage` 測試用一個會記錄事件的 fake bloc，斷言 macOS 只派發 `[FetchSearchInfo]`，android 派發 `[NotificationSetup, FetchSearchInfo]`（順序也一起鎖住）。 |
| handler `main_bloc.dart:91` | 能保護未來可能出現的其他派發者，但目前只有 1 個（YAGNI）。測試只能靠「Firebase 未初始化時 `FirebaseMessaging.instance` 拋 `[core/no-app]`」這個第三方副作用來間接觀察，比較脆弱。 |

**天花板**：若日後出現第二個派發 `NotificationSetup` 的地方，就把守衛移進 handler。

### 2.4 App Check 的 iOS／macOS 分岔：採 `main.dart` 內的頂層純函式，加測試

| 選項 | 評估 |
| :--- | :--- |
| 就地寫在 `activate(...)` 參數裡的三元式 | `lib/` 的 diff 最小，只有 4 行。但 AC-8 只能靠 code review。規格 §5.4「把 fallback 套到 iOS」是三大破壞風險之一，而且這是安全路徑，不應零自動化證據。 |
| 放到閘門檔 | ❌ 會讓只依賴 `foundation` 的能力閘門去 import `firebase_app_check`。App Check provider 是「這個平台用哪種證明」，不是「有沒有某項能力」，概念不合。好處只是 AC-5 少算 1 檔，不值得。 |
| **`main.dart` 頂層 `@visibleForTesting` 函式（🟢）** | 就在 `activate` 旁邊，比放到閘門檔更貼近使用處。測試直接 import `package:flutter_restaruant/main.dart`，有先例：`test/app_theme_platform_test.dart:7`。`lib/` 只比就地寫法多 4 行，換到 AC-8 release 列的自動化鎖。AC-5 計為 8 檔，剛好等於上限，而規格明文允許 `main.dart` 為這個分岔計入。 |

只鎖 release 列的理由：
- debug 分支（`main.dart:47-51`）與 `providerAndroid` 一字不動，由 diff 審查確認（T10）。
- Web 的 `activate` 只讀 `webProvider`（`firebase_app_check_web` 0.2.6+1 `firebase_app_check_web.dart:138`），`providerApple` 改成什麼都不影響 Web。

### 2.5 Banner 測試層級：採 `MainPage` widget 測試（AC-7）

規格擔心 `MainPage` 牽涉 `BlocProvider` 與 `getIt`，測試成本太高。probe 已實證成本可控：

- 用 `_RecordingMainBloc extends Bloc<MainEvent, MainState> implements MainBloc`，沿用 `main_page_content_widget_test.dart:10-12` 的 fake bloc 先例。
  - 以 `on<MainEvent>((_, __) {})` 吃掉所有事件，滿足 bloc 9.2.1 `add()` 對已註冊 handler 的 debug 斷言（`bloc.dart:84-94`）。
  - 覆寫 `onEvent` 同步記錄事件（`bloc.dart:96`）。
- 因為所有事件都被吃掉：geolocator、FCM、Yelp 全都不會被碰到。
- 這個層級能同時驗三件事，比拆一個新的 `BannerADSlot` 元件（新增公開 API）更省：
  - 取用端與能力同源（§5.3：macOS 下 getIt **未註冊**仍不崩）
  - 不佔位（`Scaffold.bottomNavigationBar == null`）
  - 推播派發

---

## 3. 檔案異動清單（行號皆已對照 `65a9852` 實查）

### 3.1 `lib/`（6 檔：1 新、5 改）

| 檔案:行 | 現狀 | 目標 | 任務 |
| :--- | :--- | :--- | :--- |
| `lib/features/utils/platform_capabilities.dart`（新） | — | §1.1 全文 | T1 |
| `lib/features/utils/utils_barrel.dart:1` | `export 'tuple.dart';` 為首行 | 其前插入 `export 'platform_capabilities.dart';` | T1 |
| `lib/flow/main/view/drawer_widget.dart:4` 之後 | — | 插入 `import '../../../features/utils/utils_barrel.dart';` | T2 |
| `lib/flow/main/view/drawer_widget.dart:9` | doc 列舉「檢視模式切換」 | 其後補一行 `/// 檢視模式（列表／地圖）切換僅在具地圖模式能力的平台顯示（見 [platformCapabilities]）。`（AC-10） | T2 |
| `lib/flow/main/view/drawer_widget.dart:71` | `ListTile(` 恆顯示 | 前置 `if (platformCapabilities().mapMode)`（collection-if，`:71-79` 的 ListTile 本體不動） | T2 |
| `lib/flow/main/view/main_page.dart:46` | `_mainBloc.add(const NotificationSetup());` | 包進 `if (platformCapabilities().pushNotifications) { ... }` | T3 |
| `lib/flow/main/view/main_page.dart:81-84` | `bottomNavigationBar: SafeArea(top: false, child: BannerAD(adState: getIt<BannerADState>()))` | `bottomNavigationBar: platformCapabilities().ads ? SafeArea(...原樣...) : null` | T3 |
| `lib/main.dart:18` 之後 | — | 插入 `import 'features/utils/utils_barrel.dart';` | T4 |
| `lib/main.dart:31-33` | 無條件 `MobileAds.instance.initialize()` ＋ `registerSingleton<BannerADState>` | `final capabilities = platformCapabilities();` ＋ `if (capabilities.ads) { 原兩行 }` | T4 |
| `lib/main.dart:62-64` | `await FcmManager().init();` | `if (capabilities.pushNotifications) { await FcmManager().init(); }`（仍在 `try` 內、仍在 `runApp` 前 `await`） | T4 |
| `lib/main.dart:54` | `providerApple: const AppleAppAttestProvider(),` | `providerApple: releaseAppleAppCheckProvider(),` | T5 |
| `lib/main.dart:70` 之後（`main()` 結尾與 `FindingRestaruantApp` 之間） | — | 新增頂層 `@visibleForTesting AppleAppCheckProvider releaseAppleAppCheckProvider()` | T5 |
| `lib/flow/restaurant/view/restaurant_detail_page.dart:49-52` | `if (AdCounterManager().decrementAndCheckShouldShowAd()) { // iOS DetailPage才有全屏AD ... }` | `if (platformCapabilities().ads && AdCounterManager().decrementAndCheckShouldShowAd())`，並更正註解（AC-10） | T6 |

**零改動（刻意）**：`main_bloc.dart`、`fcm_manager.dart`、`banner_ad.dart`、`interstitial_ad.dart`、3 個 `*_ad_state.dart`、`splash_page.dart`、`main_page_content_widget.dart`、`map_widget.dart`、`pubspec.yaml`、`pubspec.lock`、`macos/**`。

### 3.2 `test/`（3 新、1 追加）

| 檔案 | 動作 | case 數 | 任務 |
| :--- | :--- | :--- | :--- |
| `test/features/utils/platform_capabilities_test.dart` | 新增 | 9 | T1 |
| `test/flow/main/view/drawer_widget_test.dart` | 在 `main()` 尾端（`:86` 之後）**追加** 1 個 `testWidgets`；`:8-86` 既有測試一字不動 | +1 | T2 |
| `test/flow/main/view/main_page_test.dart` | 新增 | 2 | T3 |
| `test/app_check_provider_test.dart` | 新增 | 2 | T5 |

---

## 4. 任務拆分

「小改動」欄的判準：`lib/` diff 只動單一檔、≤ 20 行、且無公開 API 變更（測試檔不計入）。

| 任務 | 小改動？ |
| :--- | :--- |
| T1 | 否（2 檔、新增公開函式） |
| T2 | **是** |
| T3 | **是** |
| T4 | **是** |
| T5 | 否（新增公開頂層符號） |
| T6 | **是** |
| T7–T10 | 不適用（無手寫 diff） |

### T1：能力閘門 ＋ 能力矩陣測試（AC-6）

- **檔案**：
  - `test/features/utils/platform_capabilities_test.dart`（新）
  - `lib/features/utils/platform_capabilities.dart`（新）
  - `lib/features/utils/utils_barrel.dart`（+1 行）
- **小改動**：否（2 個 `lib/` 檔，新增公開函式 `platformCapabilities`）
- **步驟 1｜先寫測試（紅）**：

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_restaruant/features/utils/utils_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

/// 鎖住能力矩陣（規格 §1.4、AC-6）。
///
/// Web 列以 `isWeb: true` 注入：`kIsWeb` 是編譯期常數，VM 測試下恆為 false，
/// 但「行動瀏覽器回報 android／iOS」正是最該擋的情境（規格 §5.2），不得略過。
class _Data {
  static const all = (ads: true, pushNotifications: true, mapMode: true);
  static const none = (ads: false, pushNotifications: false, mapMode: false);

  static const rows = [
    (isWeb: false, platform: TargetPlatform.android, expected: all),
    (isWeb: false, platform: TargetPlatform.iOS, expected: all),
    (isWeb: false, platform: TargetPlatform.macOS, expected: none),
    (isWeb: false, platform: TargetPlatform.windows, expected: none),
    (isWeb: false, platform: TargetPlatform.linux, expected: none),
    (isWeb: false, platform: TargetPlatform.fuchsia, expected: none),
    (isWeb: true, platform: TargetPlatform.android, expected: none),
    (isWeb: true, platform: TargetPlatform.iOS, expected: none),
    (isWeb: true, platform: TargetPlatform.macOS, expected: none),
  ];
}

void main() {
  group('platformCapabilities 能力矩陣', () {
    for (final row in _Data.rows) {
      test('isWeb=${row.isWeb}, ${row.platform} → ${row.expected}', () {
        debugDefaultTargetPlatformOverride = row.platform;
        try {
          expect(platformCapabilities(isWeb: row.isWeb), row.expected);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  });
}
```

- **驗證紅**：`rtk flutter test test/features/utils/platform_capabilities_test.dart`，預期編譯失敗（`platformCapabilities` 未定義）。
- **步驟 2｜實作**：
  - 寫入 §1.1 的 `platform_capabilities.dart`。
  - 在 `utils_barrel.dart` 首行插入 `export 'platform_capabilities.dart';`（字母序在 `tuple.dart` 之前）。
- **驗證綠**：同一指令，9 passed。
- **對應 AC**：AC-6（含三個 Web 列）

### T2：Drawer 地圖切換閘門 ＋ doc 同步（AC-7 drawer、AC-10）

- **檔案**：
  - `test/flow/main/view/drawer_widget_test.dart`（追加）
  - `lib/flow/main/view/drawer_widget.dart`
- **小改動**：**是**（約 12 行，含 formatter 對 ListTile 的重新縮排；建構式不變）
- **前置**：T1
- **步驟 1｜先寫測試（紅）**：
  - 檔頭補 `import 'package:flutter/foundation.dart';`。
  - 在 `main()` 內、既有 `testWidgets` 之後追加：

```dart
  testWidgets('macOS 無地圖模式能力：不顯示列表／地圖切換項', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.delegate.supportedLocales,
          theme: AppThemeData.materialLight,
          home: Scaffold(
            drawer: DrawerWidget(
              isListMode: true,
              onKeywordSearch: () {},
              onFilterRules: () {},
              onToggleViewMode: () {},
              onMapMyLoc: () {},
              onFavorites: () {},
              onSettings: () {},
            ),
            body: const SizedBox(),
          ),
        ),
      );
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(5));
      // Icons.map 只屬於切換項（定位重置用 Icons.navigation）。
      expect(find.byIcon(Icons.map), findsNothing);
      expect(find.text(S.current.map_mode), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
```

- **驗證紅**：`rtk flutter test test/flow/main/view/drawer_widget_test.dart`，預期新 case 失敗（Expected: exactly 5 / Actual: 6）。既有 case 仍綠。
- **步驟 2｜實作**：
  - `drawer_widget.dart:4` 之後補 `import '../../../features/utils/utils_barrel.dart';`。
  - `:71` 的 `ListTile(` 前加 `if (platformCapabilities().mapMode)`。
  - `:9` 之後補 doc 一行（§3.1）。
- **驗證綠**：同一指令 2 passed，且 `:45` 的 `findsNWidgets(6)` **原樣**通過（預設平台為 android）。
- **對應 AC**：AC-7（drawer）、AC-10（doc）、AC-2（`:45` 回歸）

### T3：MainPage 的 Banner 與 NotificationSetup 閘門（AC-7 banner、§5.3 取用端）

- **檔案**：
  - `test/flow/main/view/main_page_test.dart`（新）
  - `lib/flow/main/view/main_page.dart`
- **小改動**：**是**（約 8 行）
- **前置**：T1
- **步驟 1｜先寫測試（紅；probe 已實證會紅在正確原因）**：

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_restaruant/component/component_barrel.dart';
import 'package:flutter_restaruant/di/di_barrel.dart';
import 'package:flutter_restaruant/flow/main/bloc/bloc_barrel.dart';
import 'package:flutter_restaruant/flow/main/view/view_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 只記錄派發事件、不執行任何邏輯的 MainBloc。
///
/// bloc 的 `add()` 在 debug 下斷言 handler 已註冊，故以 `on<MainEvent>` 吃掉
/// 所有事件（geolocator／FCM／Yelp 皆不會被觸及）；`onEvent` 於 `add()` 內
/// 同步呼叫，記錄不需等待事件迴圈。
class _RecordingMainBloc extends Bloc<MainEvent, MainState>
    implements MainBloc {
  _RecordingMainBloc() : super(const MainInitial()) {
    on<MainEvent>((_, __) {});
  }

  final List<Type> dispatched = [];

  @override
  void onEvent(MainEvent event) {
    super.onEvent(event);
    dispatched.add(event.runtimeType);
  }
}

void main() {
  Future<_RecordingMainBloc> pumpMainPage(WidgetTester tester) async {
    final bloc = _RecordingMainBloc();
    // 不可在測試本體 await close()：已註冊 handler 的 bloc 在 fake async 下會卡住。
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.delegate.supportedLocales,
        home: BlocProvider<MainBloc>.value(
          value: bloc,
          child: const MainPage(),
        ),
      ),
    );
    return bloc;
  }

  testWidgets('macOS：不取 BannerADState、廣告條不佔位、不派發 NotificationSetup', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      // 刻意不註冊 BannerADState：MainPage 若仍向 getIt 取用會拋 StateError
      // ——main.dart 在同一平台略過了註冊（規格 §5.3）。
      final bloc = await pumpMainPage(tester);

      expect(find.byType(BannerAD), findsNothing);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).bottomNavigationBar,
        isNull,
      );
      expect(bloc.dispatched, [FetchSearchInfo]);

      await tester.pumpWidget(const SizedBox());
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('android：BannerAD 照常、NotificationSetup 照常先於 FetchSearchInfo', (
    tester,
  ) async {
    // 永不完成的初始化：BannerAD 停在佔位狀態，不碰 AdMob platform channel。
    getIt.registerSingleton<BannerADState>(
      BannerADState(Completer<InitializationStatus>().future),
    );
    addTearDown(getIt.reset);

    final bloc = await pumpMainPage(tester);

    expect(find.byType(BannerAD), findsOneWidget);
    expect(bloc.dispatched, [NotificationSetup, FetchSearchInfo]);

    await tester.pumpWidget(const SizedBox());
  });
}
```

- **驗證紅**：`rtk flutter test test/flow/main/view/main_page_test.dart`，預期：
  - macOS case 失敗：`GetIt ... BannerADState is not registered`，以及 `dispatched` 含 `NotificationSetup`。
  - android case 綠：鎖住行動版現況。
- **步驟 2｜實作**：`main_page.dart` 的 `:10` 已 import `utils_barrel`，不需補 import。
  - `:46` 改為：
    ```dart
        if (platformCapabilities().pushNotifications) {
          _mainBloc.add(const NotificationSetup());
        }
    ```
  - `:81-84` 改為：
    ```dart
          bottomNavigationBar: platformCapabilities().ads
              ? SafeArea(
                  top: false,
                  child: BannerAD(adState: getIt<BannerADState>()),
                )
              : null,
    ```
- **驗證綠**：同一指令 2 passed。
- **對應 AC**：AC-7（banner）、§5.3（取用端與能力同源）、§5.1（行動版事件順序不變）

### T4：`main.dart` 的 AdMob 註冊與 FCM 初始化閘門（§5.3 註冊端、§5.1）

- **檔案**：`lib/main.dart`
- **小改動**：**是**（約 12 行）
- **前置**：T1。與 T5 同檔，須**序列**執行（先 T4 後 T5，或反之，不可並行）。
- **步驟 1｜先寫測試**：**不適用**。`main()` 會實際呼叫 Firebase、MobileAds 等 platform channel，無法單元化。
  - 註冊端與 T3 鎖住的取用端讀同一個 `ads` 能力，取用端已有自動化證據。
  - 註冊端由 code review 加 AC-9 手動觀察確認。
- **步驟 2｜實作**：
  - `:18` 之後補 `import 'features/utils/utils_barrel.dart';`。
  - `:31-33` 改為：
    ```dart
      final capabilities = platformCapabilities();

      // AdMob 只有 Android／iOS 原生實作。註冊與 MainPage 的取用讀同一個能力，
      // 不支援的平台兩端一起略過（規格 §5.3）。
      if (capabilities.ads) {
        final initFuture = MobileAds.instance.initialize();
        getIt.registerSingleton<BannerADState>(BannerADState(initFuture));
      }
    ```
  - `:62-64` 改為：
    ```dart
        // FCM 推播：註冊前景／背景訊息處理。需在 runApp 前完成，
        // 才能讀到「點推播冷啟動」的店家，供 SplashPage 跳頁。
        // 無推播能力的平台略過，initialArguments 恆為 null，SplashPage 走一般分支。
        if (capabilities.pushNotifications) {
          await FcmManager().init();
        }
    ```
- **驗證**：
  - `rtk flutter analyze`：`No issues found!`。
  - **人工核對 §5.1**：`MobileAds.instance.initialize()` 仍在 `try`／`Future.wait` **之前**發出；`FcmManager().init()` 仍在 `try` 內、`runApp` 前被 `await`；兩者都沒有被改成 `unawaited` 或搬動位置。
- **對應 AC**：AC-9（啟動無 AdMob／FCM 錯誤）、§5.1、§5.3

### T5：App Check release 的 iOS／macOS 分岔（AC-8）

- **檔案**：
  - `test/app_check_provider_test.dart`（新）
  - `lib/main.dart`
- **小改動**：否（`lib/` 約 10 行、單檔，但新增公開頂層符號 `releaseAppleAppCheckProvider`，雖然標了 `@visibleForTesting`）
- **前置**：T1 不需要；只需與 T4 序列（同檔）。
- **步驟 1｜先寫測試（紅）**：

```dart
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_restaruant/main.dart';
import 'package:flutter_test/flutter_test.dart';

/// 鎖住 AC-8 的 release 列：`providerApple` 同時作用於 iOS 與 macOS，
/// fallback provider 只能給 macOS（規格 §5.4：套到 iOS 會改變 iOS 行為，
/// 且需另在 Console 登記 DeviceCheck 金鑰）。debug 分支與 providerAndroid
/// 未改動，由 diff 審查確認。
void main() {
  test('iOS release 維持 AppleAppAttestProvider', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      expect(releaseAppleAppCheckProvider(), isA<AppleAppAttestProvider>());
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('macOS release 改用 AppleAppAttestWithDeviceCheckFallbackProvider', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      expect(
        releaseAppleAppCheckProvider(),
        isA<AppleAppAttestWithDeviceCheckFallbackProvider>(),
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
```

> 兩個 provider 類別是兄弟關係（都直接 `extends AppleAppCheckProvider`，`apple_providers.dart:44-55`），`isA<AppleAppAttestProvider>()` 不會誤接 fallback。三個類別皆由 `firebase_app_check` 0.4.8 `lib/firebase_app_check.dart:19,22,23` 轉出，零新相依。

- **驗證紅**：`rtk flutter test test/app_check_provider_test.dart`，預期編譯失敗（`releaseAppleAppCheckProvider` 未定義）。
- **步驟 2｜實作**：
  - `:54` 改為 `providerApple: releaseAppleAppCheckProvider(),`。
  - 在 `main()` 結尾（`:70`）與 `class FindingRestaruantApp` 之間新增下列函式。`main.dart:6` 已 import `foundation.dart`，不需補 import。

```dart
/// release 的 `providerApple`。
///
/// 此參數同時作用於 iOS 與 macOS。多數 Mac 不支援 App Attest，macOS 改用
/// 於 activate 時會退回 DeviceCheck 的 provider；iOS 維持 App Attest。
@visibleForTesting
AppleAppCheckProvider releaseAppleAppCheckProvider() =>
    defaultTargetPlatform == TargetPlatform.macOS
        ? const AppleAppAttestWithDeviceCheckFallbackProvider()
        : const AppleAppAttestProvider();
```

- **驗證綠**：同一指令 2 passed。
- **對應 AC**：AC-8（release 列：自動化；debug 列與 Android：T10 diff 審查）、AC-11

### T6：詳情頁插頁廣告閘門 ＋ 註解更正（AC-10）

- **檔案**：`lib/flow/restaurant/view/restaurant_detail_page.dart`
- **小改動**：**是**（約 5 行）
- **前置**：T1
- **步驟 1｜先寫測試**：**不適用**，理由如下：
  - 要掛載 `RestaurantDetailPage`，得備齊 fake `RestaurantDetailBloc`、`ModalRoute` 的 `Tuple2<RestaurantEntity>` 參數、`Fluttertoast` 等依賴，成本遠高於一個 `&&`。
  - 被讀的能力已由 T1 鎖住。
  - 行為由 AC-9「連續進詳情頁 3 次」手動確認。
- **步驟 2｜實作**：`:9` 已 import `utils_barrel`。`:49-52` 改為：

```dart
    // 插頁廣告（Android／iOS 皆有）：每進詳情頁 3 次載入一次。
    // 無廣告能力的平台不載入、也不消耗計數（&& 短路）。
    if (platformCapabilities().ads &&
        AdCounterManager().decrementAndCheckShouldShowAd()) {
      IntersitialAD(adState: InterstitialADState()).load();
    }
```

- **驗證**：
  - `rtk flutter analyze` 零問題。
  - `rtk proxy grep -n "iOS DetailPage" lib/flow/restaurant/view/restaurant_detail_page.dart`：0 命中。
- **對應 AC**：AC-9（詳情頁無 AdMob 錯誤）、AC-10
- **註記**：行動版 `true && decrement()` 與現況等價。能力判斷放左邊，是為了在 macOS 上連計數器的副作用都不發生。

### T7：格式化

- **動作**：`rtk dart format lib/ test/`
- **驗證**：`rtk dart format --output=none --set-exit-if-changed lib/ test/`，exit 0
- **註記**：collection-if、三元式、record 的換行位置都交給 formatter，不要手工硬凹。

### T8：全套機械驗收（AC-1、AC-2、AC-4、AC-5、AC-11）

```bash
# AC-1：預期 No issues found!
flutter analyze

# AC-2：預期 All tests passed!，≥ 307 passed（基線 293 + 新增 14），0 failed
flutter test

# AC-4：預期 0
grep -n -e "defaultTargetPlatform" -e "kIsWeb" -e "TargetPlatform\." \
  lib/flow/main/view/main_page.dart \
  lib/flow/main/view/drawer_widget.dart \
  lib/flow/restaurant/view/restaurant_detail_page.dart \
  lib/flow/main/bloc/main_bloc.dart \
  lib/flow/splash/view/splash_page.dart \
  | wc -l

# AC-5：預期恰為 8 檔 = 基線 6 檔 + lib/features/utils/platform_capabilities.dart + lib/main.dart
grep -rln --include="*.dart" -e "defaultTargetPlatform" -e "kIsWeb" lib/ | sort

# AC-11：預期無輸出
git diff --stat -- pubspec.yaml pubspec.lock
```

- **註記**：
  - AC-4／AC-5 的輸出是下判斷用的證據，依 `.claude/rules/rtk-rules.md`，用原生 `grep` 或 `rtk proxy grep`，**不要**用 `rtk grep`（會被壓成摘要）。
  - 若有任何既有測試轉紅，那是 regression，回頭修程式碼，**不准改測試期望值**。

### T9：macOS 本機建置（AC-3）

- **動作**：`flutter build macos`
- **驗證**：
  - 輸出 `✓ Built build/macos/Build/Products/Release/flutter_restaruant.app`。
  - 之後 `rtk git status --short` 只列出本計畫 §3 的檔案；`build/` 已被 gitignore，基線實測不會留下變動。
- **例外處理**：若失敗，先在未改動的基線（`git stash` 前請先徵得使用者同意，或改用另一個 worktree）重現。基線同樣失敗則不計入本項，於 PR 註明（規格 AC-3）。

### T10：人工確認（AC-8 debug 列、AC-9、AC-10、AC-11）

- **diff 審查**（`rtk git diff`，只讀）：
  - `main.dart:47-51` debug 分支一字未動；`providerAndroid` 兩處一字未動（AC-8）。
  - `drawer_widget.dart` doc 與 `restaurant_detail_page.dart` 註解已更正（AC-10）。
  - `pubspec.*` 不在 diff 中（AC-11）。
- **AC-9 macOS 執行觀察**（`flutter run -d macos`，debug；從登入頁的訪客入口進主頁）：
  - console 無 `MissingPluginException`（google_mobile_ads）
  - 無 `Initialization failed`＋`macOS settings must be set...`
  - 進主頁不跳通知權限詢問
  - 主頁底部無 50dp 空白條
  - Drawer 無「地圖模式」
  - 連進詳情頁 3 次以上，無 AdMob 錯誤
- **註記**：僅檢視，**不執行任何 git 寫入操作**。

---

## 5. 任務相依與並行

```
            ┌─ T2 (drawer)                 ─┐
 T1 (閘門) ─┼─ T3 (main_page)              ─┼─→ T7 (format) ─┬─→ T8 (analyze/test/grep) ─┐
            ├─ T6 (detail page)            ─┤                └─→ T9 (build macos)        ─┴─→ T10 (人工)
            └─ T4 → T5 (main.dart，同檔序列) ─┘
```

| 關係 | 說明 |
| :--- | :--- |
| T1 先行 | 所有呼叫點都讀 `platformCapabilities`。T5 技術上不依賴 T1，但與 T4 同檔。 |
| T2／T3／T6／(T4→T5) 可並行 | 4 條線碰的檔案互不重疊。 |
| T4 與 T5 序列 | 同為 `lib/main.dart`，並行編輯會衝突。 |
| T8 與 T9 可並行 | 兩者唯讀、互不影響；T9 較慢（數分鐘），可先背景啟動。 |
| T10 最後 | 在綠燈之後才審 diff，避免審到還要再改的版本。 |

---

## 6. AC 對照表

| AC | 任務 | 驗證方式 |
| :--- | :--- | :--- |
| AC-1 analyze 零問題 | T8 | `flutter analyze` → `No issues found!` |
| AC-2 測試全綠、不改既有期望值 | T2、T3、T8 | `flutter test` ≥ 307 passed／0 failed；`drawer_widget_test.dart:45` `findsNWidgets(6)` 原樣通過；`drawer_widget_test.dart:8-86` 在 diff 中無 `-` 行 |
| AC-3 `flutter build macos` | T9 | `✓ Built .../flutter_restaruant.app` |
| AC-4 呼叫點不判平台 | T2、T3、T6、T8 | 五檔 grep → `0` |
| AC-5 平台判斷檔案 ≤ 8 | T1、T5、T8 | grep → 恰 8 檔（基線 6＋閘門＋`main.dart`），新增檔不屬 AC-4 五檔 |
| AC-6 能力矩陣（含 3 個 Web 列） | T1 | `platform_capabilities_test.dart` 9 passed |
| AC-7 Drawer 5／6 項 | T2 | macOS 新 case 5 個 ListTile、無 `Icons.map`；android 由既有 `:45` 鎖 6 個 |
| AC-7 Banner 不佔位 | T3 | `main_page_test.dart` macOS：無 `BannerAD`、`bottomNavigationBar == null`、getIt 未註冊不崩；android：`BannerAD` 存在 |
| AC-8 App Check provider | T5、T10 | release iOS／macOS：`app_check_provider_test.dart` 2 passed；debug 列與 Android：T10 diff 審查 |
| AC-9 macOS 執行觀察 | T4、T6、T10 | `flutter run -d macos` 逐項目視 |
| AC-10 註解同步 | T2、T6、T10 | drawer doc 補行；`grep "iOS DetailPage"` → 0 |
| AC-11 無新相依 | T8、T10 | `git diff --stat -- pubspec.yaml pubspec.lock` 無輸出 |

---

## 7. 破壞性分析（Never break userspace）

### 7.1 行動版（Android／iOS 原生）：零行為變化

| 呼叫點 | 行動版下的值 | 等價性 |
| :--- | :--- | :--- |
| `main.dart` AdMob | `capabilities.ads == true` | 同樣兩行、同一位置（`try` 之前）執行；`BannerADState` 照常註冊 |
| `main.dart` FCM | `pushNotifications == true` | 仍在 `try` 內、`runApp` 前 `await`（SplashPage 冷啟動跳頁的前提，`main.dart:62-63`） |
| `main.dart` App Check | iOS → `AppleAppAttestProvider`（T5 測試鎖）；Android 的 `providerApple` 不生效 | `providerAndroid`、debug 分支一字未動 |
| `main_page.dart:46` | `true` | 仍派發 `NotificationSetup`，且仍先於 `FetchSearchInfo`（T3 android case 鎖順序） |
| `main_page.dart:81-84` | `true` | 原樣 `SafeArea(BannerAD)`（T3 android case） |
| `drawer_widget.dart` | `mapMode == true` | 6 項（既有 `:45`） |
| `restaurant_detail_page.dart` | `true && decrement()` | 與 `decrement()` 等價，計數節奏不變 |

### 7.2 既有測試：不需修改任何期望值

| 測試 | 與本項的關係 | 是否需改 |
| :--- | :--- | :--- |
| `test/flow/main/view/drawer_widget_test.dart:8-86` | 預設平台 android，閘門為 true，仍 6 項 | ❌ 不改（只在檔尾**追加** T2 的 case） |
| `test/component/ad/banner_ad_test.dart` | `BannerAD`／`BannerADState` 本體零改動 | ❌ |
| `test/flow/main/view/main_page_content_widget_test.dart` | `MainPageContentWidget` 零改動 | ❌ |
| `test/main_bloc_load_more_test.dart` | `main_bloc.dart` 零改動 | ❌ |
| `test/di_test.dart` | 只驗 `setupInjection()` 的註冊，`BannerADState` 不在其中 | ❌ |
| `test/app_theme_platform_test.dart` | 掛載 `FindingRestaruantApp`，不呼叫 `main()`；只跑 iOS／android | ❌ |
| `test/flow/splash/splash_page_test.dart` | 導向 SignInPage，不碰閘門 | ❌ |

### 7.3 刻意的行為變更（只發生在 macOS 與 Web）

- **macOS**：
  - 不初始化 AdMob、不註冊 `BannerADState`、不 `init()` FCM。
  - 不請求通知權限、不取 token。
  - 主頁無廣告條，Drawer 少地圖切換項，詳情頁不載插頁、不扣計數。
  - release App Check 改用 fallback provider。
- **Web**（Web target 尚未建立，僅程式碼層面）：廣告、推播、地圖切換同 macOS。App Check 不變，因為 Web 的 `activate` 只讀 `webProvider`（`firebase_app_check_web.dart:138`）。
- **連帶自然消失的特殊情況**（規格 §1.4，零改動）：
  - SplashPage 讀 `FcmManager().initialArguments` 恆為 `null`。`FcmManager` 建構不碰 plugin：`_flutterLocalNotificationsPlugin` 是 `late final`（`fcm_manager.dart:33-34`）。
  - `MapWidget` 因 `_isListMode` 無法翻轉而永不建構。

### 7.4 剩餘風險

| 風險 | 緩解 |
| :--- | :--- |
| `isWeb = kIsWeb` 預設值被誤改 | VM 測試抓不到（§1.3 天花板）；code review 加上 E-9.2 首次 Web 建置 |
| `main.dart` 註冊端守衛被誤刪 | 取用端仍讀 `ads`，macOS 會在 MainPage 拋 `StateError`；T3 只鎖取用端，註冊端靠 review 與 AC-9 |
| 日後新增第二個 `NotificationSetup` 派發者 | 守衛移進 `main_bloc.dart:91` handler（§2.3 天花板） |
| AC-5 已達上限 8 檔 | 下一個需要平台判斷的功能，應該優先擴充 `platformCapabilities`，不要另開新檔 |

---

## 8. 明確不做（守住範圍）

| 不做 | 依據 |
| :--- | :--- |
| 生物辨識，含規格 §5.6 Web 啟動期 `getAvailableBiometrics()` | 使用者已決議，留給 Web 線 |
| App Open 廣告死碼刪除（`main_page.dart:31,239-244` 等） | 規格 §4.2、§7-3，另案 |
| 為 macOS 補 `InitializationSettings.macOS` | 違反 D-9.7 |
| 廣告單元 ID 的 else catch-all（3 個 `*_ad_state.dart`） | 規格 §4.2：閘門關閉後這些 getter 永遠不會被求值 |
| `main.dart:65` 的裸 `catch` | 既有技術債，規格 §7-5 |
| `providerWeb`／reCAPTCHA Enterprise | A-9.3b |
| macOS 地圖降級、entitlements | A-9.6 |
| Web 編譯期問題（`google_mobile_ads` 的 `import 'dart:io'`，`ad_instance_manager.dart:23`） | 閘門是**執行期**判斷，不移除 import。Web 編譯閘門屬 E-9.2，本項不宣稱解決 |
| 新增 interface／platform service／DI 註冊；改 `DrawerWidget` 建構式 | 規格 §6.1-6；建構式不變才能讓既有測試零改動 |
| 任何 git 寫入（add／commit／push／stash） | 本階段僅規劃與實作 |

---

## 9. 執行方式選項

| 方式 | 做法 | Trade-off |
| :--- | :--- | :--- |
| **A. 單一 session 循序（🟢 建議）** | 一個 implementer 依 T1→T10 做完。T2／T3／T6 可在同一輪以平行工具呼叫批次編輯 | `lib/` 總 diff 約 60 行、測試約 150 行，協調成本高於改動本身。最省 context |
| **B. subagent-driven** | 派 1 個 implementer subagent 執行 T1–T7，回報後由 caller 執行 T8–T10 驗收 | 多一次交接；換到「實作者不驗自己的工」，AC 驗證較客觀。若在意自驗盲點，選這個 |
| **C. parallel session** | T1 完成後開 4 個 session：T2、T3、T6、T4→T5，匯合後跑 T7–T10 | ❌ 不建議。檔案確實互不重疊、技術上可行，但每條線只有 5–12 行 `lib/` 改動；開 session 與匯合的成本遠超收益，T7 的 format 還得等全部匯合 |

**建議**：採 **A**；若要讓實作與驗收分離，採 **B**。

---

## 10. 完成定義（DoD）

- [ ] T1–T7 完成：
  - `lib/` 1 新檔（`platform_capabilities.dart`）＋ 5 檔修改（`utils_barrel.dart`、`drawer_widget.dart`、`main_page.dart`、`main.dart`、`restaurant_detail_page.dart`。`utils_barrel` 只 +1 行）
  - `test/` 3 新檔 ＋ 1 檔追加
- [ ] AC-1 `No issues found!`
- [ ] AC-2 `All tests passed!`，≥ 307 passed，0 failed，`drawer_widget_test.dart:8-86` 無刪改
- [ ] AC-3 `flutter build macos` 成功
- [ ] AC-4 = `0`
- [ ] AC-5 恰 8 檔，與 §T8 預期清單一致
- [ ] AC-6 9 個 case（含 3 個 Web 列）全綠
- [ ] AC-7 Drawer macOS 5 項；MainPage macOS 無 Banner、`bottomNavigationBar == null`
- [ ] AC-8 release iOS／macOS 測試綠；debug 列與 Android 經 diff 審查未動
- [ ] AC-9 macOS 執行觀察六項皆符合
- [ ] AC-10 兩處註解已同步
- [ ] AC-11 `pubspec.*` 未變
- [ ] `dart format --set-exit-if-changed` exit 0
