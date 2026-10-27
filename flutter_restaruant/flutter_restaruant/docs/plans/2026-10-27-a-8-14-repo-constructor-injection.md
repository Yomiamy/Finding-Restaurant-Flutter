# 實作計畫：A-8.14 Repository 改以建構子注入 `APIClz` 與 `locale`

> 項目編號：**A-8.14**
> 建立日期：2026-10-27
> 關聯規格：[`docs/features/2026-10-27-repo-constructor-injection.md`](../features/2026-10-27-repo-constructor-injection.md)（下稱「規格」，§、AC、D、R 編號沿用規格）
> 實查基線：`new-main/main` @ `b78a332`
> 狀態：待執行。STAGE 0b 修正過 1 次，回應 plan-verifier 初審：修正執行目錄、範圍檢查改加 `--relative`、比對基準改用 merge-base，並補上停止條件與檢查。規格 §7 的 D-1～D-3 已由使用者確認，本計畫只處理「怎麼做」

---

## 1. 目標

6 個 Repository 不再自己去全域拿 `APIClz` 與 `Constants.locale`，改由 `lib/app/di/injection.dart` 從建構子注入。純重構，使用者可見行為不變，不新增測試、不新增相依。

資料流改成單向：`getIt<APIClz>()`／`Constants.locale` → `injection.dart` → Repository 欄位 `_api`／`_locale` → `APIClz` 呼叫。

---

## 2. 實作方向與 Trade-off

### 2.1 任務怎麼切

| 方向 | 作法 | 評估 |
|---|---|---|
| A. 6 組，各一個任務，序列 | 1 個 Repository ＋ 它在 `injection.dart` 的那一行 ＋ 它的測試 | 6 個任務都寫 `injection.dart`，只能序列。`MainRepo` 與 `RestaurantDetailRepo` **共用** `test/repository_test.dart`，拆成兩個任務時，同一個測試檔會被寫兩次，而 `_MockAPIClz` 只有第一個任務會新增 |
| **B. 2 組，序列（採用）** | T1：4 個 Yelp Repository；T2：`MainRepo` ＋ `RestaurantDetailRepo` | 每組內的 diff 型態完全相同，一次 review 完。除了 `injection.dart`，每個檔案只屬於一個任務 |
| C. 一個任務做完 | 12 個檔案一次改完 | diff 約 150 行，中途壞掉沒有檢查點 |

**選 B。** 判準：

- **4 個 Yelp Repository 是同質的**：本來就有 `final APIClz _api` 與 `api` 參數，改動只有「`api` 改 `required`、刪退路、加 `_locale`」，測試也都是把 `Constants.locale` 換成 `_Data.locale`。拆成 4 個任務只會多跑 3 次相同的驗收流程。
- **`MainRepo` 與 `RestaurantDetailRepo` 是同質的**：兩者都從「每次呼叫查 `GetIt.I<APIClz>()`」改成欄位，而且共用同一個測試檔。
- **兩組都會寫 `injection.dart`，所以 T1 → T2 序列執行**，不並行。T1 先做，因為 `injection.dart` 的 `constants_barrel` import 由 T1 加入，T2 直接沿用。

### 2.2 已核對的事實

在專案目錄執行 `git archive b78a332`（只會打包 `flutter_restaruant/flutter_restaruant` 子樹），解出 scratch 副本，實測本計畫 §3 的全部程式碼片段（scratch 已刪除）：

- 本次要寫入的 12 個手寫檔，在基線都符合 `dart format`（`--set-exit-if-changed` 結果為 `0 changed`）。所以每個任務都可以直接整檔執行 `dart format`。
- §3 的片段經過 `dart format` 後零差異（`YelpCategoryRepo.fetchCategories` 會併成一行，§3.1 已經是併好的版本）。
- `flutter analyze lib test/repository_test.dart test/di_test.dart test/app_theme_platform_test.dart test/data_layer/yelp_{autocomplete,category}_repo_test.dart`：`No issues found!`。
- 同一組測試檔，`flutter test` 共 26 個 test 全綠。
- `yelp_business_repo_test.dart`、`yelp_event_repo_test.dart` **沒有**在 scratch 實測；它們的改法與另外兩個 Yelp 測試相同。
- `app_theme_platform_test` 印出的 `[FlutterInspector] notification init failed: LateInitializationError…` 在基線就有，與本次改動無關。
- `flutter pub get` 不會改動 `pubspec.lock`（該檔有進版控）。
- `lib/domain/repositories/yelp_category_repository.dart:7` 的 doc comment 寫著「固定帶 `Constants.locale`」。**不改**：注入的值仍是 `Constants.locale`，敘述仍然成立；而且 AC-6 禁止改動 `lib/domain`。

---

## 3. 資料結構（最終程式碼）

### 3.1 4 個 Yelp Repository

建構子與欄位一律如下。以 `YelpAutocompleteRepo` 為例；其他 3 個只差在類別名稱、domain import，以及檔案中既有的 `static const` 常數：

```dart
import '../../api/api_barrel.dart';
import '../../domain/repositories/yelp_autocomplete_repository.dart';

class YelpAutocompleteRepo implements YelpAutocompleteRepository {
  final APIClz _api;
  final String _locale;

  YelpAutocompleteRepo({required APIClz api, required String locale})
    : _api = api,
      _locale = locale;
```

- 刪除 `import 'package:get_it/get_it.dart';` 與 `import '../../app/constants/constants_barrel.dart';`。
- `static const` 常數（`YelpBusinessRepo` 的 `_transactionType`、`_listSeparator`，`YelpEventRepo` 的 `_listSeparator`）和它們的註解原樣保留在欄位之前。
- 各方法內的 `Constants.locale` 一律改為 `_locale`，其餘參數不動：

| 檔案（`lib/data_layer/repositories/`） | 基線行號 | 改後 |
|---|---|---|
| `yelp_autocomplete_repo.dart` | :19 | `locale: _locale,` |
| `yelp_business_repo.dart` | :19、:86、:95 | `_api.businessesSearchByPhone(phone, _locale)`、`_api.businessServiceOfferings(businessIdOrAlias, _locale)`、`locale: _locale,` |
| `yelp_category_repo.dart` | :14、:18 | 見下方 |
| `yelp_event_repo.dart` | :31、:49、:57 | `locale: _locale,`、`_api.event(eventId, _locale)`、`locale: _locale,` |

`yelp_category_repo.dart` 改完後，兩個方法如下：

```dart
  @override
  Future<YelpCategoryListDto> fetchCategories() => _api.categories(_locale);

  @override
  Future<YelpCategoryDetailDto> fetchCategory(String alias) =>
      _api.category(alias, _locale);
```

### 3.2 `MainRepo` 與 `RestaurantDetailRepo`

兩者都刪除 `get_it` 與 `app/constants` 的 import，其他 import（`dart:async`、`api_barrel`、`models/model_barrel` 等）不動。

```dart
// main_repo.dart
class MainRepo implements MainRepository {
  static const int _maxItemsCountInList = 50;

  final APIClz _api;
  final String _locale;
  final FavorDataSource _favorDataSource;

  @override
  Set<RestaurantEntity> summaryInfoSet = {};
  int _offset = 0;
  String _keyword = '';
  bool _isLoading = false;

  MainRepo({
    required APIClz api,
    required String locale,
    FavorDataSource? favorDataSource,
  }) : _api = api,
       _locale = locale,
       _favorDataSource = favorDataSource ?? FavorDataSource() {
    reset();
  }
```

建構子 body 的 `reset();` 必須保留（AC-9、規格 R-3）。`fetchYelpSearchInfo` 內只改兩處：

- `:52` `await GetIt.I<APIClz>().businessesSearch(` 改為 `await _api.businessesSearch(`
- `:56` `locale: Constants.locale,` 改為 `locale: _locale,`

```dart
// restaurant_detail_repo.dart
class RestaurantDetailRepo implements RestaurantDetailRepository {
  final APIClz _api;
  final String _locale;
  final FavorDataSource _favorDataSource;

  RestaurantDetailRepo({
    required APIClz api,
    required String locale,
    FavorDataSource? favorDataSource,
  }) : _api = api,
       _locale = locale,
       _favorDataSource = favorDataSource ?? FavorDataSource();

  @override
  Future<RestaurantDetailEntity> fetchYelpRestaurantDetailInfo(
    String id,
  ) async {
    YelpRestaurantDetailDto detailDto = await _api.business(id, _locale);
    return RestaurantDetailEntity.fromDto(detailDto);
  }

  @override
  Future<ReviewEntity> fetchYelpRestaurantReviewInfo(String id) async {
    YelpReviewDto reviewDto = await _api.review(id, _locale);
    return ReviewEntity.fromDto(reviewDto);
  }
```

`toggleFavor` 不動。

### 3.3 `injection.dart`

import 區塊最後新增一行（T1 加入，之後的行號都會下移 1 行）：

```dart
import '../constants/constants_barrel.dart';
```

6 個註冊改為下列內容。註冊型別、順序、`registerLazySingleton` 都不變（AC-10）：

```dart
  getIt.registerLazySingleton<MainRepository>(
    () => MainRepo(
      api: getIt<APIClz>(),
      locale: Constants.locale,
      favorDataSource: getIt<FavorDataSource>(),
    ),
  );
  getIt.registerLazySingleton<RestaurantDetailRepository>(
    () => RestaurantDetailRepo(
      api: getIt<APIClz>(),
      locale: Constants.locale,
      favorDataSource: getIt<FavorDataSource>(),
    ),
  );
  // FavorRepo … ReviewSummaryRepo 的 6 個註冊不動
  getIt.registerLazySingleton<YelpBusinessRepository>(
    () => YelpBusinessRepo(api: getIt<APIClz>(), locale: Constants.locale),
  );
  getIt.registerLazySingleton<YelpEventRepository>(
    () => YelpEventRepo(api: getIt<APIClz>(), locale: Constants.locale),
  );
  getIt.registerLazySingleton<YelpCategoryRepository>(
    () => YelpCategoryRepo(api: getIt<APIClz>(), locale: Constants.locale),
  );
  getIt.registerLazySingleton<YelpAutocompleteRepository>(
    () => YelpAutocompleteRepo(api: getIt<APIClz>(), locale: Constants.locale),
  );
```

---

## 4. 破壞性分析

### 4.1 建構子呼叫點（`git grep` 實查 `b78a332`）

在專案目錄（§5.0）執行：

```bash
rtk proxy git grep -n -E "(MainRepo|RestaurantDetailRepo|YelpAutocompleteRepo|YelpBusinessRepo|YelpCategoryRepo|YelpEventRepo)\(" b78a332 -- lib test
```

扣掉 6 個建構子宣告本身，呼叫點共 **12 處**，全部由 T1、T2 涵蓋：

| 呼叫點 | 現況 | 負責任務 |
|---|---|---|
| `lib/app/di/injection.dart:25` | `MainRepo(favorDataSource: …)` | T2 |
| `lib/app/di/injection.dart:28` | `RestaurantDetailRepo(favorDataSource: …)` | T2 |
| `lib/app/di/injection.dart:40` | `YelpBusinessRepo()` | T1 |
| `lib/app/di/injection.dart:41` | `YelpEventRepo()` | T1 |
| `lib/app/di/injection.dart:42` | `YelpCategoryRepo()` | T1 |
| `lib/app/di/injection.dart:44` | `YelpAutocompleteRepo()` | T1 |
| `test/data_layer/yelp_autocomplete_repo_test.dart:23` | `YelpAutocompleteRepo(api: api)` | T1 |
| `test/data_layer/yelp_business_repo_test.dart:43` | `YelpBusinessRepo(api: api)` | T1 |
| `test/data_layer/yelp_category_repo_test.dart:24` | `YelpCategoryRepo(api: api)` | T1 |
| `test/data_layer/yelp_event_repo_test.dart:24` | `YelpEventRepo(api: api)` | T1 |
| `test/repository_test.dart:29` | `MainRepo()` | T2 |
| `test/repository_test.dart:44` | `RestaurantDetailRepo()` | T2 |

`required` 參數保證漏改一定編譯失敗，T1、T2 的 `flutter analyze` 就是完整性檢查。

### 4.2 間接影響（不寫入，但要保持綠燈）

| 位置 | 影響 | 結論 |
|---|---|---|
| `test/di_test.dart` | 解析全部 6 個 Repository，現在會在建構時取得 `APIClz` | 基線的 Yelp Repository 本來就在建構時呼叫 `GetIt.I<APIClz>()`，`di_test` 也已經先解析過 `APIClz`。scratch 實測全綠。AC-6 禁止改動此檔 |
| `test/app_theme_platform_test.dart` | 3 秒 Splash 之後導向主頁，`MainBloc` 解析 `MainRepository` 時，`dioClient` 因而提早求值（規格 R-2） | `dioClient` 求值時讀取的 `inspector` 在 `pumpWidget` 階段就已經求值過，不會重新掛上 error hook。scratch 實測 iOS、Android 兩個 case 都綠 |
| `lib/domain/` | 建構子不屬於介面 | 不動（AC-6） |
| `pubspec.yaml`／`pubspec.lock` | `get_it` 仍由 `injection.dart` 使用；`mocktail` 已經是 dev 相依 | 不動（AC-6） |

---

## 5. 任務拆分

### 5.0 共通流程

**執行目錄**：STAGE 1 會從 `new-main/main` 建立專屬的 worktree 與 feature branch，並把規格與本計畫 commit 進去。

- **所有指令都在 `<worktree>/flutter_restaruant/flutter_restaruant` 執行**。git root 在它的上兩層。
- subagent 的 cwd 每次呼叫都會重設，所以每次 Bash 呼叫都要先 `cd` 到這個目錄。
- 在錯的目錄執行時，`flutter` 會直接失敗；但「預期：無輸出」的 grep 會因為路徑不存在而**假通過**；落在原始 checkout（`temp` 分支，prefix 相同）時 analyze／test 也會假綠。所以每個任務的第一組指令都是目錄檢查，**任一項不符就停止並回報**：

  ```bash
  rtk proxy git rev-parse --show-prefix   # 預期：flutter_restaruant/flutter_restaruant/
  rtk proxy git branch --show-current     # 預期：STAGE 1 建立的 feature branch（不是 temp／main）
  ```

**比對基準**：與基線比較的指令一律用 `"$(git merge-base HEAD new-main/main)"`，不直接寫 `new-main/main`。這樣 #162、#164 合併進 `new-main/main` 之後，基準也不會移動、造成假失敗。若 branch 是從目前的 `new-main/main` 開出，merge-base 就是 `b78a332`。任務之間的比較則以上一個任務的 commit（`HEAD`）為基線。

**證據指令一律加 `rtk proxy`**。所有拿來當判斷依據的輸出都要看原文，例如 analyze、test 的結尾行、git diff／status／show、grep，避免被 hook 壓縮成摘要。

**每個寫入任務都照這個流程**：

1. 目錄檢查（見上）。
2. **先改測試**，執行後確認是紅燈（編譯失敗，訊息見各任務）。
3. 改 Repository，再改 `injection.dart`。
4. 驗收：

   ```bash
   dart format <本任務寫入的 .dart 檔>             # 基線都符合格式，可以整檔執行
   rtk proxy flutter analyze                       # 預期：No issues found!
   rtk proxy flutter test <本任務的測試檔> 2>&1 | tail -1    # 預期：All tests passed!
   rtk proxy flutter test 2>&1 | tail -1           # 預期：All tests passed!，通過數 = N0（本項不增減 test）
   { rtk proxy git diff --name-only --relative HEAD; rtk proxy git ls-files --others --exclude-standard; } | sort
                                                   # 預期：恰好是本任務「寫入檔案」列出的路徑
   ```

5. 驗收通過後由 workflow commit（gen-commit）。subagent 不自行 commit。

### 5.1 任務總表

| 編號 | 標題 | 寫入檔案 | 前置 | 預估 |
|---|---|---|---|---|
| T0 | 基線 | 無 | — | 5 分 |
| T1 | 4 個 Yelp Repository | 4 個 `yelp_*_repo.dart`、4 個 `yelp_*_repo_test.dart`、`injection.dart` | T0 | 12 分 |
| T2 | `MainRepo` ＋ `RestaurantDetailRepo` | `main_repo.dart`、`restaurant_detail_repo.dart`、`repository_test.dart`、`injection.dart` | T1 | 8 分 |
| T3 | 全域驗收 | 無 | T2 | 5 分 |

**全部序列執行。** T1 與 T2 都寫 `injection.dart`；T2 沿用 T1 加入的 `constants_barrel` import。

---

### T0：基線（5 分）

```bash
rtk proxy git rev-parse --show-prefix               # 預期：flutter_restaruant/flutter_restaruant/
rtk proxy git branch --show-current                 # 預期：STAGE 1 建立的 feature branch
rtk proxy git diff --stat b78a332 "$(git merge-base HEAD new-main/main)" -- lib test   # 預期：無輸出（基準仍是 b78a332，否則行號失準，停止）
flutter pub get
rtk proxy git status --porcelain -- .               # 預期：無輸出
rtk proxy flutter analyze                           # 預期：No issues found!
rtk proxy flutter test 2>&1 | tail -1               # 預期：All tests passed!，記錄通過數 N0
rtk proxy grep -rn -E "get_it|GetIt" lib/data_layer | wc -l     # 記錄：13
rtk proxy grep -rln "app/constants" lib/data_layer | wc -l      # 記錄：8
```

**停止條件**：只要符合下列任一項，就**停止執行**並回報實際輸出，不要繼續 T1：

- 目錄檢查不符。
- `git status` 有輸出。
- analyze 不是 `No issues found!`。
- test 不是全綠。

基線本身不乾淨時，後續任務無法判斷問題是不是本次改動造成的。

不寫入任何檔案，不 commit。

---

### T1：4 個 Yelp Repository（12 分）

- **寫入檔案（9 個）**：
  - `lib/data_layer/repositories/yelp_{autocomplete,business,category,event}_repo.dart`
  - `test/data_layer/yelp_{autocomplete,business,category,event}_repo_test.dart`
  - `lib/app/di/injection.dart`
- **對應 AC**：AC-5、AC-7、AC-8、AC-10、AC-11（Yelp 部分）

**步驟 1：改 4 個測試檔（紅燈）**

每個測試檔做同樣 4 件事：

1. 刪除 `import 'package:flutter_restaruant/app/constants/constants_barrel.dart';`。
2. 在 `_Data` 的第一個成員前加入下列兩行。註解不可提到 `Constants`，否則 AC-5 的 grep 會命中：

   ```dart
     // 刻意不等於正式值 'zh_TW'，才分辨得出轉發的是注入值。
     static const String locale = 'en_US';
   ```

3. `setUp` 的建構改為 `XxxRepo(api: api, locale: _Data.locale)`。
4. 程式碼中的 `Constants.locale` 全部改為 `_Data.locale`；test 名稱依下表改寫。

| 檔案 | 改後的 test 名稱（基線行號） |
|---|---|
| `yelp_autocomplete_repo_test.dart` | `autocomplete 帶入 text、注入的 locale 與座標`（:27） |
| `yelp_business_repo_test.dart` | `searchByPhone 帶入注入的 locale`（:47）、`fetchServiceOfferings 帶入注入的 locale`（:141）、`fetchReviewHighlights 帶入 count 與注入的 locale`（:152） |
| `yelp_category_repo_test.dart` | `fetchCategories 帶入注入的 locale`（:28）、`fetchCategory 帶入 alias 與注入的 locale`（:38） |
| `yelp_event_repo_test.dart` | `searchEvents 帶入注入的 locale，兩個 List 以逗號串接`（:28）、`fetchEvent 帶入注入的 locale`（:92）、`fetchFeaturedEvent 帶入注入的 locale`（:103） |

其他 test 的名稱與本體不動。改完後確認：

```bash
rtk proxy grep -n "Constants" test/data_layer/yelp_{autocomplete,business,category,event}_repo_test.dart
                                          # 預期：無輸出（AC-5）
rtk proxy grep -c "注入的 locale" test/data_layer/yelp_{autocomplete,business,category,event}_repo_test.dart
                                          # 預期：1、3、2、3
rtk proxy grep -c "_Data.locale" test/data_layer/yelp_{autocomplete,business,category,event}_repo_test.dart
                                          # 預期：2、7、3、5（setUp 1 處 ＋ 基線 Constants.locale 的程式碼處數）
rtk proxy flutter test test/data_layer/yelp_{autocomplete,business,category,event}_repo_test.dart
                                          # 預期：紅燈，編譯錯誤 No named parameter with the name 'locale'
```

**步驟 2：改 4 個 Repository**

照 §3.1 修改。

**步驟 3：改 `injection.dart`**

- import 區塊最後加上 `import '../constants/constants_barrel.dart';`。
- 4 個 Yelp 註冊改為 §3.3 的寫法。它們在基線的 `:40-45`，加入 import 後變成 `:41-46`。

**步驟 4：驗收**

先跑 §5.0 第 4 步的指令（`dart format` 的對象是本任務寫入的 9 個檔案）。另外確認：

```bash
rtk proxy grep -n -E "get_it|GetIt|app/constants" lib/data_layer/repositories/yelp_*_repo.dart
                                          # 預期：無輸出
rtk proxy grep -c "locale: Constants.locale" lib/app/di/injection.dart
                                          # 預期：4
```

---

### T2：`MainRepo` ＋ `RestaurantDetailRepo`（8 分）

- **寫入檔案（4 個）**：
  - `lib/data_layer/repositories/main_repo.dart`
  - `lib/data_layer/repositories/restaurant_detail_repo.dart`
  - `test/repository_test.dart`
  - `lib/app/di/injection.dart`
- **對應 AC**：AC-3、AC-4、AC-7～AC-10、AC-12

**步驟 1：改 `test/repository_test.dart`（紅燈）**

- 新增兩個 import：`package:flutter_restaruant/api/api_barrel.dart`、`package:mocktail/mocktail.dart`，依字母序插入既有 import 之間。
- 在 `void main()` 之前加入：

  ```dart
  class _MockAPIClz extends Mock implements APIClz {}

  class _Data {
    static const String locale = 'en_US';
  }
  ```

- 只改兩個建構點，斷言原樣保留（AC-9、AC-12）：

  ```dart
        final repo = MainRepo(api: _MockAPIClz(), locale: _Data.locale);
  ```

  ```dart
          final repo = RestaurantDetailRepo(
            api: _MockAPIClz(),
            locale: _Data.locale,
          );
  ```

```bash
rtk proxy flutter test test/repository_test.dart    # 預期：紅燈，編譯錯誤 No named parameter with the name 'api'
```

**步驟 2：改 2 個 Repository**

照 §3.2 修改。

**步驟 3：改 `injection.dart`**

2 個註冊改為 §3.3 的寫法。它們在基線的 `:24-29`，因為 T1 加了 1 行 import，現在是 `:25-30`。

**步驟 4：驗收**

先跑 §5.0 第 4 步的指令（`dart format` 的對象是本任務寫入的 4 個檔案）。另外確認：

```bash
rtk proxy grep -rn -E "get_it|GetIt" lib/data_layer           # 預期：無輸出（AC-3）
rtk proxy grep -rln "app/constants" lib/data_layer            # 預期：只有 settings_repo.dart、sign_in_repo.dart（AC-4）
rtk proxy grep -n -A1 "_favorDataSource = favorDataSource ?? FavorDataSource() {" lib/data_layer/repositories/main_repo.dart
                                                              # 預期：下一行是 reset();（AC-9）

# 兩處 API 轉發都改用欄位（AC-8）。這兩個 Repository 沒有轉發測試，只能靠計數鎖住
rtk proxy grep -c "_locale" lib/data_layer/repositories/main_repo.dart lib/data_layer/repositories/restaurant_detail_repo.dart
                                                              # 預期：main_repo 3、restaurant_detail_repo 4（欄位宣告 1 ＋ 初始化 1 ＋ 呼叫處）
rtk proxy grep -c "_api\." lib/data_layer/repositories/main_repo.dart lib/data_layer/repositories/restaurant_detail_repo.dart
                                                              # 預期：main_repo 1、restaurant_detail_repo 2
```

---

### T3：全域驗收（5 分）

對照規格 §3 逐條執行。不寫入任何檔案，不 commit。

```bash
rtk proxy git rev-parse --show-prefix             # 預期：flutter_restaruant/flutter_restaruant/

# AC-1、AC-2
rtk proxy flutter analyze                         # 預期：No issues found!
rtk proxy flutter test 2>&1 | tail -1             # 預期：All tests passed!，通過數 = N0

# AC-3：data 層不再依賴 GetIt
rtk proxy grep -rn -E "get_it|GetIt" lib/data_layer
                                                  # 預期：無輸出
rtk proxy grep -rn -E "getIt|apiInstance" lib/data_layer
                                                  # 預期：無輸出（也沒有改用 app 層的 getIt 或全域 apiInstance 繞路）

# AC-4：data 層只剩 settings_repo、sign_in_repo 依賴 app/
rtk proxy grep -rln "app/constants" lib/data_layer
                                                  # 預期：恰好 2 行（settings_repo.dart、sign_in_repo.dart）
rtk proxy grep -rln "app/" lib/data_layer
                                                  # 預期：同樣只有這 2 個檔（沒有改成依賴 app/ 的其他模組）

# AC-5：4 個 Yelp 測試不再引用 Constants
rtk proxy grep -n "Constants" test/data_layer/yelp_autocomplete_repo_test.dart test/data_layer/yelp_business_repo_test.dart test/data_layer/yelp_category_repo_test.dart test/data_layer/yelp_event_repo_test.dart
                                                  # 預期：無輸出

# AC-6：不新增相依、不改 di_test、不改 domain
rtk proxy git diff "$(git merge-base HEAD new-main/main)" --stat -- pubspec.yaml pubspec.lock test/di_test.dart lib/domain
                                                  # 預期：無輸出

# AC-7：6 個建構子都是 required APIClz api、required String locale
#   用 -o 逐一計數：Yelp 的兩個參數在同一行，用行數算會少算
rtk proxy grep -rno -E "required (APIClz api|String locale)" lib/data_layer/repositories | wc -l
                                                  # 預期：12（6 個檔案各 2 個）
rtk proxy grep -n "favorDataSource ?? FavorDataSource()" lib/data_layer/repositories/main_repo.dart lib/data_layer/repositories/restaurant_detail_repo.dart
                                                  # 預期：2 行

# AC-8：AC-3、AC-4 通過，加上 analyze 零問題，就代表 6 個 Repository 不可能再引用 GetIt 或 Constants，只剩注入的欄位可用
#       Main／Detail 的呼叫處另見 T2 步驟 4 的計數

# AC-9：見 T2 步驟 4 的 grep；repository_test 全綠已涵蓋斷言

# AC-10：6 個註冊都注入 api 與 locale；註冊型別與順序不變
rtk proxy grep -c "api: getIt<APIClz>()" lib/app/di/injection.dart          # 預期：6
rtk proxy grep -c "locale: Constants.locale" lib/app/di/injection.dart      # 預期：6
diff <(rtk proxy git show "$(git merge-base HEAD new-main/main)":./lib/app/di/injection.dart | rtk proxy grep -o "registerLazySingleton<[A-Za-z]*>") \
     <(rtk proxy grep -o "registerLazySingleton<[A-Za-z]*>" lib/app/di/injection.dart)
                                                  # 預期：無輸出

# AC-11：測試用的 locale 不是 zh_TW
rtk proxy grep -n "static const String locale" test/data_layer/yelp_*_repo_test.dart test/repository_test.dart
                                                  # 預期：5 行，值都是 'en_US'

# AC-12：repository_test 使用 _MockAPIClz
rtk proxy grep -c "_MockAPIClz" test/repository_test.dart                   # 預期：3

# 範圍：lib/test 只動了 12 個檔案
rtk proxy git diff --relative --name-only "$(git merge-base HEAD new-main/main)" -- lib test | sort
```

範圍檢查的預期輸出逐字如下，共 12 行，不多不少：

```text
lib/app/di/injection.dart
lib/data_layer/repositories/main_repo.dart
lib/data_layer/repositories/restaurant_detail_repo.dart
lib/data_layer/repositories/yelp_autocomplete_repo.dart
lib/data_layer/repositories/yelp_business_repo.dart
lib/data_layer/repositories/yelp_category_repo.dart
lib/data_layer/repositories/yelp_event_repo.dart
test/data_layer/yelp_autocomplete_repo_test.dart
test/data_layer/yelp_business_repo_test.dart
test/data_layer/yelp_category_repo_test.dart
test/data_layer/yelp_event_repo_test.dart
test/repository_test.dart
```

---

## 6. 測試計畫

| 檔案 | 改動 | test 數變化 | 對應 AC |
|---|---|---|---|
| `test/data_layer/yelp_{autocomplete,business,category,event}_repo_test.dart` | locale 改用 `_Data.locale`（`'en_US'`）。若 Repository 仍讀全域的 `'zh_TW'`，mock 的參數比對會失敗，所以這組測試能證明 Repository 轉發的是注入的值 | 0 | AC-5、AC-11 |
| `test/repository_test.dart` | `MainRepo`、`RestaurantDetailRepo` 改傳 `_MockAPIClz` 與 locale | 0 | AC-9、AC-12 |
| `test/di_test.dart`、`test/app_theme_platform_test.dart` | 不動，原樣全綠（§4.2） | 0 | AC-6 |

**不測**（規格 §4.2）：`MainRepo.fetchYelpSearchInfo`、`RestaurantDetailRepo` 的 API 轉發。本項只讓它們變得可以注入，補測試另案處理。T2 步驟 4 的 `_locale`／`_api.` 計數只是靜態檢查，用來確認呼叫處都已改用欄位，不是轉發測試。

---

## 7. 風險與回退

規格 R-1～R-4 的緩解方式不變。本計畫另外補充：

| # | 風險 | 緩解 |
|---|---|---|
| R-A | 把 `Constants.locale` 換成較短的 `_Data.locale` 後，`yelp_business_repo_test.dart`、`yelp_event_repo_test.dart` 的部分行可能被 `dart format` 重新折行 | 這是預期行為。這兩個檔案在基線就符合格式，所以整檔 `dart format` 只會影響本次改到的行 |
| R-B | 在 git root（而非專案目錄）執行指令，「預期無輸出」的 grep 會因路徑不存在而假通過 | §5.0 規定每個任務第一條指令就做 `git rev-parse --show-prefix` 目錄檢查；T0 不符就停止 |

**回退**：每個任務各有一個 commit。

- T2 可以單獨 `git revert`。
- T1 不能單獨回退：T2 的 `injection.dart` 註冊用到 T1 加入的 `constants_barrel` import。要回退 T1，必須先回退 T2。

---

## 8. 執行方式

1. **Subagent-driven，序列（建議）**
   - 依 T0 → T1 → T2 → T3 的順序，每個任務派一個 subagent。
   - subagent 只負責「目錄檢查 → 改測試（紅）→ 實作 → 驗收」，不 commit。
   - 主 agent 核對 §5.0 的檔案清單與通過數 N0 之後，交給 workflow commit，再派下一個任務。
   - 總計約 30 分鐘。改動是機械性的，review 成本低。
2. **Parallel session**
   - 另開一個 session，以 `executing-plans` 批次執行 T0 → T3，review 集中在最後處理。
   - T1、T2 都寫 `injection.dart`，**不能真的並行**。這個方式只適合想一次看完整個 diff 的情況。

文件同步（brainstorm [A-8.14] 狀態）由 STAGE 6 處理，不在本計畫內。

---

## 9. 退出標準

1. 規格 AC-1～AC-12 全部通過，T3 的指令全部符合預期。
2. feature branch 上 T1、T2 各有一個 commit。每個 commit 的檔案清單恰好等於該任務的「寫入檔案」，而且都能獨立通過 analyze 與 test。
3. `flutter test` 的通過數等於 N0，test 名稱只有 T1 表中的 9 個改寫。
4. `pubspec.yaml`、`pubspec.lock`、`test/di_test.dart`、`lib/domain/` 都沒有變動。
