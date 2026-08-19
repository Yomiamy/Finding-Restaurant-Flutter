# Finding Restaurant App - 整體架構概覽 (Overview)

> 「差勁的程式員只擔心程式碼，優秀的程式員關心資料結構。」 —— Linus Torvalds

`flutter_restaruant` 是一個餐廳探索與收藏的 Flutter App。資料來源為 **Yelp Fusion API**（搜尋、詳情、評論）與 **Cloud Firestore**（使用者最愛清單），並整合多種第三方登入、FCM 推播與 AdMob 廣告。

本專案採 **Clean Architecture 三層分離** + **BLoC 單向資料流** + **GetIt 依賴注入**，並以 `PlatformWidget` 抽象處理 iOS／Android 的原生外觀分歧。

---

## 🏗️ 核心架構分層

依賴方向嚴格單向：**Presentation → Domain ← Data**。`domain/` 是最內層，不依賴任何外層或第三方套件。

```text
  ┌────────────────────────────────────────────────────────────┐
  │                 表現層 (Presentation Layer)                │
  │  lib/flow/<feature>/view/  ── Page + Widget                │
  │  lib/flow/<feature>/bloc/  ── Bloc / Event / State         │
  │  lib/component/  [PlatformWidget] [Cell] [Ad] [Loading]    │
  │  lib/features/foundation/style/  ── Design Tokens          │
  └─────────────────────────────┬──────────────────────────────┘
                                │ 發送 Event / 監聽 State
                                ▼
  ┌────────────────────────────────────────────────────────────┐
  │              路由與注入接縫 (Composition Root)             │
  │   [routesTable]  ── BlocProvider + GetIt.I<Repository>()   │
  │   [setupInjection]  ── GetIt 註冊介面 → 實作                │
  └─────────────────────────────┬──────────────────────────────┘
                                │ 建構子注入 Repository 介面
                                ▼
  ┌────────────────────────────────────────────────────────────┐
  │                   領域層 (Domain Layer)                    │
  │   lib/domain/repositories/  ── abstract interface class    │
  │   ⚠️ 介面層乾淨：5 個介面皆不 import data_layer            │
  │   lib/domain/entities/      ── Entity (業務模型)            │
  │   🔴 11/11 entity 反向 import data_layer/dto（見下方缺陷）  │
  └─────────────────────────────▲──────────────────────────────┘
                                │ implements（依賴反轉）
                                │ ▲ 但 entity 有反向 import ─┐
  ┌─────────────────────────────┴──────────────────────────────┐
  │                    資料層 (Data Layer)                     │
  │   lib/data_layer/repositories/  ── Repo 實作                │
  │   lib/data_layer/dto/           ── Dto (@JsonSerializable) │
  │   lib/data_layer/datasources/   ── FavorDataSource         │
  └─────────────────────────────┬──────────────────────────────┘
                                │
                                ▼
  ┌────────────────────────────────────────────────────────────┐
  │                外部資源 (External Sources)                 │
  │  [APIClz @RestApi] ──► Yelp Fusion API (經 Dio)            │
  │  [FavorDataSource] ──► Cloud Firestore                     │
  │  [Manager × 9]     ──► Firebase Auth / FCM / 生物辨識 / 廣告 │
  └────────────────────────────────────────────────────────────┘
```

### 1. 領域層 (Domain Layer) — 架構的錨點（但錨沒有完全打穩）

- **不依賴 I/O 技術**：`lib/domain/` 全目錄**沒有** import `dio`、`cloud_firestore`、`shared_preferences`、`retrofit`。業務契約確實獨立於任何網路／資料庫技術。
- **`abstract interface class` 契約**：五個 Repository 介面（`MainRepository`、`RestaurantDetailRepository`、`FavorRepository`、`SignInRepository`、`SettingsRepository`）以 Dart 3 的 `abstract interface class` 宣告，明確表達「只能被 implement，不能被 extend」。**這 5 個介面檔案全數乾淨**，不 import 任何 data_layer 內容。
- **Entity 為業務模型**：`RestaurantEntity`、`RestaurantDetailEntity`、`UserEntity`、`ReviewEntity` 等 11 個。

#### 🔴 已知架構缺陷：Entity 反向依賴 DTO

**11 個 entity 檔案全數 `import '../../data_layer/dto/dto_barrel.dart'`**，理由是轉換方法被放在 Entity 自己身上：

```dart
// lib/domain/entities/restaurant_entity.dart:1
import '../../data_layer/dto/dto_barrel.dart';   // ← domain 反向依賴 data

factory RestaurantEntity.fromDto(YelpRestaurantSummaryDto dto) => ...
YelpRestaurantSummaryDto get toDto => ...
```

更嚴重的是 **`AccountDto` ⇄ `UserEntity` 構成真實的循環 import**：`account_dto.dart:2` import domain entities（為取得 `AccountType` enum），而 `user_entity.dart:2` import data_layer dto。Dart 允許循環 import 故編譯不會失敗，但**這代表 domain 層物理上無法獨立於 data_layer 抽出編譯或測試**。

另有兩處橫向洩漏：`sign_in_repository.dart:2` 與 `restaurant_business_time_entity.dart:2` import `features/utils/utils_barrel.dart`，而該 barrel 間接拉進 `geolocator` 與 `url_launcher`——一個 domain entity 只為了判斷語系，就把定位與瀏覽器套件掛上了。

> 🐧 **Linus 式評註**：「依賴方向」不是靠目錄名字決定的，是靠 import 決定的。目前的 `domain/` 目錄名字說它是內層，import 說它不是。修法很明確——**把 `fromDto`/`toDto` 從 Entity 搬到 data_layer 的 mapper**，Entity 就不再需要認識 DTO，循環自然消失。這不是理論潔癖：真要為 domain 寫獨立單元測試時，現在得把整個 data_layer 一起拖進來。

### 2. 資料層 (Data Layer) — 實作契約，向內依賴

- **`*Repo` implements `*Repository`**：`MainRepo`、`RestaurantDetailRepo`、`FavorRepo`、`SignInRepo`、`SettingsRepo`。依賴方向朝內——`data_layer` import `domain`，反之絕無。
- **Dto 與 Entity 分離**：`lib/data_layer/dto/` 下的 `Yelp*Dto` 以 `@JsonSerializable` 標註，由 `json_serializable` 產生 `*.g.dart`。Dto 是 API 線上格式的鏡射（欄位名對齊 Yelp JSON），Entity 才是 App 內部使用的模型。
- **轉換點明確**：`RestaurantEntity.fromDto(dto)` 一律在 `data_layer` 內呼叫（`main_repo.dart:63`、`restaurant_detail_repo.dart:22,29`、`sign_in_repo.dart:43`、`favor_data_source.dart:52`）。**Dto 永不外洩到 Presentation 層。**
- **`FavorDataSource`**：最愛清單在 Firestore 的**單一存取點**，每個最愛項目以 subcollection `favors/{uid}/items/{restaurant_id}` 結構儲存。內含空字串 uid 的 guard——少了它 Firestore 會拋 `ArgumentError`。

### 3. 表現層 (Presentation Layer)

- **Feature-First 目錄**：`lib/flow/<feature>/` 下再分 `bloc/` 與 `view/`，每個 feature 自成一個垂直切片（main、restaurant、favor、signinup、settings、splash、filter、photo_viewer）。
- **BLoC 單向資料流**：`Bloc<Event, State>` + `Equatable`。State 以**具名子類別**表達（`MainInitial` / `InProgress` / `Success` / `Failure` / `LoadMoreSuccess` / `ToggleFavorSuccess`），而非單一 class 塞 `isLoading` 布林旗標——狀態互斥性由型別系統保證。
- **`PlatformWidget<I, A>`**：泛型抽象類別，以 `Platform.isAndroid` / `Platform.isIOS` 分派到 `createAndroidWidget` / `createIosWidget`。子類別必須同時提供兩個平台的實作，**分歧在編譯期就被強制處理**。
- **Design Tokens**：`lib/features/foundation/style/` 下的 `AppThemeData`、`ThemeColor`、`ThemeSize`、`ThemeFontSize`、`ThemeTextStyle`。

### 4. 跨層設施 (Cross-cutting)

- **`Manager` 層（9 個）**：`SignInManager`、`FcmManager`、`AdCounterManager`、`GoogleSignInManager`、`AppleSignInManager`、`FacebookSignInManager`、`MailSignInUpManager`、`AutoSignInManager`、`BiometricSignInManager`。全數採**同一套 Singleton 模式**（`static final _singleton` + `factory` 回傳），各自封裝一個第三方 SDK 的互動細節。
- **`FlutterInspector`（debug-only）**：`lib/di/inspector.dart` 的頂層 `final FlutterInspector?`，`kDebugMode` 為 `false` 時恆為 `null`，所有引用點成為 dead code 被 tree-shaking 移除。

---

## 🛠️ 架構設計原則與「好品味」

### 1. 依賴反轉是靠 GetIt 註冊「介面 → 實作」落實的

`lib/di/injection.dart` 的註冊全部以**介面**為 key、**實作**為 value：

```dart
getIt.registerLazySingleton<MainRepository>(
    () => MainRepo(favorDataSource: getIt<FavorDataSource>()));
```

Presentation 層要 `MainRepository`（介面），拿到的是 `MainRepo`（實作）。**Bloc 完全不知道實作類別的存在**——這讓測試時可注入 fake，也讓資料來源抽換不波及 UI。全數使用 `registerLazySingleton`：第一次取用才建構，之後共用同一實例。

### 2. `routesTable` 是 Composition Root

`lib/routes/routes_table.dart` 是全 App 唯一把「路由 → Bloc → Repository」三者接起來的地方：

```dart
MainPage.routeName: (context) => BlocProvider<MainBloc>(
    create: (_) => MainBloc(repository: GetIt.I<MainRepository>()),
    child: const MainPage()),
```

- **Bloc 的生命週期綁定路由**：`BlocProvider` 建在 route builder 內，頁面 pop 時 Bloc 自動 dispose，不需手動管理。
- **Page 本身是 `const`**：Page widget 不接收 Bloc，靠 `context.read<MainBloc>()` 取用，因此可宣告為 `const`，減少重建成本。
- **無 Bloc 的頁面就不包**：`FilterPage`、`PhotoViewer`、`SplashPage` 直接建構，不為了「一致性」硬套 BlocProvider。

### 3. 攔截器順序決定除錯工具看得到什麼

`lib/api/api_clz.dart` 的 `dioClient` 以 IIFE 建構，最終的攔截器鏈為三層：

| # | Interceptor | 註冊處 | 條件 |
| :--- | :--- | :--- | :--- |
| 0 | `LogInterceptor(requestBody: true, responseBody: true)` | `dio_client.dart:24` | `isLogEnabled` 預設 `true`，**無 `kDebugMode` 圍堵** |
| 1 | `InterceptorsWrapper` — 注入 `Authorization` | `api_clz.dart:57`（經 `interceptWraps`） | 恆常 |
| 2 | `FlutterInspectorDioInterceptor` | `api_clz.dart:71` | `kDebugMode && inspector != null` |

Dio 的 request 攔截器**依註冊順序正向執行**（0→1→2），response/error 則**反向**（2→1→0）。

**Inspector 排在 auth 之後是正確且必要的**：它的 `onRequest` 以 `requestHeaders: options.headers` 取當下快照，因此看得到已注入的 `Authorization`。順序反過來，除錯面板會顯示一個沒有 Authorization 的假請求——那正是排查 401 時最會誤導人的畫面。

> 🔴 **已知缺陷：`LogInterceptor` 會在 release build 印出完整請求與回應**
>
> `DioClient` 的 `isLogEnabled` 預設 `true` 且呼叫端未覆寫，因此 `LogInterceptor(requestBody: true, responseBody: true)` **在 release 版仍然生效**，把完整 request/response body 寫進 stdout。這與 Inspector 嚴謹的 `kDebugMode` 雙重防護形成明顯落差——一邊嚴防除錯資訊外洩，另一邊預設全開。
>
> 附帶一個一致性問題：`LogInterceptor` 位於 index 0、**早於** auth 注入，所以它印的 header **不含** `Authorization`。同一個請求，兩個除錯管道顯示兩份不同的 header 快照。
>
> **建議修法**：`isLogEnabled` 預設改為 `kDebugMode`，並將其註冊順序移到 auth 之後。

### 4. 平台分歧在編譯期強制處理，而非執行期猜測

`PlatformWidget<I extends Widget, A extends Widget>` 用泛型參數分別約束 iOS 與 Android 的回傳型別，兩個抽象方法都是 `required`：

```dart
I createIosWidget(BuildContext context);
A createAndroidWidget(BuildContext context);
```

繼承它就**必須**寫兩個平台的實作，漏掉一個編譯不過。這比在 build 裡散落 `if (Platform.isIOS)` 判斷更能消滅「某個平台忘了處理」這類特殊情況。

> ⚠️ **已知邊界**：`PlatformWidget` 走 `dart:io` 的 `Platform`，因此**不支援 Web**（Web 會拋出）。目前專案定位為 iOS／Android 雙平台，這是實用主義下的合理取捨，而非疏漏。

### 5. Theme 必須繞過 `PlatformApp` 的 Cupertino 分支

iOS 走 `CupertinoApp` 分支時 `material:` 的設定**根本不會被呼叫**，Material widget 會退回 Flutter 預設色票。因此 `main.dart` 額外用 `builder:` 包一層 `Theme`，讓兩個平台都吃得到 `AppThemeData.materialLight`。

`AppThemeData` 的色票只做 `ColorScheme.fromSeed`，**零 `copyWith` 覆寫**——種子色決定整組色階，不手動微調個別顏色，避免色票之間互相矛盾。

### 6. Debug 工具絕不進 production build

`lib/di/inspector.dart` 以三元運算在**編譯期**決定：

```dart
final FlutterInspector? inspector = kDebugMode ? FlutterInspector(...) : null;
```

`kDebugMode` 是編譯期常數，release build 中整個 `FlutterInspector(...)` 建構式成為不可達分支，連同其傳遞相依一併被 tree-shaking 移除。所有使用端（`main.dart` 的 `navigatorObservers`、`MagicalTap`、`api_clz.dart` 的攔截器、`splash_page.dart` 的 FAB）皆為 `null` 檢查或 `?.` 呼叫，release 行為零改變。

這道防線的必要性在於：除錯面板會顯示**完整的請求／回應 body（含 `Authorization` header）**。若隨 release 出貨，等同把 API 金鑰直接攤給終端使用者。
