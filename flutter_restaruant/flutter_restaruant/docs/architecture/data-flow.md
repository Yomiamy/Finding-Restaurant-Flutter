# Finding Restaurant App - 數據流與功能流程 (Data Flow)

> 「好的程式碼沒有特殊情況。」 —— Linus Torvalds

本文件剖析 App 內核心功能的運作流程、狀態移轉與數據傳遞軌跡，涵蓋「App 啟動與依賴組裝」、「餐廳搜尋與最愛合併」、「最愛狀態雙向同步」、「登入流程分派」與「除錯工具接線」等主要路徑。

---

## 1. App 啟動與依賴組裝流程 (Bootstrap & Composition)

啟動順序是**有意義的依賴序**，不可任意調換：Flutter binding → DI 註冊 → 外部服務並行初始化 → 登入狀態載入 → `runApp`。

```text
  main()
    │
    ├─ 1. WidgetsFlutterBinding.ensureInitialized()
    │     （必須最先：後續 platform channel 呼叫的前提）
    │
    ├─ 2. setupInjection()
    │     GetIt 註冊「介面 → 實作」，全數 registerLazySingleton
    │     ┌──────────────────────────────────────────────┐
    │     │ DioClient / APIClz                           │
    │     │ SignInManager / FcmManager / AdCounterManager│
    │     │ FavorDataSource                              │
    │     │ MainRepository        → MainRepo             │
    │     │ RestaurantDetailRepository → RestaurantDetailRepo│
    │     │ FavorRepository       → FavorRepo            │
    │     │ SignInRepository      → SignInRepo           │
    │     │ SettingsRepository    → SettingsRepo         │
    │     └──────────────────────────────────────────────┘
    │     ※ 只註冊工廠函式，尚未建構任何實例（lazy）
    │
    ├─ 3. MobileAds.instance.initialize()（不 await）
    │     其 Future 直接包進 BannerADState 交由消費端等待
    │     getIt.registerSingleton<BannerADState>(...)
    │     ⚠️ 這是唯一的 eager singleton，且註冊點在 main.dart
    │        而非 injection.dart——讀 injection.dart 會誤以為那是全部
    │
    ├─ 4. Future.wait([...]) 併發四項初始化
    │     ├─ Constants.init()          （PackageInfo）
    │     ├─ Firebase.initializeApp(...)
    │     ├─ S.load(系統語系)
    │     └─ SignInManager().loadPrefs()
    │           （於 runApp 前載入，使 isGuest 可被 UI 同步查詢，
    │             SplashPage 才不需要 await 就能決定導向哪一頁）
    │
    └─ 5. .then((_) { FcmManager().init(); runApp(...); })
              │
              ▼
       ┌────────────────────────────────────────────────┐
       │  PlatformApp                                   │
       │   ├─ navigatorKey ─────► 全域 NavigatorState    │
       │   ├─ navigatorObservers ► [debug] inspector     │
       │   ├─ routes: routesTable                       │
       │   ├─ material: → MaterialAppData               │
       │   ├─ cupertino: → CupertinoAppData             │
       │   └─ builder: ─┬─ Theme(AppThemeData)          │
       │                └─ [debug] MagicalTap (5 連點)   │
       └────────────────────────────────────────────────┘
```

### 🔴 關鍵風險：`Future.wait` 無錯誤處理，任一項失敗即白屏

`Future.wait` 的語意是**任一 Future reject，整體即 reject**。目前 `.then()` 之後沒有 `.catchError`，也沒有 `try/catch`：

```dart
Future.wait([
  Constants.init(),                      // PackageInfo.fromPlatform()
  Firebase.initializeApp(...),
  S.load(...),
  SignInManager().loadPrefs(),           // ← 只有這個自己包了 try/catch
]).then((_) {
  FcmManager().init();
  runApp(const FindingRestaruantApp());  // ← reject 時永不執行
});
```

`Firebase.initializeApp()` 或 `Constants.init()` 若拋例外，`runApp()` **永遠不會被呼叫**——App 停在原生啟動畫面，使用者看到永久白屏，且沒有任何錯誤訊息可循。

四項之中只有 `SignInManager.loadPrefs()` 自行包了 `try/catch`（`sign_in_manager.dart:49-55`，註解明確寫著「避免整個 Future reject」）——**這證明開發者已意識到此風險，但只修了一處**。

> 🐧 **附帶品味問題**：本專案 style guide 明令「禁止 `.then()`」（§7.5），而 `main()` 宣告為 `async` 卻全程不用 `await`，第 38 行還掛了 `// ignore: unawaited_futures` 壓警告。改成 `await Future.wait([...])` 後接兩行即等價，且能自然套用 `try/catch`——一次修掉風險與規範違反。

### 關鍵細節：為什麼登入狀態要在 `runApp` 之前載入

`SplashPage` 的導向判斷是 `SignInManager().isGuest ? MainPage : SignInPage`——這是一次**同步**讀取。若登入狀態改為在 UI 中非同步載入，`SplashPage` 就得先渲染一個不確定狀態、再等結果跳轉，使用者會看到閃爍。**把非同步收斂在 `runApp` 之前，UI 層就只剩同步查詢，特殊情況直接消失。**

### 關鍵細節：`builder:` 為何必須包一層 `Theme`

`PlatformApp` 在 iOS 走 `CupertinoApp` 分支時，`material:` 提供的 `MaterialAppData` **根本不會被呼叫**，Material widget 會退回 Flutter 預設色票（藍色）。因此 `builder:` 額外包一層 `Theme(data: AppThemeData.materialLight)`：

- **iOS**：沒有 `MaterialApp` 可繼承，這層是唯一的 Material 主題來源。
- **Android**：與 `MaterialAppData` 的設定重疊，但值相同故無害。

一個 `builder:` 同時解決兩個平台，不需要 `if (Platform.isIOS)` 分支。

---

## 2. 餐廳搜尋流程：兩個資料源的合併 (Search & Favor Merge)

這是 App 最核心的資料流，也是**唯一需要合併兩個獨立資料源**的路徑：Yelp API 提供餐廳資料，Firestore 提供該使用者的最愛狀態。

```text
  MainPage (UI)          MainBloc              MainRepo           Yelp API / Firestore
      │                     │                      │                       │
      │─ 1. add(FetchSearchInfo) ─►                │                       │
      │                     │                      │                       │
      │                     ├─ 2. 取得目前 GPS 座標  │                       │
      │                     │   Utils.getCurrentPosition()                 │
      │                     │                      │                       │
      │                     ├─ 3. 判斷是否為載入更多 │                       │
      │                     │   isLoadMore = summaryInfoSet.isNotEmpty     │
      │                     │                      │                       │
      │                     ├─ 4. [僅首次] emit(InProgress())              │
      │◄── 顯示 Loading ────┤   （載入更多時不 emit，避免整頁閃爍）          │
      │                     │                      │                       │
      │                     │─ 5. fetchYelpSearchInfo(lat,lng,...) ─►      │
      │                     │                      │                       │
      │                     │                      ├─ 6. 重入守衛           │
      │                     │                      │   if (_isLoading)     │
      │                     │                      │     → 改走本地過濾     │
      │                     │                      │                       │
      │                     │                      │─ 7. businessesSearch ─►│ Yelp
      │                     │                      │◄── YelpSearchDto ─────│
      │                     │                      │                       │
      │                     │                      │─ 8. fetchFavorsMap() ─►│ Firestore
      │                     │                      │◄── Map<id, bool> ─────│
      │                     │                      │                       │
      │                     │                      ├─ 9. 合併兩源           │
      │                     │                      │   dto → Entity.fromDto│
      │                     │                      │       .copyWith(favor)│
      │                     │                      │                       │
      │                     │                      ├─ 10. 累積至 summaryInfoSet
      │                     │                      │    _offset += limit    │
      │                     │◄── List<RestaurantEntity> ──                 │
      │                     │                      │                       │
      │                     ├─ 11. emit(Success | LoadMoreSuccess)         │
      │◄── BlocBuilder 重建 ─┤                      │                       │
```

### 關鍵細節：Dto → Entity 的轉換點

轉換一律發生在 **data layer 內部**（`main_repo.dart:63`）：

```dart
List<RestaurantEntity> fetchedEntities = (searchDto.businesses ?? []).map((dto) {
  bool isFavor = favorsMap.containsKey(dto.id);
  return RestaurantEntity.fromDto(dto).copyWith(favor: isFavor);
}).toList();
```

- **`YelpRestaurantSummaryDto` 在執行期永不越過 Repository 邊界**——Bloc 與 UI 拿到的一律是 `RestaurantEntity`。這讓 Yelp 改欄位名時，衝擊被限制在 Dto 與 `fromDto` 兩處。
- **`copyWith(favor:)` 是合併點**：Yelp 不知道使用者收藏了什麼，最愛狀態只能在此疊加。

> 🔴 **但 import 層級並未隔離**：`fromDto` / `toDto` 是寫在 **Entity 自己身上**的成員（11 個 entity 皆然），因此 `domain/entities/` 反向 import 了 `data_layer/dto/`。執行期的資料不會外洩，編譯期的依賴卻已經反向。詳見 [`overview.md` 的架構缺陷章節](./overview.md#-已知架構缺陷entity-反向依賴-dto)。

### 關鍵細節：`_isLoading` 重入守衛

```dart
if (_isLoading) {
  return await filterByKeyword(_keyword, sortByStr);  // 改走本地資料
}
```

使用者快速滑動觸發連續 `FetchSearchInfo` 時，若不擋下，`_offset` 會被重複遞增造成**分頁跳號**（漏掉整頁資料）。守衛的做法不是丟棄請求，而是**降級為本地過濾**——使用者仍會看到列表更新，不會覺得 App 沒反應。`_isLoading` 在 `finally` 中還原，確保例外路徑不會永久卡死。

### 關鍵細節：載入更多為何不 emit `InProgress`

```dart
if (!isLoadMore) {
  emit(const InProgress());
}
```

`InProgress` 會讓 UI 顯示整頁 Loading。載入更多時列表已有內容，整頁 Loading 會使已渲染的項目消失再出現——**視覺上像是資料被清空**。因此只有首次載入才進入 `InProgress`，載入更多直接 emit `LoadMoreSuccess`，列表無縫延長。

---

## 3. BLoC 狀態機與 UI 重建 (State Machine)

State 以**互斥的具名子類別**表達，而非單一 class 內的布林旗標組合。

```text
                    ┌──────────────┐
                    │ MainInitial  │  ← super(const MainInitial())
                    └──────┬───────┘
                           │ FetchSearchInfo（首次）
                           ▼
                    ┌──────────────┐
                    │  InProgress  │
                    └──────┬───────┘
                  ┌────────┴────────┐
            成功  │                 │  拋出 Exception
                  ▼                 ▼
          ┌──────────────┐   ┌──────────────┐
          │   Success    │   │   Failure    │
          │ summaryInfos │   └──────────────┘
          └──────┬───────┘
                 │
     ┌───────────┼───────────┬──────────────┐
     │           │           │              │
 FetchSearchInfo │      ToggleFavor       Reset
 （已有資料）     │           │              │
     ▼           │           ▼              ▼
┌──────────────┐ │  ┌──────────────────┐ ┌──────────────┐
│LoadMoreSuccess│ │  │ToggleFavorSuccess│ │ ResetSuccess │
└──────────────┘ │  └──────────────────┘ └──────────────┘
                 │
        FilterListByKeyword
                 ▼
          ┌──────────────┐
          │   Success    │（過濾後的子集，空結果也是 Success）
          └──────────────┘
```

### 關鍵細節：為什麼「查無結果」是 `Success` 而非 `Failure`

```dart
if (filterInfos.isNotEmpty) {
  emit(Success(summaryInfos: filterInfos));
} else {
  emit(const Success(summaryInfos: []));
}
```

兩個分支都 emit `Success`。**「查無結果」是成功執行的正常結果，不是錯誤**——`Failure` 保留給真正的例外（網路中斷、API 錯誤）。UI 據此區分「顯示空狀態 `EmptyDataWidget`」與「顯示錯誤重試」兩種截然不同的畫面。

> 🐧 **品味評註**：這兩個分支其實可以直接寫成 `emit(Success(summaryInfos: filterInfos))`——`filterInfos` 為空時結果完全相同。目前的 if/else 是可消除的特殊情況。

### 關鍵細節：`Equatable` 與重複狀態抑制

所有 State 繼承 `Equatable` 並覆寫 `props`：

```dart
class Success extends MainState {
  @override
  List<Object> get props => summaryInfos;
}
```

flutter_bloc 在 `emit` 時會比對新舊 state，**相等則不觸發重建**。`props` 若漏填欄位，內容變了卻被判定相等，UI 就不會更新；填對了則免費獲得重複狀態抑制。

---

## 4. 路由與 Bloc 生命週期 (Routing & Bloc Scoping)

`routesTable` 是全 App 唯一的 Composition Root——路由、Bloc、Repository 三者在此接合。

```text
  Navigator.pushNamed(context, MainPage.routeName)
                    │
                    ▼
     routesTable[MainPage.routeName] 被呼叫
                    │
                    ▼
  ┌────────────────────────────────────────────────┐
  │ BlocProvider<MainBloc>(                        │
  │   create: (_) => MainBloc(                     │
  │     repository: GetIt.I<MainRepository>()),    │──► GetIt 取出
  │   child: const MainPage())                     │    MainRepo 實例
  └────────────────┬───────────────────────────────┘   （lazy singleton）
                   │
                   ▼
         MainPage 於 widget tree 中
         以 context.read<MainBloc>() 取用
                   │
                   │ 使用者返回上一頁
                   ▼
         route 被 pop → BlocProvider dispose
                     → MainBloc.close() 自動呼叫
```

### 關鍵細節：Bloc 生命週期綁定路由，Repository 生命週期綁定 App

| 物件 | 生命週期 | 由誰管理 |
| :--- | :--- | :--- |
| `MainBloc` | 與路由同生共死，pop 即 dispose | `BlocProvider`（自動） |
| `MainRepo` | 整個 App 存活期間單一實例 | GetIt `registerLazySingleton` |

這個分工讓 **Repository 的快取（`summaryInfoSet`、`_offset`）跨頁面保留**——使用者進詳情頁再返回，列表不需重新請求。若 Repository 也綁定路由，每次返回都會觸發完整重新載入。

> ⚠️ **代價**：`MainRepo` 持有可變狀態且為 singleton，因此 `reset()` 必須在適當時機（切換篩選條件、登出）明確呼叫，否則會看到上一次查詢的殘留資料。這是「快取跨頁保留」換來的必然責任。

### 關鍵細節：Page 為何可以是 `const`

`BlocProvider` 建在 route builder 內、Page 之外，Page 本身不接收 Bloc 作為建構參數，因此可宣告 `const MainPage()`。Flutter 對 `const` widget 會短路重建，減少不必要的 rebuild。

---

## 5. 最愛狀態的雙向同步 (Favor Sync)

最愛是唯一「使用者可寫入」的資料，因此需要處理**本地狀態與遠端的一致性**。

```text
  使用者點擊愛心
        │
        ▼
  add(ToggleFavor(entity))
        │
        ▼
  MainBloc: emit(InProgress())
        │
        ▼
  MainRepo.toggleFavor(entity)
        │
        ▼
  FavorDataSource.toggleFavor(entity)
        │
        ├─ 1. 取得 uid（空字串 guard）
        │     ⚠️ 少了這道 guard，Firestore 會因空字串
        │        doc id 拋出 ArgumentError
        │
        ├─ 2. 寫入 Firestore
        │     collection(favor).doc(uid)
        │
        └─ 3. 回傳「已持久化的 Entity」
              （而非讓呼叫端自行推導新狀態）
        │
        ▼
  emit(ToggleFavorSuccess())
        │
        ▼
  UI 依新的 entity.favor 重繪愛心
```

### 關鍵細節：回傳 Entity 而非 `void`

`MainRepository.toggleFavor` 的契約註解寫得很明確：

> Returns the persisted entity so callers adopt the new favor value instead of deriving it a second time.

若回傳 `void`，呼叫端就得自己算 `!entity.favor`——**同一個「翻轉」邏輯會存在於兩個地方**，一旦 Firestore 寫入失敗或伺服器端有額外規則，本地推導值就與真實狀態不符。回傳持久化後的 Entity 讓真實來源只有一個。

---

## 6. 登入流程分派 (Sign-In Dispatch)

App 支援 5 種登入方式，每種各有一個 Manager 封裝其 SDK 差異。

```text
              SignInPage（使用者選擇登入方式）
                          │
                          ▼
                 add(對應的 SignInEvent)
                          │
                          ▼
                     SignInBloc
                          │
                          ▼
                     SignInRepo
                          │
        ┌────────┬────────┼────────┬─────────────┐
        ▼        ▼        ▼        ▼             ▼
    Google    Apple   Facebook   Mail      Biometric
    SignIn    SignIn   SignIn   SignInUp    SignIn
    Manager   Manager  Manager   Manager     Manager
        │        │        │        │             │
        └────────┴────────┼────────┴─────────────┘
                          │ 統一產出
                          ▼
                    AccountDto
                          │
                          ▼
                UserEntity.fromDto(accountDto)
                          │
                          ▼
              SignInManager 更新登入狀態
              （後續 isGuest 等查詢的單一真實來源）
```

### 關鍵細節：Manager 的統一 Singleton 模式

9 個 Manager 全數採同一模式：

```dart
class SignInManager {
  static final SignInManager _singleton = SignInManager._internal();
  SignInManager._internal();
  factory SignInManager() => _singleton;
}
```

呼叫端寫 `SignInManager()` 看起來像在建構新物件，實際拿到同一實例。**好處**是呼叫端不需要知道它是 singleton；**代價**是無法在測試中替換實作（不像 Repository 走 GetIt 可注入 fake）。

> 🐧 **品味評註**：登入狀態既然是全 App 共享的可變狀態，走 GetIt 註冊會比自建 singleton 更一致——目前專案同時存在兩套單例機制（GetIt 與 `_singleton` factory）。這是既有設計，改動會波及 9 個檔案與大量呼叫點，屬「可改善但非急迫」。

---

## 7. 除錯工具接線 (Debug Inspector Wiring)

Inspector 有 **5 個接線點分散在 4 個檔案**，全數以 `kDebugMode` 或 `?.` 保護，release build 中整條路徑被 tree-shaking 移除。

```text
  lib/di/inspector.dart
    final FlutterInspector? inspector = kDebugMode ? FlutterInspector(...) : null;
                    │
                    │ release build：恆為 null，以下引用全成 dead code
                    │
    ┌───────────────┼───────────────┬──────────────┬────────────────┐
    ▼               ▼               ▼              ▼                ▼
 ① api_clz     ② main.dart      ③ main.dart   ④ main.dart    ⑤ splash_page
   攔截器        navigatorObservers  MagicalTap    （builder 層）    attach() FAB
    │               │               │                               │
    │               │               │                               │
  排在 auth      記錄路由變化      5 連點喚起                    常駐 FAB
  攔截器之後                       dashboard                     入口
```

### 關鍵細節：攔截器順序決定看到的是不是真實請求

最終攔截器鏈共三層，request 依序正向執行、response 反向執行：

```text
  request  ──►  [0] LogInterceptor  ──►  [1] auth 注入  ──►  [2] Inspector  ──► 送出
                （dio_client.dart:24）  （Authorization）    （記錄快照）

  response ◄──  [0] LogInterceptor  ◄──  [1] auth（未覆寫） ◄── [2] Inspector ◄── 回應
                                                                 （最先拿到，
                                                                   原地替換 pending entry）
```

**Inspector 排在 auth 之後**才看得到 `Authorization`——它的 `onRequest` 是取 `options.headers` 的當下快照。順序反過來，面板會顯示一個沒有 `Authorization` 的請求，而那正是排查 401 時最會誤導人的畫面。

Inspector 的 pending→complete 機制靠 `options.extra` 傳遞：`onRequest` 寫入 `_inspector_start_time` 與 `_inspector_pending_entry`，`onResponse`/`onError` 取出後以 `replaces:` 原地替換，因此同一筆請求在面板上只佔一列，不會出現重複。

> 🔴 **`LogInterceptor` 在 release build 仍會印出完整 body**：`isLogEnabled` 預設 `true` 且無 `kDebugMode` 圍堵（`dio_client.dart:23`）。且它位於 index 0、早於 auth 注入，印出的 header 不含 `Authorization`——與 Inspector 看到的是兩份不同快照。詳見 [`overview.md`](./overview.md)。

### 關鍵細節：兩個進入點需要兩種不同的 context

| 進入點 | 位置 | context 來源 | 原因 |
| :--- | :--- | :--- | :--- |
| 5 連點喚起 | `main.dart` `builder:` | `navigatorKey.currentContext` | `builder` 的 context **位於 Navigator 之上**，`showGeneralDialog` 從中解析不到 `NavigatorState` |
| 常駐 FAB | `splash_page.dart` | `SplashPage` 自身的 `context` | 路由 widget 的 context **已在 Overlay 之下**，`attach()` 才找得到 `Overlay` |

這是 Flutter widget tree 位置決定 API 可用性的典型案例：**同一個 `inspector` 物件，兩個進入點卻不能共用同一個 context**。

### 關鍵細節：`captureUncaughtErrors` 對測試的副作用

`FlutterInspector` 建構式內會立即改寫三個全域 error hook（`FlutterError.onError`、`PlatformDispatcher.instance.onError`、`ErrorWidget.builder`）。由於 `inspector` 是**頂層 lazy final**，首次求值發生在第一次被讀取時——全專案只有 `test/app_theme_platform_test.dart` 會 mount 真實的 `FindingRestaruantApp`，因此該測試必須在 `try/finally` 中自行還原這三個 hook。

> ⚠️ `tearDown()` 來不及救：`flutter_test` 對 `ErrorWidget.builder` 的前後比對發生在測試主體結束時、`tearDown` 執行**之前**。日後若有新測試 mount 真實 App，同樣需要處理。
