# 實作計畫：訪客模式 (Guest Mode)

- 規格來源：`docs/features/2026-07-29-guest-mode.md`（AC-1 ~ AC-8）
- 分支：`feature/clean-arch-alignment`
- 日期：2026-07-29

---

## 0. 前情提要（實作者必讀，不要走回頭路）

規格初稿曾把「訪客會寫入 Firestore 空 doc id」當成核心 bug，**該判斷已被推翻並移出規格**。已 grep 全 codebase 確認：

- 全專案**唯一**的 `ToggleFavor` 派發點是 `lib/component/cell/restaurant_detail/restaurant_head_cell.dart:38`
- `MainBloc` 的 `ToggleFavor`（`main_bloc.dart:67`）**沒有任何 UI 派發**，`RestaurantItemCell` 無最愛按鈕 → 從 UI 無法到達的死碼
- `MainBloc` 不使用 `SignInManager` 的任何登入資訊

**本計畫嚴禁包含**：

- ❌ 為 `MainBloc` / `MainRepo` / `FavorDataSource` 加訪客判斷或防禦分支
- ❌ 修改 `FavorDataSource._uid` 的 `?? ''` 邏輯
- ❌ 任何「防止空 doc id 寫入」的任務

**在唯一入口（`RestaurantHeadCell`）攔截，就是完整的修法。** 不做縱深防禦。

---

## 1. 資料結構與狀態設計

### 1.1 核心決策：訪客旗標放進 `SignInManager`

**決定：訪客旗標作為 `SignInManager` 的一個 `bool` 欄位 + 一個 `SharedPreferences` key，不新增任何類別、interface、Bloc、Event、State。**

理由（三條，都是「消滅特殊情況」而非「增加抽象」）：

1. **與 `accountDto` 天然互斥（AC-2）。** `SignInManager.accountDto` 已經是「登入狀態」的唯一權威。訪客旗標若放在別的類別，就多出一份需要跨物件同步的狀態（R-3）；放在同一個物件裡，互斥規則可以寫成一行 getter：`accountDto == null && _isGuest`。互斥不再靠約定，而是靠資料結構本身保證。
2. **清除點自動收斂（AC-6）。** `signIn()` 與 `signUp()` 兩個方法的**末端都已經統一寫 `accountDto = result.item1`**（`sign_in_manager.dart:53`、`:69`）。這是所有登入路徑（Google / Apple / Facebook / Email / 自動登入 / 生物辨識）的唯一匯流點——因為 `signIn()` 內部是一個 `switch`，六種登入方式全部收斂到同一行賦值。在這兩行旁邊清旗標，就自動涵蓋 AC-6 要求的**所有**成功路徑，且不需要在任何登入按鈕的 callback 寫第二次。
3. **登出點也已經在那裡（AC-7）。** `signOut()`（`:74`）末端的 `accountDto = null` 旁邊清旗標即可。

**被否決的替代方案**：

| 方案 | 否決理由 |
|------|----------|
| 新增 `GuestModeRepository` + `GuestModeRepo` 實作 | 單一實作的 interface，為了讀寫一個 bool 建立兩個檔案 + DI 註冊。純粹的儀式。 |
| 新增 `GuestBloc` / `GuestEvent` / `GuestState` | 旗標讀取是同步的布林查詢，沒有非同步狀態轉換需要建模。Bloc 是為了「事件流 → 狀態流」而存在，這裡兩者都不存在。 |
| 各頁面直接讀 `SharedPreferences` | 直接違反 AC-2「不得各自讀取」，且每個讀取點都是 async，會逼所有頁面加 `FutureBuilder`。 |
| 放進既有的 `SettingsRepo` | 訪客旗標與「設定」無語意關聯，且 `SettingsRepo` 是 `const` class 無法持有快取狀態。 |

### 1.2 非同步載入 vs 同步查詢（本設計最關鍵的一點）

**問題**：`SharedPreferences.getInstance()` 是 `Future`，但旗標查詢會發生在同步的 `build()` 路徑上（`SettingsPage.build`、`RestaurantHeadCell.build` 的 `onTap`）。若讓 getter 回傳 `Future<bool>`，這些頁面全部要包 `FutureBuilder`，diff 會膨脹三倍。

**解法**：**記憶體快取 + App 啟動時預載入**。

- `SignInManager` 持有 `bool _isGuest = false`（記憶體真實來源）
- `main()` 內在 `runApp` 之前 `await SignInManager().loadGuestFlag()`，把磁碟值讀進記憶體一次
- 之後所有查詢走同步 getter `isGuest`，零 `FutureBuilder`
- 寫入時（`markAsGuest()`）**先更新記憶體、再 await 寫磁碟**，記憶體永遠是最新的

`main()` 已經有 `Future.wait([Constants.init(), Firebase.initializeApp(), S.load(...)]).then(...)` 的預載入區塊——**把 `loadGuestFlag()` 加進這個既有的 `Future.wait` 陣列即可**，不新增等待階段、不延後 App 啟動（並行執行）。

> 為什麼值得多寫這 3 行（`_isGuest` 欄位 + `loadGuestFlag()`）：不寫的話，六個呼叫點全部要變成非同步。這是用 3 行換掉約 60 行 `FutureBuilder` 樣板。

### 1.3 最終 API 表面（`SignInManager` 新增的全部內容）

```dart
bool _isGuest = false;

/// 訪客模式：未登入且已選擇以訪客身分瀏覽。與已登入狀態互斥。
bool get isGuest => accountDto == null && _isGuest;

Future<void> loadGuestFlag() async {
  final prefs = await SharedPreferences.getInstance();
  _isGuest = prefs.getBool(Constants.prefKeyGuestMode) ?? false;
}

Future<void> markAsGuest() async {
  _isGuest = true;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(Constants.prefKeyGuestMode, true);
}

Future<void> clearGuestFlag() async {
  _isGuest = false;
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(Constants.prefKeyGuestMode);
}
```

三個方法、一個欄位、一個 getter。**沒有新檔案。**

### 1.4 狀態轉移表

| 事件 | `accountDto` | `_isGuest`（記憶體） | prefs key | `isGuest` 結果 |
|------|--------------|---------------------|-----------|----------------|
| 全新安裝 | null | false | 不存在 | false → SplashPage 去 SignInPage |
| 點「訪客模式」 | null | true | true | true |
| 訪客重啟 App | null | true（`loadGuestFlag` 載入） | true | true → SplashPage 去 MainPage |
| 訪客完成登入 | 非 null | false（`signIn` 清除） | 已移除 | false |
| 正式使用者登出 | null | false（`signOut` 清除） | 已被 `prefs.clear()` 移除 | false |
| 登出後重啟 | null | false | 不存在 | false → SignInPage ✅ AC-7 |

**AC-7 雙重保險**：`SettingsRepo.logout()` 已呼叫 `prefs.clear()`（`settings_repo.dart:17`），會連帶清掉磁碟上的旗標；但**記憶體中的 `_isGuest` 不會被它清掉**，所以 `signOut()` 內仍必須清記憶體。兩者缺一不可——這正是為什麼旗標必須跟 `accountDto` 放在同一個物件。

---

## 2. 檔案異動總覽

| 檔案 | 動作 | Owner 任務 |
|------|------|-----------|
| `lib/utils/constants.dart` | 新增 `prefKeyGuestMode` | **T1（唯一 owner）** |
| `lib/l10n/intl_zh_TW.arb` | 新增 2 個 key | **T2（唯一 owner）** |
| `lib/l10n/intl_en.arb` | 新增 2 個 key | **T2（唯一 owner）** |
| `lib/generated/l10n.dart` | 由 intl_utils 產生 | **T2（唯一 owner）** |
| `lib/manager/sign_in_manager.dart` | 新增旗標欄位與三方法、清除點 | **T3（唯一 owner）** |
| `lib/main.dart` | 預載入旗標 | T4 |
| `lib/flow/splash/view/splash_page.dart` | 啟動分流 | T5 |
| `lib/flow/signinup/view/sign_in_page.dart` | 訪客按鈕 | T6 |
| `lib/component/cell/restaurant_detail/restaurant_head_cell.dart` | 最愛攔截 | T7 |
| `lib/flow/settings/view/settings_page.dart` | 區塊切換 | T8 |
| `test/guest_mode_test.dart` | 新檔 | T9 |

**共享檔案的單一 owner 已標註**：`constants.dart` → T1；`l10n` 三檔 → T2；`sign_in_manager.dart` → T3。其他任務只讀不寫這些檔案。

---

## 3. 任務清單

### T1 — 新增 SharedPreferences key 常數

- **複雜度**：機械性
- **寫入檔案**：`lib/utils/constants.dart`
- **相依**：無（可最先執行）
- **內容**：在 `/// [SharedPreference]` 區塊，`prefKeyBiometricAuthSetting` 下方加一行：

```dart
static const prefKeyGuestMode = 'guest_mode';
```

- **驗收**：`rtk flutter analyze` 通過；`Constants.prefKeyGuestMode` 可被引用。

---

### T2 — 新增多語系字串並重新產生 l10n

- **複雜度**：機械性
- **寫入檔案**：`lib/l10n/intl_zh_TW.arb`、`lib/l10n/intl_en.arb`、`lib/generated/l10n.dart`（產生）
- **相依**：無（可與 T1 並行）
- **內容**：兩個 arb 檔各在 `signin` 區塊末端（`signinup_with_apple_hint_msg` 之後）加入，注意前一行要補逗號：

`intl_zh_TW.arb`：
```json
  "continue_as_guest": "訪客模式",
  "signin_or_signup_title": "登入 / 註冊"
```

`intl_en.arb`：
```json
  "continue_as_guest": "Continue As Guest",
  "signin_or_signup_title": "SignIn / SignUp"
```

- **產生指令**（專案 `pubspec.yaml:122` 已設定 `flutter_intl: arb-dir: lib/l10n, output-dir: lib/generated`）：

```bash
rtk dart run intl_utils:generate
```

若 `intl_utils` 未在 dev_dependencies，改用：
```bash
rtk dart pub global activate intl_utils && rtk dart pub global run intl_utils:generate
```

- **驗收**：`lib/generated/l10n.dart` 出現 `String get continue_as_guest` 與 `String get signin_or_signup_title`；`rtk flutter analyze` 通過。
- **注意**：`l10n.dart` 是產生檔，不可手改。T6 與 T8 依賴此任務的產出。

---

### T3 — `SignInManager` 加入訪客旗標（核心任務）

- **複雜度**：設計判斷
- **寫入檔案**：`lib/manager/sign_in_manager.dart`
- **相依**：T1（需要 `Constants.prefKeyGuestMode`）
- **內容**：
  1. 新增 import：`package:shared_preferences/shared_preferences.dart`、`../utils/constants.dart`
  2. 在 `accountDto` 欄位下方新增 `bool _isGuest = false;`
  3. 新增 §1.3 的 `isGuest` getter 與三個方法
  4. **清除點（AC-6）**：在 `signIn()` 的 `accountDto = signInResult.item1;`（第 53 行）之後、`return` 之前插入：
     ```dart
     if (accountDto != null) {
       await clearGuestFlag();
     }
     ```
  5. 同樣地在 `signUp()` 的 `accountDto = signUpResult.item1;`（第 69 行）之後插入相同三行
  6. **登出點（AC-7）**：在 `signOut()` 末端 `accountDto = null;` 之後插入 `await clearGuestFlag();`

- **關鍵設計約束（不可違反）**：
  - `if (accountDto != null)` 這個判斷**必須保留**——登入失敗時 `accountDto` 為 null，此時若清掉旗標，訪客會因為一次失敗的 Google 登入而被踢回登入頁。這是正當的業務分支，不是補丁。
  - **不要**在 `SignInPage` 的任何 callback 或 `SignInBloc` 內另外清旗標。AC-6 明文要求單一收斂點。
- **驗收**：`rtk flutter analyze` 通過；T9 的單元測試涵蓋此行為。

---

### T4 — App 啟動時預載入旗標

- **複雜度**：機械性
- **寫入檔案**：`lib/main.dart`
- **相依**：T3
- **內容**：於既有的 `Future.wait([...])` 陣列（`main.dart:29-37`）中加入一項，並補上 import `manager/sign_in_manager.dart`：

```dart
  Future.wait([
    Constants.init(),
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
    S.load(ui.PlatformDispatcher.instance.locale),
    SignInManager().loadGuestFlag(),
  ]).then((_) {
```

- **設計理由**：放進既有的 `Future.wait` 是並行執行，不增加啟動延遲；且保證在 `runApp` 之前完成，`SplashPage` 的同步查詢必然拿到正確值。
- **驗收**：`rtk flutter analyze` 通過；App 可正常啟動。

---

### T5 — `SplashPage` 啟動分流（AC-3）

- **複雜度**：整合
- **寫入檔案**：`lib/flow/splash/view/splash_page.dart`
- **相依**：T3、T4
- **內容**：新增 import `../../main/view/main_page.dart` 與 `../../../manager/sign_in_manager.dart`，並將 `initState` 內的導向改為：

```dart
      if (mounted) {
        final routeName = SignInManager().isGuest
            ? MainPage.routeName
            : SignInPage.routeName;
        // ignore: unawaited_futures
        Navigator.of(context).pushReplacementNamed(routeName);
      }
```

- **約束**：`mounted` 檢查必須保留（AC-3 明訂）；`pushReplacementNamed` 語意不變。
- **驗收**：見 §5 的 R-2 驗證步驟（需實機/模擬器驗證，非推論）。

---

### T6 — `SignInPage` 新增訪客模式按鈕（AC-1）

- **複雜度**：整合
- **寫入檔案**：`lib/flow/signinup/view/sign_in_page.dart`
- **相依**：T2（需要 `S.current.continue_as_guest`）、T3（需要 `markAsGuest()`）
- **內容**：新增 import `../../../manager/sign_in_manager.dart`，並在 `show3rdSignInUpBtns()`（第 191 行）的 Column children **最末端**追加：

```dart
        const SizedBox(height: 10),
        PlatformTextButton(
          child: Text(S.current.continue_as_guest,
              style: const TextStyle(
                  fontSize: UIConstants.mFontSize, color: Colors.grey)),
          onPressed: () async {
            await SignInManager().markAsGuest();
            if (!mounted) return;
            // ignore: unawaited_futures
            Navigator.of(context).pushReplacementNamed(MainPage.routeName);
          },
        )
```

- **約束**：
  - **不要**包 `Platform.isIOS` 判斷——AC-1 要求雙平台皆顯示
  - `await` 之後必須 `if (!mounted) return;`（Style Guide §7.5，`_SignInPageState` 是 `State` 所以有 `mounted`）
  - 使用 `pushReplacementNamed` 以符合 AC-1「不留可返回登入頁的堆疊」
  - **不新增** Bloc event。這裡沒有需要進度指示或錯誤處理的非同步流程，走 Bloc 只會多三個檔案的 diff。
- **驗收**：登入頁 Google 按鈕下方出現「訪客模式」；Android 與 iOS 皆可見；點擊後進入 MainPage 且無法返回。

---

### T7 — `RestaurantHeadCell` 最愛攔截（AC-4）

- **複雜度**：整合
- **寫入檔案**：`lib/component/cell/restaurant_detail/restaurant_head_cell.dart`
- **相依**：T3
- **內容**：新增 import `../../../flow/signinup/view/sign_in_page.dart` 與 `../../../manager/sign_in_manager.dart`，將第 38 行的 `onTap` 改為：

```dart
            onTap: () {
              if (SignInManager().isGuest) {
                // ignore: unawaited_futures
                Navigator.of(context).pushNamed(SignInPage.routeName);
                return;
              }
              bloc.add(ToggleFavor(summaryInfo: _summaryInfo));
            },
```

- **設計說明**：
  - 這是 `StatelessWidget`，但**不需要改成 `StatefulWidget`**——`isGuest` 是同步 getter，`onTap` 內沒有 `await`，因此沒有 async gap，`context` 必然有效。這正是 §1.2 選擇同步快取的直接回報。
  - 用 `pushNamed`（非 `pushReplacementNamed`），使用者取消登入時可返回原餐廳頁。
  - 提早 return 的衛語句形式，圖示的 `_summaryInfo.favor` 渲染完全不動 → 自動滿足 AC-4「視覺狀態不得改變」。
  - 非訪客路徑一字未改 → 滿足 AC-4「行為與現況完全相同」。
- **驗收**：訪客點最愛 → 跳登入頁且圖示不變；已登入使用者點最愛 → 行為與改動前相同。

---

### T8 — `SettingsPage` 區塊切換（AC-5）

- **複雜度**：整合
- **寫入檔案**：`lib/flow/settings/view/settings_page.dart`
- **相依**：T2（需要 `S.current.signin_or_signup_title`）、T3
- **內容**：新增 import `../../../manager/sign_in_manager.dart`，並修改 `createLogoutSection()`（第 104 行）為依旗標回傳兩種內容：

```dart
  AbstractSettingsSection createLogoutSection() {
    final child = SignInManager().isGuest
        ? SizedBox(
            height: 50,
            child: PlatformElevatedButton(
                color: ColorName.appPrimaryColor,
                child: Text(S.current.signin_or_signup_title,
                    style: const TextStyle(
                        fontSize: UIConstants.xhFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                onPressed: () => Navigator.of(context)
                    .pushNamed(SignInPage.routeName)),
          )
        : Column(mainAxisSize: MainAxisSize.min, children: [
            // ... 既有的登出按鈕 + 刪除帳戶 GestureDetector 原封不動搬進來
          ]);

    return CustomSettingsSection(
        child: Padding(
            padding: const EdgeInsets.only(left: 25, top: 50, right: 25),
            child: child));
  }
```

- **約束**：
  - 既有的登出 / 刪除帳戶區塊**原封不動**搬進 `else` 分支，一個字都不改 → 滿足 AC-5「非訪客時畫面與現況完全相同」
  - `createHeadSection()` 與 `createInfoSettingsSection()`（版本資訊）不動 → 滿足 AC-5 最後一條
  - 外層的 `Padding` 保持共用，避免兩個分支重複寫版面常數
  - `Navigator.of(context)` 在 `onPressed` 同步呼叫，無 async gap
- **驗收**：訪客進設定頁只看到「登入 / 註冊」，無登出與刪除帳戶；正式使用者畫面與改動前逐像素相同；版本資訊兩種狀態皆顯示。

---

### T9 — 單元測試（AC-8）

- **複雜度**：整合
- **寫入檔案**：`test/guest_mode_test.dart`（新檔）
- **相依**：T1、T3
- **內容**：測試 `SignInManager` 的旗標讀寫與清除。用 `SharedPreferences.setMockInitialValues({})` 提供假 prefs（無需新增依賴，`shared_preferences` 內建此測試支援）。因 `SignInManager` 是 singleton，每個測試需在 `setUp` 重置狀態。

測試案例（涵蓋 AC-8 三條）：

1. `markAsGuest` 後 `isGuest` 為 true，且 prefs 寫入 `Constants.prefKeyGuestMode`
2. `loadGuestFlag` 能從既有 prefs 值還原記憶體狀態（模擬 App 重啟）
3. `clearGuestFlag` 後 `isGuest` 為 false 且 prefs key 被移除
4. **互斥性（AC-2）**：`_isGuest` 為 true 但 `accountDto` 非 null 時，`isGuest` 必須回傳 false
5. **登入清除（AC-6）**：呼叫 `signOut()` 後旗標被清除（`signOut` 不需真實 Firebase，`accountDto` 為 null 時走 `default` 分支的 `_mailSignInUpManager.signOutWithMail()`；若該呼叫在測試環境拋錯，改為直接驗證 `clearGuestFlag()` 的行為並於註解說明）

- **測試資料**：依專案慣例（Style Guide §8.2）置於同檔案的 `_Data` 類別，例如 `_Data.guestPrefs` / `_Data.emptyPrefs`。
- **驗收**：`rtk flutter test test/guest_mode_test.dart` 全綠。
- **註**：`signIn()` 的清除路徑涉及 Google/Firebase SDK，不做整合測試；以案例 4、5 涵蓋旗標邏輯本身，登入串接由 §5 的手動驗證涵蓋。

---

## 4. 相依關係與並行策略

```
T1 (constants)  ──┐
                  ├──> T3 (sign_in_manager) ──┬──> T4 (main.dart) ──> T5 (splash)
T2 (l10n)  ───────┘                           ├──> T6 (sign_in_page)
                                              ├──> T7 (head_cell)
                                              ├──> T8 (settings_page)
                                              └──> T9 (test)
```

**並行波次**（寫入路徑不重疊，可安全平行）：

| 波次 | 任務 | 說明 |
|------|------|------|
| 波次 1 | **T1 ∥ T2** | 兩者無交集（`constants.dart` vs `l10n/*`），完全獨立 |
| 波次 2 | **T3** | 單獨執行。核心任務，且是後續所有任務的共同相依 |
| 波次 3 | **T4 ∥ T6 ∥ T7 ∥ T8 ∥ T9** | 五個任務各寫各的檔案，零重疊 |
| 波次 4 | **T5** | 需 T4 完成（旗標預載入必須先就位，否則 SplashPage 讀到的永遠是 false） |

**編譯完整性**：每個任務結束後專案皆可編譯。

- T1、T2 只新增未使用的常數/字串 → 編譯通過
- T3 只新增未被呼叫的方法 → 編譯通過
- T4~T8 各自只消費已存在的 API → 編譯通過
- 唯一的順序硬約束是 T4 → T5：若 T5 先做，功能雖可編譯但行為錯誤（旗標永遠 false）

**執行方式建議**：

- **subagent-driven（推薦）**：波次 1 派 2 個 subagent、波次 3 派 5 個 subagent，波次 2 與 4 主線序列執行。共 4 個同步點。
- **parallel session**：因 T3 是幾乎所有任務的相依瓶頸，多 session 的收益有限。若採用，建議 session A 做 T1→T3→T4→T5（主幹），session B 做 T2→T6→T8（UI），session C 做 T7→T9；B 與 C 需等待 A 的 T3 完成。
- **單線序列**：T1 → T2 → T3 → T4 → T5 → T6 → T7 → T8 → T9。任務總量不大，單線亦屬合理選擇。

---

## 5. 風險與驗證方式

### R-2（中）：`MainPage` 從未被當作啟動後的第一個畫面

**已完成的靜態查證**（不是推論，是逐行讀過的結果）：

| 檢查點 | 位置 | 結論 |
|--------|------|------|
| Bloc 注入 | `routes_table.dart:28` | `MainPage.routeName` 在 routes table 中已包 `BlocProvider<MainBloc>`，與從登入頁進入時是**同一個 builder**。訪客路徑不存在缺少 Bloc 的可能。 |
| `initState` 相依 | `main_page.dart:43-56` | 只派發 `NotificationSetup` 與 `FetchSearchInfo`，兩者皆不觸及 `SignInManager`。 |
| `MainBloc` 相依 | `main_bloc.dart` | 全類別無 `SignInManager` 引用；`FetchSearchInfo` 依賴 `Utils.getCurrentPosition()`（定位權限）與 Yelp API（`Constants.authToken` 硬編碼），皆與登入無關。 |
| 路由參數 | `main_page.dart:270` | `ModalRoute.of(context)?.settings.arguments as Tuple2<...>?` 是**可為 null 的轉型**，且第 274 行有 null 檢查。`pushReplacementNamed` 不帶 arguments 不會拋 `TypeError`。 |

**靜態查證顯示風險低，但仍必須實機驗證**（AC-3 明訂「不得出現只有訪客路徑才會崩潰」）。驗證步驟：

1. 全新安裝或清除 App 資料 → 啟動 → SplashPage → SignInPage（確認 baseline）
2. 點「訪客模式」→ 應進入 MainPage 並看到餐廳列表（首次會跳定位權限請求）
3. **殺掉 App（完全終止，非背景）→ 重新啟動** → 應由 SplashPage 直接進入 MainPage，**跳過 SignInPage**
4. 在此訪客啟動路徑下逐一操作：關鍵字搜尋、篩選、地圖/列表切換、開啟餐廳詳情、開啟設定頁、開啟口袋名單
5. 觀察 console 是否有 `LateInitializationError`、`Null check operator used on a null value` 或 `type 'Null' is not a subtype of` 等例外

若第 3 步崩潰，優先檢查 `MainPageState._summaryInfos`（`late` 欄位，於 `initState` 賦值）與 FCM 初始化時序。

### R-3（中）：訪客旗標與 `accountDto` 兩份狀態不同步

**緩解**：§1.1 的設計把兩者放進同一物件，並以 `isGuest` getter 內建互斥判斷（`accountDto == null && _isGuest`）。即使 `_isGuest` 因任何原因殘留 true，只要使用者已登入，`isGuest` 就一定回傳 false。由 T9 案例 4 覆蓋。

### R-4（低）：`SignInPage.initState` 的 `AutoSignInEvent`

訪客從設定頁進入登入頁時，`initState` 會派發 `AutoSignInEvent()`。若自動登入成功，會走 `SignInManager.signIn(AccountType.auto)` → 命中 T3 的清除點 → 旗標被清 → 直接跳 MainPage。**行為正確且已被 T3 涵蓋**，無需額外處理。

但注意：訪客通常沒有快取的 `prefKeyAccountInfo`，`AutoSignInManager` 會回傳 `Tuple2(null, '')`，`accountDto` 維持 null，`if (accountDto != null)` 守衛使旗標**不被誤清**。這正是 T3 中該守衛存在的理由。

### 新增風險 R-5（低）：`SettingsRepo.logout()` 的 `prefs.clear()`

`logout()` 呼叫 `prefs.clear()` 會清除**所有** prefs（含生物辨識設定），這是既有行為，本次不改。但它會順帶清掉磁碟上的訪客旗標，與 `signOut()` 清記憶體旗標形成雙保險。**不要**因為看到 `prefs.clear()` 就省略 `signOut()` 內的 `clearGuestFlag()`——記憶體快取不會被 `prefs.clear()` 影響。

### 端到端手動驗證清單（對應 AC）

| # | 情境 | 預期 | AC |
|---|------|------|-----|
| 1 | 登入頁是否有「訪客模式」按鈕（Android + iOS） | 皆顯示 | AC-1 |
| 2 | 點訪客模式 → 返回手勢 / 返回鍵 | 無法回到登入頁 | AC-1 |
| 3 | 訪客殺 App 重啟 | 直接進 MainPage | AC-2、AC-3 |
| 4 | 訪客在餐廳詳情點最愛 | 跳登入頁，圖示不變 | AC-4 |
| 5 | 訪客進設定頁 | 只有「登入 / 註冊」，無登出/刪除帳戶，版本資訊仍在 | AC-5 |
| 6 | 訪客 → 設定頁 → 登入 / 註冊 → 完成 Google 登入 → 再進設定頁 | 顯示登出 / 刪除帳戶 | AC-6 |
| 7 | 承上，殺 App 重啟 | 進 MainPage 且**以正式帳號身分**（最愛可正常收藏） | AC-6 |
| 8 | 正式使用者登出 → 殺 App 重啟 | 停留在登入頁，**未被誤判為訪客** | AC-7 |
| 9 | 已登入使用者的最愛按鈕與設定頁 | 與本次改動前完全相同 | AC-4、AC-5 |

### 全域驗證指令

```bash
rtk flutter analyze
rtk flutter test
```

---

## 6. 明確不做（範圍護欄）

- 不新增任何 pubspec 依賴
- 不新增 interface / abstract class / Repository / Bloc / Event / State
- 不修改 `FavorDataSource`、`MainBloc`、`MainRepo`
- 不修改 Firestore 安全規則
- 不做訪客最愛的本地儲存或資料遷移
- 不隱藏抽屜的「口袋名單」入口（規格 Q-1 暫定維持現狀）
- 不做「登入後返回原餐廳詳情頁」（規格 Q-2 暫定不做）
- 不做訪客功能限制的說明彈窗（規格 Q-3 暫定不做）
- 不改動登入頁既有的 Email / Google / Apple 流程與版面
