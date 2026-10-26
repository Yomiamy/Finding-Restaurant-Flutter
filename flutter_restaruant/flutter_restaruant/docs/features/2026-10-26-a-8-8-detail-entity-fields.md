# 功能規格：A-8.8 補齊 Detail DTO／Entity 欄位、資訊欄顯示 displayPhone／price／Yelp 連結、刪除 `fetchToken`

- **日期**：2026-10-26
- **狀態**：草稿（STAGE 0a）。§7 的設計決策已有建議，STAGE 0b 可以推翻，但推翻時要一併改 §4 的驗收條件
- **實查基線**：`main` @ `b78a332`
- **需求來源**：gen-grill brief Q1–Q5，已放行（摘要見 §2.2）
- **相關 brainstorm 項目**：`docs/brainstorm/2026-10-26-features-brainstorm.md` §8.3.1 [A-8.8]（L1637-1653）。Summary 側已由 Issue #159／PR #160 完成，本規格只處理剩下的部分
- **相關規格**：`docs/features/2026-10-23-yelp-places-api-coverage.md`（PR #160，Summary DTO 新欄位）、`docs/features/2026-10-22-ui-8-7-static-map-placeholder.md`（同一個 Cell 的前一次改動）

---

## 1. 背景與問題

### 1.1 現況（實查）

- `YelpRestaurantDetailDto`（`lib/api/dto/yelp_restaurant_detail_dto.dart:10-21`）只有 11 個欄位：`name`、`imageUrl`、`isClosed`、`reviewCount`、`rating`、`phone`、`categories`、`location`、`coordinates`、`photos`、`hours`。Yelp Business Details 已經回傳的 `id`、`alias`、`price`、`url`、`display_phone`、`is_claimed`、`transactions` 都沒有解析。
- `RestaurantDetailEntity`（`lib/domain/entities/restaurant_detail_entity.dart:7-18`）的欄位和 DTO 一一對應，所以同樣沒有 `id`，詳情頁的實體無法識別自身。`fromDto`（`:34-53`）與 `toDto`（`:55-67`）也只對應這 11 欄。
- `RestaurantInfoCell`（`lib/features/component/cell/restaurant_detail/restaurant_info_cell.dart`）：
  - 電話列只讀 `phone`（`:123` 判斷是否顯示、`:126-128` 撥號、`:146` 顯示文字）。畫面上看到的是 `+886212345678` 這種原始格式。
  - 分類列（`:31-36`、`:157-168`）把 `categories` 的 title 過濾空字串後以 ` · ` 串接，`maxLines: 1`。
  - 外部連結只有導航 ActionSheet 裡的兩個 Google Maps 入口（`:233`、`:251`），沒有 Yelp 官方頁面的入口。
- `APIClz.fetchToken`（`lib/api/api_clz.dart:18-24`，`POST /oauth2/token`）是 Yelp 已廢除的 OAuth2 介面，產生碼在 `lib/api/api_clz.g.dart:26`。`lib/`、`test/` 中沒有任何呼叫點。
- **資料流**：列表、地圖或最愛把 `RestaurantEntity` 傳進詳情頁，詳情頁以 `FetchDetailInfo(id: _summaryInfo.id!)`（`restaurant_detail_page.dart:38`；切換最愛後在 `:119` 重新觸發一次）觸發 `RestaurantDetailRepo.fetchYelpRestaurantDetailInfo`（`restaurant_detail_repo.dart:18-26`），也就是 `APIClz.business(id, locale)` 加上 `RestaurantDetailEntity.fromDto`。本規格不改這條資料流。
- **既有的可重用元件**：
  - `Utils.openUrl(rawUrl: …)`（`lib/features/utils/utils.dart:15-24`）：`rawUrl` 非空時呼叫 `launchUrlString`。
  - `url_launcher` 已安裝（`pubspec.yaml:43`）。
  - 多語系使用 `intl_utils`：ARB 放在 `lib/l10n/intl_{en,zh_TW}.arb`，執行 `make intl` 產生 `lib/generated/`，產生的檔案有進 git。
- **Detail DTO／Entity 的消費端**：
  - `YelpRestaurantDetailDto.toJson` 與 `RestaurantDetailEntity.toDto` 在 `lib/` 都沒有呼叫點。`favor_data_source.dart:122` 寫進 Firestore 的是 `RestaurantEntity`，不是 Detail。所以 Detail 的 JSON 形狀沒有任何持久化或對外的契約。
  - 建構 `RestaurantDetailEntity` 的測試有 6 處，全部使用具名參數：
    - `test/component/restaurant_info_cell_test.dart`
    - `test/domain_entity_test.dart:50`
    - `test/empirical_m3_stress_test.dart:46`
    - `test/component/restaurant_detail/review_summary_card_test.dart`
    - `test/data_layer/review_summary_repo_test.dart`
    - `test/flow/restaurant/review_summary_bloc_test.dart`

### 1.2 為什麼是問題

使用者從列表點進詳情頁時，有三個問題：

- 電話以原始的 E.164 格式顯示（例如 `+886212345678`），不容易閱讀。
- 看不到價位。列表頁有顯示價位（`restaurant_item_cell.dart:109`），進入詳情頁後反而沒有。
- 沒辦法跳到 Yelp 官方頁面查看完整資訊，例如菜單、照片、訂位。

開發面的問題：Detail 實體沒有 `id`，之後的收藏比對或深層連結（A-9.4）都得回頭補欄位。另外，`fetchToken` 是一支會誤導讀者的死碼：讀 `APIClz` 的人會以為專案還在走 OAuth2。

### 1.3 【核心判斷】

**值得做。** 理由：

- 欄位資料 Yelp 已經回傳了，本次只是把它解析出來，不需要增加任何 API 呼叫。
- 改動集中在 1 個 DTO、1 個 Entity、1 個 Cell、1 支死碼。
- Detail 的 `toJson`／`toDto` 沒有外部契約（§1.1），新增欄位不會破壞任何持久化格式。

- **資料結構**：資料流向是 Yelp JSON → `YelpRestaurantDetailDto`（7 個新欄位全收）→ `RestaurantDetailEntity`（只帶 UI 與識別需要的 4 個：`id`、`price`、`url`、`displayPhone`）→ `RestaurantInfoCell`。沒有任何新增的複製或轉換層。
- **可消滅的複雜度**：
  - 價位不另開一列，而是成為分類列串接清單的第一個元素。既有的「過濾空字串」邏輯會順便處理 null 和空字串，不需要新增任何 `if`（D-1）。
  - `displayPhone` 只決定顯示文字，電話列是否顯示仍然只看 `phone`（D-3）。
- **最大破壞風險**：
  - 刪除 `fetchToken` 後重新產生 `api_clz.g.dart`，產生器版本漂移可能帶進無關的 diff。AC-1 鎖住這一點。
  - 資訊欄多一列，會改變 Cell 的高度。AC-15 鎖住不能出現 overflow。

---

## 2. 使用者故事

### 2.1 故事

1. 身為**使用者**，在詳情頁看到格式化過的電話（例如 `02 2345 6789`），點一下就能撥號。
2. 身為**使用者**，在詳情頁的分類旁看到價位（例如 `$$ · 咖啡廳`），不必退回列表才能判斷消費程度。
3. 身為**使用者**，在詳情頁點「在 Yelp 開啟」，跳到該餐廳的 Yelp 官方頁面查看完整資訊。
4. 身為**開發者**，`RestaurantDetailEntity` 帶有自己的 `id`，日後做收藏比對或深層連結時，不必再回頭補資料層。
5. 身為**維護者**，`APIClz` 只留下實際在用的端點，不會被已廢除的 OAuth2 介面誤導。

### 2.2 需求 brief 摘要（gen-grill 已放行）

- **Q1 問題**：
  - Detail DTO 與 Entity 都沒有 `id`。
  - `price`、`url`、`display_phone`、`is_claimed`、`transactions` 沒有解析。
  - `fetchToken` 是死碼。
- **Q2 場景**：使用者從列表進入詳情頁時，看到的電話是原始格式、看不到價位，也沒有 Yelp 官方頁面的入口。
- **Q3 成功標準**：
  - DTO 解析 7 個欄位。
  - Entity 帶 4 個欄位，`fromDto`／`toDto` 雙向對應。
  - Cell 顯示 `displayPhone` 與 `price`，撥號仍然用 `phone`，並提供「在 Yelp 開啟」。
  - 移除 `fetchToken`。
  - `flutter analyze` 零警告，既有與新增測試全過。
- **Q4 不做**：
  - 不顯示 `isClaimed`／`transactions`。
  - `id` 不接上收藏或深層連結（A-9.4）。
  - 詳情頁資料來源不變。
  - 不動 Summary DTO。
- **Q5 實查**：見 §1.1。

---

## 3. 規格細節

### 3.1 欄位

| JSON key | Dart 欄位 | 型別 | DTO | Entity | UI |
|----------|-----------|------|-----|--------|----|
| `id` | `id` | `String?` | 新增 | 新增 | 不顯示 |
| `alias` | `alias` | `String?` | 新增 | — | 不顯示 |
| `price` | `price` | `String?` | 新增 | 新增 | 分類列（U-2） |
| `url` | `url` | `String?` | 新增 | 新增 | 「在 Yelp 開啟」（U-3） |
| `display_phone` | `displayPhone` | `String?` | 新增 | 新增 | 電話列文字（U-1） |
| `is_claimed` | `isClaimed` | `bool?` | 新增 | — | 不顯示 |
| `transactions` | `transactions` | `List<String>?` | 新增 | — | 不顯示 |

**DTO 約定**（沿用 `yelp_restaurant_detail_dto.dart` 現有寫法，不另立風格）：

- 維持 `@JsonSerializable(fieldRename: FieldRename.snake)`。`display_phone`、`is_claimed` 會由產生碼自動對應。
- 新欄位一律 nullable。**server 沒給就是 `null`**，不設 `defaultValue`。
- 不加 `@JsonKey(includeIfNull: false)`。Summary DTO 加這個是為了保持 Firestore 最愛 payload 的形狀（`yelp_restaurant_summary_dto.dart:26`），Detail 的 `toJson` 沒有消費端，不需要。
- `fromJson`／`toJson` 只呼叫產生碼（flutter-styles §X.2）。

**Entity 約定**：

- 新增 4 個 `final String?` 欄位，並加入 `const` 建構式的具名參數。
- `fromDto` 從 DTO 讀這 4 欄；`toDto` 把這 4 欄寫回 DTO。
- `alias`、`isClaimed`、`transactions` 不進 Entity。所以 `toDto` 產生的 DTO 中，這 3 欄是 `null`。這個有損的往返是刻意的設計：`toDto` 沒有呼叫點（§1.1），Entity 只攜帶有消費端的欄位。

### 3.2 `RestaurantInfoCell` 行為

資訊欄由上到下的順序：地址 → 電話列 → **「在 Yelp 開啟」列（新）** → 分類列（**前面加上價位**）→ 評分 → 營業狀態。

**U-1 電話列**

| `phone` | `displayPhone` | 電話列 | 顯示文字 | 撥號 URI |
|---------|----------------|--------|----------|----------|
| 非空 | 非空 | 顯示 | `displayPhone` | `tel://<phone>` |
| 非空 | `null` 或 `''` | 顯示 | `phone`（回退） | `tel://<phone>` |
| `null` 或 `''` | 任意 | **不顯示**（與現在相同） | — | — |

- 電話列是否顯示，判斷條件與現在相同（`restaurant_info_cell.dart:123`），只看 `phone`。
- 撥號用 `phone` 不用 `displayPhone`，因為 `displayPhone` 含有空白和括號，例如 `(415) 749-2060`。
- 「`phone` 空、`displayPhone` 非空」時電話列不顯示：沒有可撥的號碼，就不放一個點了沒反應的列。Yelp 沒有電話的商家，兩個欄位都會回傳空字串，所以實務上它們會同時為空。

**U-2 價位**

- 分類列的內容改為：`[price, ...categories 的 title]`，過濾掉 null 和空字串後，以 ` · ` 串接。價位放在最前面，因為分類列只有 `maxLines: 1`，放前面不會被截斷。

| `price` | 分類 title | 分類列文字 |
|---------|-----------|-----------|
| `'$$'` | `['咖啡廳']` | `$$ · 咖啡廳` |
| `'$$'` | 無 | `$$` |
| `null` 或 `''` | `['咖啡廳']` | `咖啡廳`（與現在一字不差） |
| `null` 或 `''` | 無 | 分類列不顯示（與現在相同） |

- `price` 原樣顯示 Yelp 回傳的字串，不做轉換，也不走多語系。它本身就是符號，例如 `$`～`$$$$`，部分地區會是當地貨幣符號。

**U-3 在 Yelp 開啟**

> **2026-10-27 修訂（使用者於 STAGE 2 實作完成後要求）**：拿掉「在 Yelp 開啟」文字列，改為在店家名稱（詳情頁 AppBar 標題）之後接一個外開 icon。原「電話列之下獨立一列」的設計（D-2）作廢；`RestaurantInfoCell` 不再處理 `url`。

- 詳情頁 AppBar 標題抽成 `RestaurantDetailTitle(name:, url:)`（`lib/features/component/cell/restaurant_detail/restaurant_detail_title.dart`），頁面改用它。
- 版面：`Row(mainAxisSize: min)` = `Flexible(Text(name))` + `IconButton(Icons.open_in_new)`。店名過長時沿用 AppBar 預設的單行省略號，icon 不被擠出。店名文字樣式與現行相同（白色、`fontSize22`）。
- `url` 非空才顯示 icon；`null` 或 `''` 時只有店名，與修訂前的標題完全相同。
- icon 白色，`tooltip` 為 `S.current.open_in_yelp`（icon-only 按鈕的無障礙標籤，ARB key 因此保留）。
- 點擊時呼叫 `Utils.openUrl(rawUrl: url)`，沿用既有 helper，開啟方式與現在的 Google Maps 連結一致。
- 新增的 ARB key：

| key | `intl_zh_TW.arb` | `intl_en.arb` |
|-----|------------------|---------------|
| `open_in_yelp` | `在 Yelp 開啟` | `Open in Yelp` |

**不顯示**：`id`、`alias`、`isClaimed`、`transactions`。

### 3.3 刪除 `fetchToken`

- 刪除 `api_clz.dart:18-24` 的宣告，執行 `make gen` 重新產生 `api_clz.g.dart`。
- 其他 15 支方法的簽章都不變。

---

## 4. 驗收條件

### 4.1 可機械驗證（必須全數通過）

```bash
make gen          # dart run build_runner build --delete-conflicting-outputs（Makefile:58-59）
make intl         # dart run intl_utils:generate（Makefile:75-76）
flutter analyze
flutter test
rtk proxy grep -rn -E "fetchToken|oauth2/token" lib test
git diff main --stat -- pubspec.yaml pubspec.lock
```

- **AC-1** `make gen` 成功，以下 3 個產生檔的 diff 範圍限定如下，並一起 commit：
  - `lib/api/api_clz.g.dart`：只刪除 `fetchToken` 的實作。
  - `lib/api/dto/yelp_restaurant_detail_dto.g.dart`：只新增 7 個欄位的讀寫。
  - 其他 `.g.dart` 不應該出現 diff。若因為產生器版本差異而出現無關的 diff，要先排除再 commit。
- **AC-2** `make intl` 成功。兩個 ARB 都新增 `open_in_yelp`，`lib/generated/`（`l10n.dart`、`intl/messages_{en,zh_TW}.dart`）的更新一起 commit。
- **AC-3** `flutter analyze` 輸出 `No issues found!`。
- **AC-4** `flutter test` 全綠。**不得**靠修改既有測試的期望值來達成。以下兩個既有斷言必須原樣通過，它們同時是 U-1 回退與 U-2 null 情境的回歸測試：
  - `test/component/restaurant_info_cell_test.dart:36` 的 `find.text('+886212345678')`：只有 `phone`，沒有 `displayPhone`。
  - 同檔 `:37` 的 `find.text('咖啡廳')`：沒有 `price`。
- **AC-5** 第 5 條指令沒有輸出（`fetchToken` 已從 `lib/` 和 `test/` 完全消失）。
- **AC-6** 第 6 條指令沒有輸出（不新增相依）。

### 4.2 DTO（新檔 `test/api/dto/yelp_restaurant_detail_dto_test.dart`，測資放在同檔的 `_Data`，比照 `yelp_restaurant_summary_dto_test.dart`）

- **AC-7** **完整測資**：JSON 包含 §3.1 的 7 個新 key 和至少 1 個既有欄位（例如 `name`）。`fromJson` 之後逐欄斷言：
  - `transactions` 等於 `['pickup', 'delivery']`。
  - `isClaimed` 為 `true`。
  - `displayPhone` 是 `display_phone` 的值。
  - 既有欄位不受影響。
- **AC-8** **缺欄位**：`fromJson(const {'name': 'x'})` 之後，7 個新欄位全部是 `null`，不得出現預設值。

### 4.3 Entity（新增 test 到 `test/domain_entity_test.dart` 的既有 group，不改既有 test 的本體）

- **AC-9** `fromDto`：DTO 帶入 `id`、`price`、`url`、`displayPhone` 後，Entity 的同名欄位都相等。
- **AC-10** `toDto`：AC-9 的 Entity 執行 `toDto` 後，這 4 欄都相等。`alias`、`isClaimed`、`transactions` 為 `null`，這是 §3.1 的刻意設計，要在測試中明確斷言。
- **AC-11** 空 DTO：`RestaurantDetailEntity.fromDto(YelpRestaurantDetailDto())` 的 4 個新欄位都是 `null`。

### 4.4 UI（新增 testWidgets 到 `test/component/restaurant_info_cell_test.dart`）

- **AC-12** U-1：
  - `displayPhone` 非空時，畫面上找得到 `displayPhone` 的文字，找不到 `phone` 的文字。
  - `displayPhone` 為 `''` 時，顯示 `phone`。`null` 的情境由既有測試涵蓋，見 AC-4。
- **AC-13** U-2：§3.2 價位表的前兩列都要有對應的斷言：`$$ · 咖啡廳`、`$$`。`price: ''` 搭配 `['咖啡廳']` 時，顯示 `咖啡廳`。
- **AC-14** U-3（2026-10-27 修訂）：測試對象為 `RestaurantDetailTitle`。
  - `url` 非空時，店名文字 `findsOneWidget`，`find.byIcon(Icons.open_in_new)` 與 `find.byTooltip(S.current.open_in_yelp)` 皆為 `findsOneWidget`。
  - `url` 為 `null` 或 `''` 時，店名文字 `findsOneWidget`，`find.byIcon(Icons.open_in_new)` 為 `findsNothing`。
  - `RestaurantInfoCell` 在 `url` 非空時，畫面上沒有 `S.current.open_in_yelp` 文字，也沒有 `Icons.open_in_new`。
- **AC-15** 版面：所有新欄位都有值，並且分類多到觸發省略號時，`pumpWidget` 之後 `tester.takeException()` 為 `null`，也就是沒有 RenderFlex overflow。測試畫面使用預設的測試尺寸。
- **AC-16** widget test **不點擊**電話列和 Yelp 列。理由見 R-1。

### 4.5 人工驗收

- **AC-17** 在 iOS 或 Android 其中一個平台上完成：
  - 點電話列，撥號畫面帶入的是 `phone` 的號碼。
  - 點「在 Yelp 開啟」，開啟的是該餐廳的 Yelp 頁面。
- **AC-18** Code review 時確認：撥號 URI 由 `phone` 組成，不是 `displayPhone`；Yelp 連結走 `Utils.openUrl(rawUrl:)`，沒有新增其他的 launch 路徑。

---

## 5. 範圍邊界

### 5.1 In Scope

- `YelpRestaurantDetailDto` 新增 7 個欄位，重新產生 `.g.dart`。
- `RestaurantDetailEntity` 新增 4 個欄位，更新 `fromDto`／`toDto`。
- `RestaurantInfoCell` 實作 U-1～U-3。
- 新增 ARB key `open_in_yelp`，重新產生 `lib/generated/`。
- 刪除 `APIClz.fetchToken`，重新產生 `api_clz.g.dart`。
- §4 列出的新增測試。
- 文件同步：把 brainstorm §8.3.1 [A-8.8] 的狀態改成完成，沿用 PR #160 的慣例（commit `f9d1c5e`）。

### 5.2 Out of Scope

- **不顯示**：`isClaimed`、`transactions`、`alias`、`id`。前兩者只在 DTO 解析，不進 Entity。
- **`id` 的用途**：不接收藏、深層連結或比對（A-9.4）。這次只讓 Entity 帶有 `id`。
- **資料流**：詳情頁仍然由傳入的 `RestaurantEntity.id` 觸發 `business(id)`，不改 BLoC、Repository。頁面只改 AppBar 標題（改用 `RestaurantDetailTitle`，見 U-3 修訂）。
- **Summary DTO**：不動，PR #160 已經完成。
- **Detail DTO 的型別風格**：不把它改成 `final` + `Equatable`。理由見 D-4。
- **AI 評論摘要**：`ReviewSummaryRepo.formatPrompt`（`review_summary_repo.dart:78-101`）不加入價位或電話。
- **其他畫面**：`RestaurantItemCell` 的價位顯示（`restaurant_item_cell.dart:109`）和 `RestaurantHeadCell` 不動。
- **共用 helper**：不改 `Utils.openUrl` 和 launch mode，不新增 scheme 白名單（見 R-2）。
- **歷史文件**：`docs/architecture/2026-08-06-architecture_comparison_report.md` 雖然提到 `fetchToken`，但它是當時的快照，不回頭修改。

---

## 6. 風險

| # | 風險 | 影響 | 緩解 |
|---|------|------|------|
| R-1 | 點擊行為無法用 widget test 驗證：`Utils.openUrl` 內部是 unawaited 的 `launchUrlString`，測試環境沒有 url_launcher 的 platform 實作，點擊會產生 uncaught 的非同步錯誤。要替換 `UrlLauncherPlatform`，就得新增 `url_launcher_platform_interface` 作為 dev 相依，違反 AC-6 | 撥號目標、Yelp 連結目標沒有自動化測試 | 交給 AC-17 的人工驗收和 AC-18 的 code review。顯示與隱藏的邏輯由 AC-12～AC-14 自動化測試 |
| R-2 | `url` 是 Yelp 回傳的外部字串，沒有檢查 scheme 就交給 `launchUrlString` | 理論上可能開啟非預期的 URL | 這個值和已經直接載入的 `image_url`、`photos` 來自同一個已認證的 Yelp 回應，屬於既有的信任範圍；開啟動作也是交給 OS 處理。接受這個風險，不做白名單 |
| R-3 | `make gen` 因為產生器版本漂移，在無關的 `.g.dart` 產生 diff | review 雜訊，甚至夾帶非預期的行為改動 | AC-1 限定 diff 範圍 |
| R-4 | 資訊欄多一列 Yelp 連結，文字欄的高度可能超過左側 140 高的地圖 | 版面變高。`Row` 外層是 `ListView`，所以不會 overflow | AC-15 鎖住 overflow |
| R-5 | 價位放在分類列前面，分類太多時，尾端的分類會更早被省略號截掉 | 少看到一兩個分類 | 接受。價位比尾端的分類更有資訊量 |

---

## 7. 設計決策（trade-off）

### D-1 價位放在哪裡

| 選項 | 內容 | 評估 |
|------|------|------|
| **(a) 併入分類列，放在最前面（採用）** | `[price, ...titles]` 過濾空字串後以 ` · ` 串接 | 不新增 widget，也不新增 `if`。null 和空字串由既有的過濾邏輯處理。價位沒有值時，畫面和現在完全相同，既有測試不用改。Yelp 官方 App 也是 `$$ · 分類` 的呈現方式 |
| (b) 獨立一列 `Text` | 分類列下面另外一列 | 多一個 `if (price 非空)` 的特殊情況，也多一列高度 |
| (c) 放在 `RestaurantHeadCell`，用 `summaryInfo.price` | 不需要 Detail 欄位 | 違背 Q3「`RestaurantInfoCell` 顯示 `price`」，也讓 Detail 的 `price` 欄位變成沒有消費端 |

### D-2 Yelp 連結的入口

| 選項 | 內容 | 評估 |
|------|------|------|
| **(a) 資訊欄獨立的可點擊列，放在電話列下面（採用）** | 樣式和電話列相同 | 容易發現；與電話列都屬於「聯絡或外連」，放在一起。只多一個 `if (url 非空)`，這是真正的業務條件：沒有連結就沒有入口 |
| (b) 在既有的導航 ActionSheet 加第三個選項 | 不新增列 | ActionSheet 的標題是「請選擇導覽方式」（`navigation_choice`），放 Yelp 頁面語意不符；而且要先點地圖才看得到，可發現性差 |
| (c) AppBar action | 位置顯眼 | 要改 `restaurant_detail_page.dart`，並把 `url` 從 state 往上傳，範圍擴大 |

### D-3 `displayPhone` 的回退寫在哪裡

| 選項 | 內容 | 評估 |
|------|------|------|
| **(a) Cell 內就地決定顯示文字（採用）** | 顯示文字 = `displayPhone` 非空時用它，否則用 `phone` | 只有一個呼叫點，改動最小 |
| (b) Entity 新增 getter（例如 `phoneLabel`） | 可以重用 | 只有一個呼叫點，多一個 API 介面，屬於 YAGNI |
| (c) `fromDto` 時把空的 `displayPhone` 填成 `phone` | Cell 不用判斷 | 扭曲資料：Entity 的 `displayPhone` 不再等於 Yelp 回傳的值，`toDto` 也不再對稱 |

### D-4 Detail DTO 要不要順便改成 `final` + `Equatable`

flutter-styles §X.2 要求 DTO 使用 `Equatable`，但現在的 Detail DTO 是可變欄位，也沒有 `Equatable`。**本次不改**，理由：

- 新增欄位不需要改。
- 依 `2026-10-23-yelp-places-api-coverage.md` §3.0 的限制，Equatable DTO 不能內嵌沒有值相等性的 DTO，所以要連帶把 `YelpRestaurantCoordinatesDto`、`YelpRestaurantHoursDto`（以及 hours 內嵌的 open DTO）都改成 Equatable，範圍會擴散到 3 個以上的檔案。
- 目前沒有任何地方比較兩個 Detail DTO 是否相等。

如果之後要統一，應該另開一個項目，一次處理所有既有的 Yelp DTO。

---

## 8. 執行方式（交 STAGE 0b 選擇）

- **Subagent-driven（建議）**：同一個 session，依任務逐一派 subagent，每個任務完成後 review。任務之間有依賴：DTO → Entity → Cell。`fetchToken` 的刪除和 ARB key 的新增可以和 DTO 平行進行。
- **Parallel session**：另開 session，以 `executing-plans` 批次執行。適合想把 review 集中在最後一次做的情況。
