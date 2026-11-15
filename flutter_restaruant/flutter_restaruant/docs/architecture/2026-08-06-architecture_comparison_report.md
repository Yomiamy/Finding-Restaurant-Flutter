# Finding Restaurant App 架構與代碼風格審查報告 (更新於 2026-08-06)

本報告以 **`flutter_inspector_kit`（下稱對照組套件）** 的工程準則作為對照，審查本專案（下稱**當前專案**）`lib/` 目錄的代碼品味、職責拆分與命名慣例，並記錄已落地的架構決策與**尚未解決的缺陷**。

> **證據基準**：所有結論皆來自 `main` 分支 `d0e88d4` 當下的實際檔案內容，並經獨立複查。`flutter analyze` 目前為 **`No issues found!`**。
>
> ⚠️ **關於本報告的驗證強度**：本次調查由 4 個平行 agent 讀取 155 個檔案產出，原訂的對抗式複查階段因額度用盡未能執行。報告中**每一項指名的缺陷都已由我逐一開檔複查**（附行號），但「未被發現的問題」不在此保證範圍內。

---

## 🐧 核心審查與品味評級 (Linus' Taste Rating)

### 🟢 好的部分 (Good Taste)

* **狀態以型別表達，而非布林旗標組合**：`MainState` 用 7 個互斥的具名子類別（`MainInitial` / `InProgress` / `Success` / `Failure` / `LoadMoreSuccess` / `ResetSuccess` / `ToggleFavorSuccess`）表達狀態機，而非單一 class 塞 `isLoading` / `hasError`。不可能出現「同時 loading 又 error」這種靠約定才不發生的非法狀態。

* ~~**平台分歧在編譯期強制處理**：`PlatformWidget<I extends Widget, A extends Widget>` 以兩個 `required` 抽象方法約束，繼承者漏寫任一平台則編譯失敗。這比在 `build` 內散落 `if (Platform.isIOS)` 更能消滅「某平台忘了處理」的特殊情況。~~
  > **2026-09-26 實查更新 (UI-8.2 / PR #129)**：經查全專案 0 處繼承或呼叫 `lib/component/platform_widget.dart`（專案實際跨平台 UI 一律採用 `flutter_platform_widgets` 套件），該檔已作為零引用死碼移除。

* **回傳持久化結果而非 `void`**：`MainRepository.toggleFavor` 回傳寫入後的 Entity，介面註解寫明理由——「so callers adopt the new favor value instead of deriving it a second time」。避免了「翻轉邏輯存在於兩處」的經典錯誤。

* **`PlatformApp` 的 Cupertino 分支陷阱被識別並註解**：`main.dart` 的 `builder:` 額外包一層 `Theme`，註解說明 iOS 走 `CupertinoApp` 時 `material:` 不生效。這是真正理解框架行為後的修法，不是試錯湊出來的 workaround。

* **Navigator context 的層級問題被根因解決**：5 連點喚起 dashboard 時不用 `builder` 的 `context`（位於 Navigator 之上），改用 `navigatorKey.currentContext`，且註解完整說明原因。

* **啟動鏈上的 `loadPrefs` 有防護且註解到位**：`sign_in_manager.dart:45-56` 明確寫著「這個呼叫位於 `main()` 的 `Future.wait` 啟動鏈上，因此**不可對外拋錯**」。作者理解 `Future.wait` 的 fail-fast 語意。

* **色票只做 `ColorScheme.fromSeed`、零 `copyWith` 覆寫**：種子色決定整組色階，不手動微調個別顏色，避免色票互相矛盾。

### 🔴 尚未解決的壞品味 (Unresolved Bad Taste)

以下每一項都經逐檔複查確認，附精確行號。

#### ~~1. Domain 層反向依賴 Data 層（架構規則實質失效）~~ ❌ 已裁決不調整（As-Designed 資料驅動分層架構；循環依賴已於 PR #112 解除）

**11 個 entity 檔案全數 `import '../../data_layer/dto/dto_barrel.dart'`**，根因是 `fromDto` / `toDto` 這對轉換方法被放在 Entity 自己身上。原先 `AccountDto` ⇄ `UserEntity` 構成**真實的循環 import**（`account_dto.dart:2` ⇄ `user_entity.dart:2`）；此問題已於 2026-09-07（PR #112）透過在 Data 層定義 `AccountType`、Domain 層定義 `AccountTypeModel` 解耦消除，`AccountDto` 不再反向依賴 Domain。

Dart 允許循環 import 故編譯不會失敗，但這代表 **domain 層物理上無法獨立於 data_layer 抽出來編譯或測試**——Clean Architecture 最主要的收益就此蒸發。

> 「依賴方向」不是靠目錄名字決定的，是靠 import 決定的。目前 `domain/` 這個目錄名字說它是內層，import 說它不是。

**原修法提案**：把 `fromDto`/`toDto` 移到 data_layer 的 mapper，Entity 就不再需要認識 DTO，循環自然消失。

附帶兩處橫向洩漏：`sign_in_repository.dart:2` 與 `restaurant_business_time_entity.dart:2` import `features/utils/utils_barrel.dart`，而該 barrel 間接拉進 `geolocator` 與 `url_launcher`——一個 domain entity 只為判斷語系，就把定位與瀏覽器套件掛上了。

> **2026-11-15 實查更新**：
> 1. **循環依賴與橫向洩漏已解**：`AccountDto ⇄ UserEntity` 直接循環 import 已於 PR #112（2026-09-07）解除；`restaurant_business_time_entity.dart` 對 `features/utils/utils_barrel.dart` 的 import 亦已隨 A-9.1（刪除 `Utils.isLocaleZh()`）移除。
> 2. **架構定案（`[A-8.2]` / `docs/architecture/overview.md` §1）**：正式裁決為 **❌ 不需要調整（As-Designed 資料驅動分層架構）**。本專案採 `Infra (DTO, API, DB) ← Domain (Entity) ← Data Layer (Repository) ← BLoC ← Presentation` 拓撲，由 `Entity.fromDto` 自行封裝轉換並確保 DTO 永不外洩至 Presentation 層，拒絕引入純單行轉發的形式主義 Mapper。

#### 2. `LogInterceptor` 預設值與攔截器順序（🟡 部分修復：呼叫端已加 `kDebugMode`，release 外洩風險已解除）

`dio_client.dart:23-26` 的 `isLogEnabled` 預設 `true`，呼叫端（`api_clz.dart:53`）未覆寫，且**沒有 `kDebugMode` 圍堵**：

```dart
if (isLogEnabled) {
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
}
```

release 版仍會把完整 request/response body 寫進 stdout。這與 Inspector 嚴謹的 `kDebugMode` + `null` 雙重防護形成刺眼的落差——**同一個專案裡，一邊嚴防除錯資訊外洩，另一邊預設全開**。

附帶一致性問題：`LogInterceptor` 位於 index 0、早於 auth 注入，因此它印的 header 不含 `Authorization`，與 Inspector 看到的是兩份不同快照。

**修法**：`isLogEnabled` 預設改為 `kDebugMode`，並將註冊順序移到 auth 之後。

> **2026-11-15 實查更新**：呼叫端 `lib/api/api_clz.dart:164` **已明確傳入 `isLogEnabled: kDebugMode`**（附註解「release 不記錄請求 URI 與回應內容」），release build 印出完整請求與回應的外洩風險已解除。目前僅剩 `lib/api/dio/dio_client.dart:10` 建構子預設值仍為 `bool isLogEnabled = true`，以及 `:24-32` 中 `LogInterceptor` 註冊順序仍早於 `interceptWraps`（Auth header 注入）待收尾。

#### ~~3. `main()` 的 `Future.wait` 無錯誤處理 → 啟動失敗即永久白屏~~ ✅ 已修復

`main.dart:31-43` 沒有 `catchError` 也沒有 `try/catch`。`Firebase.initializeApp()` 或 `Constants.init()` 一旦拋例外，`.then()` 不執行，**`runApp()` 永遠不會被呼叫**，使用者看到永久白屏且無任何錯誤提示。

四項之中只有 `SignInManager.loadPrefs()` 自行包了 `try/catch`——**作者已意識到此風險，但只修了一處**。

同時，`main()` 宣告為 `async` 卻全程不用 `await`，靠 `.then()` 串接，第 38 行掛 `// ignore: unawaited_futures` 壓警告。這違反專案 style guide §7.5「禁止 `.then()`」。改成 `await Future.wait([...])` 後接兩行即等價，且能自然套用 `try/catch`——**一次修掉風險與規範違反**。

> **2026-08-21 實查更新**：此缺陷已修復。`lib/main.dart` 的啟動鏈（第 33-40 行區塊）已改用 `await Future.wait([...])` 並被 `try/catch (e, st)` 完整包覆，解決了永久白屏風險與 `.then()` 規範違反。

#### 4. 硬編碼的 Yelp Bearer Token（🟡 部分修復：明文已遷至 Remote Config，`fetchToken` 死碼已刪除）

`constants.dart:40` 的 `Constants.authToken` 是明文靜態 token，會被打包進 release binary。`APIClz.fetchToken`（`api_clz.dart:18-24`）雖然存在，但**全 codebase 無任何呼叫點**——取得 token 的正規管道寫好了卻沒接上。

附帶 bug：auth interceptor 用 `addAll` 而非 `putIfAbsent`，會**覆寫** Retrofit 已組好的 header。`fetchToken` 標註 `@FormUrlEncoded()`，生成碼設 `application/x-www-form-urlencoded`，會被此 interceptor 蓋成 `application/json`。因無呼叫點所以尚未爆發。

> **2026-10-27 實查更新 (PR #135 / PR #162)**：
> 1. `constants.dart` 內的明文 `Constants.authToken` 與 `staticMapApiKey` 已於 **A-8.5（Issue #134 / PR #135，2026-09-28）** 移除，改由 Firebase Remote Config（`AiModelConfig().yelpAuthToken`／`staticMapApiKey`）動態下發。惟 Remote Config 值仍會下發至客戶端記憶體，長期根治仍待建立 Server-side Broker 並輪替歷史金鑰。
> 2. 零呼叫的死碼 `APIClz.fetchToken` 已於 **A-8.8（Issue #161 / PR #162，2026-10-27）** 正式刪除。

#### 5. 三層單例疊床架屋，且兩條取用路徑並存

`SignInManager` / `FcmManager` / `AdCounterManager` 本身已是經典 Dart singleton（`static final _singleton` + `factory`），卻又被註冊進 GetIt 成 `registerLazySingleton`——**第二層單例包第一層單例**。

而實際呼叫端根本繞過 GetIt：`main.dart:37,40` 與 `splash_page.dart:28` 都直接用 `SignInManager()` 建構式取用。也就是說這三個 manager 的 GetIt 註冊**在主要呼叫路徑上從未被使用**。一個東西兩條取得路徑，是典型可消滅的複雜度。

#### 6. DI 註冊點分散在兩個檔案

`main.dart:29` 的 `getIt.registerSingleton<BannerADState>(...)` 是唯一的 **eager** singleton，且**不在** `injection.dart` 內（因為它需要注入 `MobileAds.initialize()` 的 Future）。讀 `injection.dart` 會誤以為那就是全部的註冊。

#### ~~7. `locale` 被決定了兩次，其中一次是多餘的~~ ✅ 已修復

`main.dart:35` 用**系統語系**載入翻譯 `S.load(ui.PlatformDispatcher.instance.locale)`，但 `main.dart:56` 把 `PlatformApp.locale` **硬鎖為 `zh_TW`**。`locale` 一旦指定，`S.delegate` 會以 `zh_TW` 重新載入並覆蓋前者。第 35 行實質上只影響 `runApp` 之前那個沒有 UI 的極短窗口——**是可直接刪除的複雜度**。

> **2026-11-15 實查更新**：此缺陷已修復。`lib/main.dart:97-129` 的 `PlatformApp` 已移除硬鎖的 `locale:` 參數，全 App 統一由 `lib/main.dart:46` 的 `S.load(ui.PlatformDispatcher.instance.locale)` 與 `supportedLocales: S.delegate.supportedLocales` 決定語系。

#### 8. `MainRepository` 介面洩漏可變內部狀態

`main_repository.dart:4` 把 `Set<RestaurantEntity> summaryInfoSet` 曝露在介面上，`MainRepo:17` 以公開欄位滿足它，因此呼叫端拿到的是**可寫的同一個 Set**。`MainBloc:26` 也確實在用（`_mainRepository.summaryInfoSet.isNotEmpty`）。介面應該描述行為，不該把實作的快取容器攤開。

#### 9. `toggleFavor` 在三個介面各寫一次，三份實作行為不同

`FavorRepository:8`、`MainRepository:23`、`RestaurantDetailRepository:10` 的簽章與註解字面完全相同，但三份實作各自做不同的 cache 同步（`RestaurantDetailRepo:33` 純轉發、`FavorRepo:29-37` 重建 `_favorInfos`、`MainRepo:129-137` 增刪 `summaryInfoSet`）。**同名同簽章卻語意不同**，是最容易讓後人踩到的一類設計。

---

## 🔍 架構與職責對比分析

### 1. 專案結構 (Structure)

| 維度 | 對照組套件 (`flutter_inspector_kit`) | 當前專案 (`flutter_restaruant`) |
| :--- | :--- | :--- |
| **架構模式** | **扁平技術分包**（`core` / `models` / `ui` / `utils`） | **Clean Architecture + Feature-First**（`domain` / `data_layer` / `flow`） |
| **層級隔離** | 無嚴格層級，靠 `FlutterInspector` Facade 收斂 | 採 `Infra ← Domain ← Data Layer ← Presentation` 資料驅動分層，`Entity.fromDto` 封裝轉換、DTO 永不外洩至 UI（見缺陷 1 更新與 `overview.md`） |
| **業務邏輯位置** | UI `StatefulWidget` 內或純函數 | `Bloc` 的事件處理器 + Repository |
| **實體隔離** | 統一 `Entry`，實作 `TimestampedEntry` 契約 | 區分 `Entity`（業務）／`Dto`（線上格式）／`Model`（UI） |
| **規模** | ~60 檔，單一 package | **174 檔**，8 個 feature 垂直切片 |

> **實用主義評註**：兩者的選擇都對——**架構應該匹配問題規模**。對照組是輕量 debug 工具，引入 UseCase 或 Repository 層純屬自我折磨；當前專案有 8 個 feature、兩個外部資料源、5 種登入方式，分層帶來的隔離是划算的。`Entity.fromDto` 亦經 `[A-8.2]` 確認為資料驅動分層架構的既定設計，不額外引入單行轉發的 Mapper。

### 2. 狀態管理與職責

* **對照組套件**：不引入任何狀態管理，`StatefulWidget` 直接在 `build` 內同步過濾 `RingBuffer`（≤500 筆，微秒級）。刻意不加 Controller 層。
* **當前專案**：`flutter_bloc ^9.1.1`，嚴格單向資料流。UI 只發 Event、只監聽 State。
* **權衡與決策**：
  * Bloc 生命週期綁定路由（`BlocProvider` 建在 route builder 內，pop 即 dispose）；Repository 生命週期綁定 App（GetIt lazy singleton）。
  * 這個分工讓 **Repository 快取跨頁面保留**——進詳情頁再返回，列表不需重新請求。
  * **代價**：`MainRepo` 是持有可變狀態的 singleton，`reset()` 必須在切換篩選、登出時明確呼叫，否則看到殘留資料。這是「快取跨頁保留」換來的必然責任，非設計失誤。

### 3. 命名慣例 (Naming)

| 類型 | 當前專案慣例 | 範例 |
| :--- | :--- | :--- |
| Repository 介面 | `[Feature]Repository` | `MainRepository` |
| Repository 實作 | `[Feature]Repo` | `MainRepo` |
| 業務實體 | `[Feature]Entity` | `RestaurantEntity` |
| 傳輸物件 | `[Source][Feature]Dto` | `YelpRestaurantSummaryDto` |
| UI 模型 | `[Feature]Configs` / `[Feature]Vo` | `FilterConfigs`、`ResultVo` |
| 狀態管理 | `[Feature]Bloc` / `Event` / `State` | `MainBloc` |
| 第三方封裝 | `[Service]Manager` | `FcmManager` |

命名一致性良好，`Repository`（介面）與 `Repo`（實作）的區分尤其清楚——看名字就知道該注入哪一個。

---

## 📌 建議處理順序

依「風險 × 修復成本」排序，非依發現順序：

| 優先 | 項目 | 理由 | 預估成本 |
| :---: | :--- | :--- | :---: |
| 🟡 **部分修復** | 缺陷 2：`LogInterceptor` 預設值與順序 | 呼叫端 `api_clz.dart:164` 已傳 `isLogEnabled: kDebugMode`（release 外洩已解）；剩 `dio_client.dart` 建構子預設值與註冊順序移至 auth 之後 | 極低 |
| ✅ **已修復** | ~~缺陷 3：`Future.wait` 無錯誤處理~~ | 已於 `lib/main.dart` 加入 `try/catch` 完整包覆 | 低 |
| 🟡 **部分修復** | 缺陷 4：硬編碼 Token | 明文已遷至 Remote Config（PR #135）、`fetchToken` 已刪（PR #162）；剩餘 Server-side Broker 與金鑰輪替 | 高 |
| ❌ **不調整 (As-Designed)** | ~~缺陷 1：Entity 反向依賴~~ | `AccountDto ⇄ UserEntity` 循環已於 PR #112 解除；`Entity.fromDto` 經 `[A-8.2]` 與 `overview.md` 裁決為資料驅動分層架構，不加形式主義 Mapper | — |
| ✅ **已修復** | ~~缺陷 7：`locale` 重複指定~~ | `PlatformApp` 已移除 `locale: zh_TW` 硬鎖，統一由 `S.load` 與 `supportedLocales` 決定 | 低 |
| **P3** | 缺陷 5、6 | 複雜度清理（三層單例雙重取用路徑、DI 註冊點分散），無外部行為改變 | 低 |
| **P3** | 缺陷 8、9 | 介面設計；動到公開契約需同步改呼叫端 | 中 |

> **原 P0 兩項之「啟動白屏」（缺陷 3）與「release 印出完整請求」（缺陷 2 呼叫端）均已解除；剩餘 `dio_client.dart` 建構子預設值與攔截器順序僅約 5 行改動即可徹底收尾。**
