# 功能規格：補齊 Yelp Places API 12 支端點（API 層＋Repository 層）

- **日期**：2026-10-23
- **狀態**：草稿（STAGE 0a）。§7 的待決事項交由 STAGE 0b 決定
- **實查基線**：`main` @ `ecd648d`
- **需求來源**：gen-grill brief Q1–Q5，已放行（摘要見 §2.2）
- **規格來源**：官方 OpenAPI 摘錄 `/Users/yomiry/.claude/jobs/3d869a41/tmp/yelp-places-spec.json.txt`。這是暫存檔，不在 repo 內，所以 §3 已把本次需要的參數與回應欄位**全部抄進本文件**，0b 以本文件為準。下文的 `spec:NNN` 指這個摘錄檔的行號
- **相關 brainstorm 項目**（`docs/brainstorm/2026-10-22-features-brainstorm.md`）：
  - 本次只做 A-8.9、A-8.12 的 API 與 Repository 部分
  - 明確排除 A-8.7、A-8.8、A-8.10
  - 錯誤處理依賴 A-8.1、A-8.3
  - 分層依據 A-8.2、A-8.4
  - 與 A-8.13 無重疊

  逐項關係見 §5.3

---

## 1. 背景與問題

### 1.1 現況（實查）

- `APIClz` 只宣告 4 支方法：
  - `fetchToken`（`api_clz.dart:18`，`POST /oauth2/token`，官方已廢除，A-8.8 排定刪除）
  - `businessesSearch`（`:26`，`GET /v3/businesses/search`）
  - `business`（`:39`，`GET /v3/businesses/{id}`）
  - `review`（`:45`，`GET /v3/businesses/{id}/reviews`）
- 本規格的 12 支端點目前**全部沒有實作**：`api_clz.dart` 沒有對應宣告，`lib/api/dto/` 也沒有對應 DTO（`dto_barrel.dart:1-12` 只有 search、detail、review 系列）。
- 既有 Yelp Repository 有兩支，都是依畫面切分，也都直接呼叫 `GetIt.I<APIClz>()`：
  - `MainRepo`（`main_repo.dart:52`）
  - `RestaurantDetailRepo`（`restaurant_detail_repo.dart:21,30`）

  它們回傳 Entity（`RestaurantEntity.fromDto` 等），locale 一律在 Repository 內部帶入 `Constants.locale`（`constants.dart:39`，`'zh_TW'`）。
- 既有 Yelp DTO **都沒有使用 `Equatable`**：
  - 欄位是可變的（例如 `yelp_search_dto.dart:8-9`）。
  - `YelpRestaurantSummaryDto` 自行覆寫 `==`，只比較 `id`（`yelp_restaurant_summary_dto.dart:47-55`），而且 `test/empirical_m3_stress_test.dart:176-183` 鎖住了這個行為。
  - `Equatable` + `@JsonSerializable` 的寫法只出現在 domain entity，例如 `review_summary_entity.dart:10-42`、`allergen_info.dart:41-62`。

### 1.2 為什麼是問題

後續每做一個依賴其他 Yelp 端點的功能（A-8.9 搜尋補全、A-8.12 分類樹，以及未來的活動、店家比對等），都得從 API 宣告、DTO、Repository 一路補起，API 層的工作量會和功能本身綁在一起。這次一次把 Places API 的 12 支端點補到 Repository 層，之後的功能工作只需要處理 BLoC 和 UI。

### 1.3 【核心判斷】

**值得做。** 三個理由：

- 這是使用者明確要求的。
- 改動以新增為主，正式版沒有任何呼叫點會走到新程式，執行期零影響。
- 唯一動到既有程式的地方是 DI 註冊，以及 D-4 選項 (a) 對 `YelpSearchDto` 的調整。

**需要直說的 YAGNI 疑慮**：12 支裡只有 autocomplete（A-8.9）與 categories（A-8.12）在 brainstorm 有規劃中的消費端，其餘 10 支目前沒有使用者。`service_offerings` 已經被官方標為 deprecated，engagement、review_highlights 在現行 API Key 下大概只會拿到 403。這是使用者知情後的選擇，本規格照做，但在 §6 列為風險。

- **資料結構**：12 支端點的回應實際上只有 4 種主資源：Business、Event、Category、Autocomplete 建議，再加上 engagement、service_offerings、review_highlights 這 3 種小型結構。其中 Business 與既有 search 回應**是同一個資源**（spec:45-201 與 spec:603-759 的欄位完全相同），不應該再建一套平行型別。
- **可消滅的複雜度**：
  - 不為 DTO 再鏡像一層 Entity（D-3）。
  - locale 在 Repository 內部固定帶入，不對外暴露。
  - 參數範圍不在 client 端驗證，交給 Yelp 回 400。
- **最大破壞風險**：改動 `YelpSearchDto`（D-4 選項 (a)），以及在 `injection.dart` 新增註冊。兩者都由既有測試加上 `di_test.dart` 鎖住。

---

## 2. 使用者故事

### 2.1 故事

1. 身為**開發者**，在做依賴 Yelp 其他端點的功能（例如搜尋補全、分類篩選、活動列表）時，我希望直接從 Repository 取得**型別化資料**，不必先補 Retrofit 宣告、DTO 和 DI。
2. 身為**開發者**，我希望 Repository 的介面清楚標示哪些端點需要特別權限，以及沒有權限時會發生什麼（403 會怎麼呈現），這樣在接 UI 前就知道要不要做降級。
3. 身為**維護者**，我希望新程式遵守 `.claude/rules/flutter-styles.md` §X.2：DTO 使用 `@JsonSerializable` 加 `Equatable`，`fromJson`／`toJson` 只用產生碼。我也希望每支端點都有解析測試和 Repository 測試，日後 Yelp 改 schema 時，由測試先發現。

### 2.2 需求 brief 摘要（gen-grill 已放行）

- **Q1 問題**：`APIClz` 只接了 search、business details、reviews 3 支 Places 端點。
- **Q2 場景**：開發者能直接從 Repository 取得型別化資料。
- **Q3 成功標準**：
  - `APIClz` 新增 12 支 Retrofit 方法，路徑與參數符合官方 reference。
  - 每支回應都有 `@JsonSerializable` + `Equatable` 的 DTO，放在 `lib/api/dto/`。
  - 各端點接上 `lib/domain/repositories/` 的介面與 `lib/data_layer/repositories/` 的實作。
  - build_runner 正常、`flutter analyze` 零警告、既有測試全過。
  - 新增 DTO 解析測試與 Repository 測試（mocktail）。
- **Q4 不做**：
  - BLoC、UI。
  - 修正既有端點：A-8.7／A-8.10 的 search 參數、A-8.8 的 Detail 欄位與刪除 `fetchToken`。
  - API Key 權限：只標註，不處理。
- **Q5 實查**：見 §1.1。

---

## 3. 範圍內端點

### 3.0 共通約定（12 支都適用）

| 項目 | 約定 | 依據 |
|------|------|------|
| Base URL／鑑權 | 沿用 `@RestApi(baseUrl: Constants.baseUrl)` 與既有 `dioClient` 的 `Authorization` interceptor，不另建 client | `api_clz.dart:14,52-77` |
| `locale` | 支援 `locale` 的端點，由 Repository 一律帶入 `Constants.locale`，不放進 Repository 方法簽章 | `restaurant_detail_repo.dart:21-24` 現行作法 |
| 必填參數 | Retrofit 方法簽章的必填參數一律 non-nullable。產生碼會用 `queryParameters.removeWhere((k, v) => v == null)` 丟掉 null，nullable 的必填參數會被靜默省略 | `api_clz.g.dart:90,118,146` |
| Path 參數 | non-nullable。既有 `@Path() String? id`（`api_clz.dart:41`）傳入 null 時會組出 `/null`，新方法不沿用這個寫法 | — |
| 陣列 query 參數 | 序列化格式見 D-5 | `dio options.dart:728` 預設 `ListFormat.multi` |
| 參數範圍 | client 端**不驗證** `maxLength`、`maximum`、`pattern`，違反時由 Yelp 回 400 | YAGNI |
| DTO | `@JsonSerializable(fieldRename: FieldRename.snake)`，有巢狀物件時加 `explicitToJson: true`。欄位全部 nullable，**server 沒給就是 `null`**，不使用 `defaultValue`。欄位為 `final`，類別 `extends Equatable` | flutter-styles §X.2；`yelp_restaurant_summary_dto.dart:8-11`；`docs/features/2026-09-24-domain-entity-json-serializable.md` §3.2 |
| 巢狀 DTO 的相等性 | **新的 Equatable DTO 不可以內嵌沒有值相等性的既有 DTO**。`YelpRestaurantCategoryDto`、`YelpRestaurantLocationDto` 沒有覆寫 `==`，`Equatable` 比到它們時會退化成 identity 比較，兩次 `fromJson` 的結果永遠不相等。（STAGE 0b 依使用者「不建立重複 DTO」的裁決，改由 T1 把這兩個 DTO 改成 Equatable 後直接重用，此限制對它們已解除） | `equatable.dart:54` 以 `iterableEquals(props, …)` 逐項比較 |

### 3.1 總表

| # | Method | Path | 用途 | 必填參數 | 回應頂層 | 存取限制 | brainstorm |
|---|--------|------|------|----------|----------|----------|------------|
| 1 | GET | `/v3/businesses/search/phone` | 以電話號碼（須含國碼）查找商家，回傳符合的商家清單 | `phone` | `{businesses: Business[], total}` | — | — |
| 2 | GET | `/v3/businesses/matches` | 以名稱＋地址精確比對 Yelp 上的商家，用於把外部資料（自家資料庫、其他平台）對應到 Yelp 商家 ID | `name`, `address1`, `city`, `state`, `country` | `{businesses: BusinessMatch[]}` | — | — |
| 3 | GET | `/v3/transactions/{transaction_type}/search` | 搜尋支援外送（`delivery`）的商家；官方註明不回傳沒有任何評論的商家 | path `transaction_type`；`location` 或 `latitude`+`longitude` 擇一 | `{businesses: Business[], total}` | — | — |
| 4 | GET | `/v3/businesses/engagement` | 查詢商家每週的消費者互動指標（engagement／intent／transaction 分數），屬 Yelp Insights | `business_ids` | `{data: Engagement[]}` | **需特別權限（Yelp Insights），未開通回 403** | — |
| 5 | GET | `/v3/businesses/{business_id_or_alias}/service_offerings` | 查詢商家目前啟用（`active`）與有資格提供（`eligible`）的服務項目；官方已改由 Business Details 的 Jobs offered 取代，**僅供參照** | path | `{active, eligible}` | **官方標 deprecated，且需特別權限** | — |
| 6 | GET | `/v3/businesses/{business_id_or_alias}/review_highlights` | 取得評論精選句：被多則評論提到的重點字句，附相關照片與提及的評論數 | path | `{review_highlights: Highlight[]}` | **需 Premium Plan** | — |
| 7 | GET | `/v3/events` | 依地點、時間區間、分類等條件搜尋 Yelp 上的活動 | 無（`location` 或經緯度屬條件式） | `{events: Event[], total}` | — | — |
| 8 | GET | `/v3/events/{event_id}` | 取得單一活動的詳細資訊 | path | `Event` | — | — |
| 9 | GET | `/v3/events/featured` | 取得某地區的精選活動（單一一筆） | `location` 或 `latitude`+`longitude` 擇一 | `Event` | — | — |
| 10 | GET | `/v3/categories` | 取得 Yelp 全部商家分類清單，可用來做菜系篩選；帶 `locale` 時只回該地區可用的分類並翻譯標題 | 無 | `{categories: Category[]}` | — | A-8.12 |
| 11 | GET | `/v3/categories/{alias}` | 以分類別名取得單一分類的詳情（標題、上層分類、適用國家） | path | `{category: Category}` | — | A-8.12 |
| 12 | GET | `/v3/autocomplete` | 使用者輸入文字時回傳補全建議，含關鍵字、商家、分類三類 | `text` | `{categories, businesses, terms}` | — | A-8.9 |

**用途說明的來源**：依官方 reference 的端點說明與 §3.3 的回應欄位整理。其中 #5 的「改由 Jobs offered 取代」與 #3 的「不回傳無評論商家」取自官方 reference 頁的說明文字；#5 官方未說明服務項目的具體值。

**存取限制的資料來源**：#4–#6 的限制來自需求 brief，由使用者提供。spec 摘錄本身**沒有** deprecated 旗標，也沒有權限或 403 說明，以 `deprecat|403|premium|insights|permission` 搜尋只命中 spec:198,756 的 `attributes` 欄位描述。標「—」的端點，brief 與 spec 摘錄都沒有提到限制。本規格不處理權限開通（Q4）。

### 3.2 共用物件定義

**Business**：#1、#3 共用。spec:45-201 與 spec:603-759 的欄位完全相同。

| 欄位 | 型別 | 必有 | 既有 `YelpRestaurantSummaryDto` 是否有 |
|------|------|------|----------------------------------------|
| `id` | string | 是 | 有 |
| `alias` | string | 是 | **無** |
| `name` | string | 是 | 有 |
| `image_url` | string | | 有 |
| `is_closed` | boolean | | **無** |
| `url` | string | | **無** |
| `review_count` | integer | | 有 |
| `categories` | 見 §6 R-3，spec 字面是 array of array of `{alias, title}` | | 有（`List<YelpRestaurantCategoryDto>`） |
| `rating` | decimal | | 有 |
| `coordinates` | `{latitude, longitude}`，兩者皆 decimal 且必有 | 是 | 有 |
| `transactions` | string[]（`pickup`／`delivery`／`restaurant_reservation`） | | **無** |
| `price` | string | | 有 |
| `location` | `{address1, address2, address3, city, zip_code, country, state, display_address: string[]（必有）, cross_streets?}` | 是 | 有，但缺 `zip_code`、`cross_streets` |
| `phone` | string | 是 | 有 |
| `display_phone` | string | 是 | **無** |
| `distance` | decimal（公尺） | | 有 |
| `attributes` | object（自由結構，含 Premium tier 屬性，spec:198） | | **無** |

覆蓋率：17 個欄位中有 11 個；缺 `alias`、`is_closed`、`url`、`transactions`、`display_phone`、`attributes`。其中 `is_closed`、`url`、`display_phone` 已排在 A-8.8 補進 Summary DTO（brainstorm:1648）。

**BusinessMatch**：#2 使用，spec:390-486。只有 `id`（必有）、`alias`（必有）、`name`、`coordinates`（必有）、`location`（必有）、`phone`（必有）、`display_phone`（必有）。它是 Business 的子集。

**Event**：#7、#8、#9 共用。spec:1192-1338、1386-1532、1597-1743 三處欄位相同。

| 欄位 | 型別 | 備註 |
|------|------|------|
| `id` | string | 必有 |
| `time_start` | string（ISO 8601） | 必有 |
| `name`, `description`, `business_id`, `category`, `event_site_url`, `image_url`, `tickets_url`, `time_end` | string，nullable | |
| `cost`, `cost_max` | number，nullable | |
| `attending_count`, `interested_count` | integer | |
| `is_canceled`, `is_free`, `is_official` | boolean | |
| `latitude`, `longitude` | number（float），nullable | |
| `location` | object，nullable：`{address1, address2, address3, city, state, zip_code, country, display_address: string[], cross_streets}`，全部 nullable | 結構近似 Business 的 `location`，但所有欄位都是 nullable，且必須是 Equatable（見 §3.0 最後一列） |

**Category**：#10、#11 使用，spec:1779-1813、1859-1893。欄位為 `alias`（必有）、`title`（必有）、`parent_aliases: string[]`、`country_whitelist: string[]`、`country_blacklist: string[]`。#12 的 `categories` 只有 `{alias, title}`（spec:1968-1980），是它的子集。

### 3.3 各端點

標示「opt」的是選填，其餘都是必填。`locale` 的格式一律是 `^[a-z]{2,3}_[A-Z]{2}$`。

**#1 `GET /v3/businesses/search/phone`**（spec:1-213）
- **參數**：
  - `phone`：string，1–32 字元，pattern `^[0-9 +()-.x/]+$`，須以 `+` 開頭並含國碼。
  - `locale`：opt。
- **回應**：`{businesses: Business[]（必有）, total: integer（必有）}`。

**#2 `GET /v3/businesses/matches`**（spec:214-494）
- **參數**：
  - `name`：≤64。
  - `address1`：≤64。**允許空字串**（spec:231），用來比對沒有街道地址的服務型商家。所以不可以用 null 代替空字串，見 §3.0「必填參數」。
  - `address2`、`address3`：opt，≤64。
  - `city`：1–64。
  - `state`：1–3，ISO 3166-2。
  - `country`：恰好 2 字元，`[A-Z]{2}`。
  - `postal_code`：opt，≤12。
  - `latitude`：opt，-90..90。
  - `longitude`：opt，-180..180。
  - `phone`：opt，1–32。
  - `yelp_business_id`：opt，恰好 22 字元。
  - `limit`：opt，integer 1–10，預設 3。
  - `match_threshold`：opt，enum `none|default|strict`，預設 `default`。
- **回應**：`{businesses: BusinessMatch[]（必有）}`。**沒有 `total`**。
- **註**：`latitude`／`longitude` 的描述寫著「Required if location is not provided」，但這支端點沒有 `location` 參數，應該是文件複製貼上造成的。本規格視兩者為選填。

**#3 `GET /v3/transactions/{transaction_type}/search`**（spec:495-771）
- **參數**：
  - `transaction_type`：path，enum 只有 `delivery`，預設 `delivery`。
  - `latitude`、`longitude`、`location`（1–250）：`location` 與經緯度擇一。
  - `term`：opt，≤300。
  - `categories`：opt，string[]，不可重複。spec 說明為逗號分隔，例如 `"bars,french"`（spec:558）。
  - `price`：opt，integer[]，每個值 1–4，最多 4 個，不可重複。spec 說明為逗號分隔，例如 `"1, 2, 3"`（spec:574）。
- **回應**：`{businesses: Business[]（必有）, total: integer（必有）}`。
- **建議**：`APIClz` 保留 path 參數，以符合官方 reference。Repository 固定帶入 `delivery`，不對外暴露，因為只有一個合法值的參數沒有實際的選擇空間。

**#4 `GET /v3/businesses/engagement`**（spec:772-870）［需特別權限，未開通回 403］
- **參數**：
  - `business_ids`：string[]，最多 20 個。
  - `date_range_start`、`date_range_end`：opt，date 字串。
- **回應**：`{data: [{business_id: string, metrics: [{start_of_week_date: "YYYY-MM-DD"（必有）, engagement_metric: int（1–20）, intent_metric: int（1–10）, transaction_metric: int（1–4）}]}]}`。其中 `data`、`business_id`、`metrics` 必有。

**#5 `GET /v3/businesses/{business_id_or_alias}/service_offerings`**（spec:871-926）［deprecated，且需特別權限］
- **參數**：
  - `business_id_or_alias`：path，22 字元 ID 或 alias。
  - `locale`：opt。
- **回應**：`{active: string[]（必有）, eligible: string[]（必有）}`。

**#6 `GET /v3/businesses/{business_id_or_alias}/review_highlights`**（spec:927-1003）［需 Premium Plan］
- **參數**：
  - `business_id_or_alias`：path。
  - `count`：opt，integer，預設 3，最多回 5 筆。
  - `locale`：opt。
- **回應**：`{review_highlights: [{photo: string, sentence: string, review_count: integer}]}`，全部欄位必有。`sentence` 用 `[[HIGHLIGHT]]…[[ENDHIGHLIGHT]]` 標出重點字，DTO 只保存原字串，不解析這個標記。

**#7 `GET /v3/events`**（spec:1004-1350）
- **參數**（全部 opt）：
  - `locale`。
  - `offset`：0–1000。
  - `limit`：0–50，預設 3。
  - `sort_by`：`asc|desc`，預設 `desc`。
  - `sort_on`：`popularity|time_start`，預設 `popularity`。
  - `start_date`、`end_date`：Unix timestamp，integer。
  - `categories`：string[]，不可重複。
  - `is_free`：boolean。
  - `excluded_events`：string[]。
  - `location`：1–250。
  - `latitude`、`longitude`。
  - `radius`：integer 0–40000。
- **回應**：`{events: Event[]（必有）, total: integer（必有）}`。

**#8 `GET /v3/events/{event_id}`**（spec:1351-1537）
- **參數**：`event_id`（path）、`locale`（opt）。
- **回應**：`Event`。

**#9 `GET /v3/events/featured`**（spec:1538-1748）
- **參數**：`location`（1–250），或 `latitude`+`longitude`，擇一；`locale`（opt）。
- **回應**：單一 `Event`。

**#10 `GET /v3/categories`**（spec:1749-1822）
- **參數**：`locale`（opt）。帶入時，只回傳該 locale 可用的分類，並翻譯標題。
- **回應**：`{categories: Category[]（必有）}`。

**#11 `GET /v3/categories/{alias}`**（spec:1823-1901）
- **參數**：`alias`（path）、`locale`（opt）。
- **回應**：`{category: Category（必有）}`。

**#12 `GET /v3/autocomplete`**（spec:1902-2025）
- **參數**：
  - `text`：minLength 1。
  - `locale`：opt。
  - `latitude`、`longitude`：opt。這支端點沒有 `location` 參數，描述中的「Required if location is not provided」和 #2 一樣是文件誤植。
- **回應**：`{categories: [{alias, title}]（必有）, businesses: [{id, name}]（必有）, terms: [{text}]（必有）}`。

---

## 4. 驗收條件

### 4.1 可機械驗證（必須全數通過）

```bash
make gen          # = dart run build_runner build --delete-conflicting-outputs（Makefile:58-59）
flutter analyze
flutter test
git diff main -- lib/api/api_clz.dart | rtk proxy grep '^-[^-]'
```

- **AC-1** `make gen` 成功，新產生與更新的 `*.g.dart` 一起 commit（沿用現行慣例）。
- **AC-2** `flutter analyze` 輸出 `No issues found!`。新 DTO 如果有非 `final` 欄位，會觸發 `must_be_immutable`（`Equatable` 帶 `@immutable`，見 `equatable.dart:25`），所以這一條同時檢查 DTO 是否不可變。
- **AC-3** `flutter test` 全綠。**不得**靠修改既有測試的期望值來達成。特別是 `test/empirical_m3_stress_test.dart:176-183`（Summary DTO 以 id 判斷相等）、`test/di_test.dart`、`test/repository_test.dart` 必須原樣通過。
- **AC-4** 第 4 條指令的輸出為空：`api_clz.dart` 只新增、不刪除也不修改既有行，既有 4 支方法的簽章不變。

### 4.2 API 層

- **AC-5** `APIClz` 新增 12 支方法，每一支的 HTTP method、path、query key、path 參數名稱都與 §3 一致。驗證方式：用一個替身 `HttpClientAdapter` 擷取 `RequestOptions`，以 `APIClz(dio)` 逐一呼叫 12 支方法，斷言 `method`、`path`、`queryParameters` 的 key 集合。陣列參數另外斷言 D-5 選定的格式。
- **AC-6** 必填參數（§3.3 沒有標 opt 的）在 Retrofit 簽章中是 non-nullable。#2 的 `address1` 傳入 `''` 時，AC-5 的擷取結果仍然要帶有 `address1=`。

### 4.3 DTO

- **AC-7** 每個新的 DTO 類別都符合以下條件：
  - 有 `@JsonSerializable`，並且 `extends Equatable`。
  - 欄位為 `final` 且 nullable。
  - `props` 列出所有欄位。
  - `fromJson`／`toJson` 的本體**只呼叫** `_$XxxFromJson`／`_$XxxToJson`，不手寫 map。
  - 檔案放在 `lib/api/dto/`，並從 `dto_barrel.dart` 匯出。
- **AC-8** 每個回應 DTO 至少有以下解析測試，測資依 flutter-styles §8.2 放在同檔的 `_Data`：
  1. **完整測資**：依 §3 的全部欄位組出 JSON，`fromJson` 之後逐欄斷言。
  2. **只有必有欄位**：選填欄位斷言為 `null`，不得出現預設值。
  3. **Round-trip**：`X.fromJson(x.toJson()) == x`。直接傳 map、不經過 `jsonEncode`，這樣可以確認巢狀物件的 `explicitToJson` 有設定。
  4. 數值欄位（`rating`、`distance`、`cost`、`latitude` 等）在 JSON 給 `int` 時，能正確轉成 `double`。

### 4.4 Repository

- **AC-9** 介面放在 `lib/domain/repositories/`，實作放在 `lib/data_layer/repositories/`，切分方式依 D-1 的決定。12 支端點每支在 Repository 都有一個對應方法，兩邊的 barrel 都要匯出。
- **AC-10** 在 `lib/app/di/injection.dart` 以 `registerLazySingleton` 註冊。`test/di_test.dart` 為每個新 Repository 補上「resolve 成介面型別」的案例（比照 `di_test.dart:107-111`）。
- **AC-11** 每個 Repository 實作都可以注入 `APIClz` 替身，沿用 `main_repo.dart:23-24` 的 optional constructor 參數慣例，預設值是 `GetIt.I<APIClz>()`。這是 mocktail 測試的前提。
- **AC-12** Repository 測試使用 mocktail，以 `_Mock` 前綴命名替身，檔案放在 `test/data_layer/`。每個方法至少涵蓋：
  1. 參數正確轉給 `APIClz`，包含 locale 為 `Constants.locale`、#3 的 `transaction_type` 固定為 `delivery`（若 0b 採用 §3.3 的建議）。
  2. 回傳值就是 `APIClz` 的結果，或依 D-3 轉換後的結果。
  3. **錯誤路徑**：`APIClz` 拋出 status code 403 的 `DioException` 時，Repository 的行為符合 D-2 的決定。#4、#5、#6 三支必測，其他端點至少測一支代表。
- **AC-13** #4、#5、#6 的 Repository 介面方法用 `///` 註解標明存取限制，以及 403 時的行為。

### 4.5 其他

- **AC-14** 不新增 `pubspec.yaml` 相依。`equatable`、`json_annotation`、`retrofit`、`mocktail` 都已經安裝（`pubspec.yaml:21,30,84,105`）。

---

## 5. 範圍邊界

### 5.1 In Scope

- `APIClz` 新增 12 支方法，並重新產生 `api_clz.g.dart`。
- 新增 §3 回應所需的 DTO 與 `.g.dart`，並更新 `dto_barrel.dart`。
- 新增 Repository 介面與實作，更新兩個 barrel、`injection.dart`、`test/di_test.dart`。
- 新增 DTO 解析測試、Repository 測試，以及 AC-5 的 request 擷取測試。
- 若 D-4 選 (a)：把 `YelpSearchDto` 改成 `final` 欄位 + `Equatable` + `explicitToJson: true`，對外行為不變。

### 5.2 Out of Scope

- **BLoC、UI、Entity**：Entity 是否需要新增見 D-3，建議不做。
- **既有端點**：
  - 不改 `businessesSearch` 的參數，包括 `location`、`price` 型別、`categories`、`radius`、`open_now`（A-8.7、A-8.10）。
  - 不補 `YelpRestaurantDetailDto`／`YelpRestaurantSummaryDto` 的欄位，也不刪除 `fetchToken`（A-8.8）。
  - 不改既有 DTO 的相等性語意。
- **API Key 權限**：不處理 #4–#6 的開通，不做「依權限決定是否呼叫」的開關。
- **錯誤型別體系**：不引入 `Result<T>`／`AppException`（A-8.1），也不做 Dio 錯誤對應 interceptor（A-8.3）。目前 `lib/features/foundation/` 只有 `extension/`、`style/`，A-8.1 尚未落地。
- **client 端驗證**：不驗證參數範圍、格式、條件式必填（例如 `location` 與經緯度擇一）。
- **其他**：
  - 不做快取，包括 A-8.12 提到的分類本地快取。
  - 不做 GraphQL（A-8.13）。
  - 不做真實 API 的整合測試。
- **不改 `@RestApi(baseUrl: …)`**：它與 flutter-styles §X.1 不一致，但屬於既有寫法，不在本次範圍。

### 5.3 與 brainstorm 項目的關係

| 項目 | 關係 |
|------|------|
| A-8.9 Autocomplete（brainstorm:1735-1749） | 本規格交付它的 API、DTO、Repository。brainstorm 原本建議放進 `MainRepository`／`MainRepo`（:1744），也提議新增 `autocomplete_suggestion_entity.dart`（:1743）。本規格依 D-1、D-3 的建議，改成獨立的 Repository 並且不建 Entity。A-8.9 之後只需要做 debounce、Overlay UI 和 BLoC |
| A-8.12 Categories（brainstorm:1880-1892） | 本規格交付 `/v3/categories`、`/v3/categories/{alias}` 的 API、DTO、Repository。本地快取和篩選頁 Chip UI 留給 A-8.12。注意：Repository 固定帶 `locale=zh_TW`，會讓結果只剩 zh_TW 可用的分類（spec:1757） |
| A-8.7／A-8.8／A-8.10 | 明確排除（Q4）。A-8.8 補齊 `YelpRestaurantSummaryDto` 的 `is_closed`／`url`／`display_phone` 後，#1–#3 若採 D-4 (a) 就會自動受益 |
| A-8.1／A-8.3 | 403 的長期呈現方式取決於這兩項（D-2）。本規格不搶先做 |
| A-8.2／A-8.4 | A-8.2 已裁定「Infra（DTO）← Domain」是合法的分層（brainstorm:1577），這是 D-3「Repository 直接回傳 DTO」的依據。A-8.4 正在評估 DTO 與 Entity 合一，本規格不先建 Entity，避免增加 A-8.4 要處理的類別數 |
| A-8.13 GraphQL | 沒有重疊。本規格只處理 REST，不碰 `/v3/graphql` |

---

## 6. 風險

| # | 風險 | 影響 | 緩解 |
|---|------|------|------|
| R-1 | 10 支端點沒有規劃中的消費端，成為長期沒人呼叫的死碼 | 維護成本；Yelp 改 schema 時無人察覺 | AC-8 的解析測試鎖住 schema。brainstorm 中補上對應的消費項目，或日後定期清理 |
| R-2 | #5 已 deprecated；#4、#6 在現行 API Key 下回 403 | 實作完成後，三支在正式環境都拿不到資料 | 使用者知情後仍要求納入。AC-13 在介面標註，AC-12 鎖住 403 的行為 |
| R-3 | spec 中 Business 的 `categories` 字面是 **array of array**（spec:83-102、641-660），但既有 `/v3/businesses/search` 一直以 array of object 解析（`yelp_restaurant_summary_dto.dart:21`），且在正式環境運作中 | 若照 spec 字面實作，實際回應會解析失敗 | 以現有程式在正式環境的行為為準，採 array of object；解析測試用 array of object 的測資。上線前用真實回應抽查一次（屬人工確認） |
| R-4 | 陣列參數的格式：#3 的 `categories`／`price` 在 spec 說明為逗號分隔；#4 的 `business_ids`、#7 的 `categories`／`excluded_events`，spec 摘錄沒有交代 style／explode | 格式錯誤時，Yelp 可能只認第一個值或回 400，而且單元測試測不出來 | D-5 統一格式，AC-5 鎖住實際送出的內容。未在說明中提到逗號的參數，需要用真實 API 抽查 |
| R-5 | spec 摘錄被截斷：`display_address.items.type` 在 spec:175、468、733、1306 顯示為 `"..."`，部分 description 有截斷 | 型別判斷需要推論 | `display_address` 依 spec:1500、1711 的完整定義與既有 DTO（`yelp_restaurant_location_dto.dart:13`）採 `List<String>`。其他截斷處只影響說明文字，不影響型別 |
| R-6 | D-4 選 (a) 時會修改既有的 `YelpSearchDto` | `main_repo.dart:52-66` 讀取 `businesses`。若有地方寫入欄位，改成 `final` 後會編譯失敗 | 實查結果：`YelpSearchDto` 在 `lib/`、`test/` 中只有 `main_repo.dart:52` 一個使用點，而且只讀取。`toJson` 沒有呼叫者，加上 `explicitToJson` 不影響任何行為。編譯本身與 AC-3 會擋下回歸 |
| R-7 | 新的 Equatable DTO 內嵌沒有值相等性的既有 DTO | round-trip 相等測試失敗，或測試被改成比對 identity 而失去意義 | §3.0 明文禁止。D-4 (a) 的元素 `YelpRestaurantSummaryDto` 以 id 判斷相等，可以接受，但測資必須帶 `id`：`id` 為 null 時永遠不相等，見 `empirical_m3_stress_test.dart:181` |
| R-8 | 12 支方法擠在同一個 PR | review 困難 | 0b 可以依 D-1 的領域分組拆成多個任務，每組都能獨立通過 AC-1～AC-4 |

---

## 7. 待決事項（交 STAGE 0b）

### D-1 Repository 的切分方式

| 選項 | 內容 | 代價 |
|------|------|------|
| R1 一支大的 | `YelpPlacesRepository`，12 個方法 | 只有 1 組介面、實作、DI、測試，類別最少。但 4 種不相干的資源混在同一個介面裡，未來每個 BLoC 測試都要面對 12 個方法的替身，介面的任何改動都會波及所有消費端 |
| **R2 依回應的主資源拆（建議）** | Business（#1–#6）、Event（#7–#9）、Category（#10–#11）、Autocomplete（#12） | 4 組介面、實作、DI 註冊、測試檔。每組都很小，而且和未來消費端一對一：A-8.9 對 Autocomplete、A-8.12 對 Category |
| R3 掛到既有 Repository | autocomplete 放進 `MainRepository`（brainstorm:1744 的原始建議），其餘放進 `RestaurantDetailRepository` 等 | `MainRepo` 是有狀態的分頁 Repository（`main_repo.dart:17-21` 的 `summaryInfoSet`、`_offset`、`_isLoading`）。把無狀態的端點混進去會和 `reset()`、分頁狀態耦合，也會讓既有介面膨脹 |

**建議 R2。** 理由：

- 分組規則是「回應的主資源是什麼」，看 §3.1 的「回應頂層」欄就能決定，不需要逐支判斷。
- 依賴方向乾淨：每個未來的 BLoC 只依賴它需要的那一組。

如果 0b 認為只有一個方法的 Autocomplete Repository 太薄，可以退一步把它併入 Business，因為它回傳的是搜尋建議，最接近 Business 搜尋。但不要退到 R1 或 R3。命名建議沿用既有的 `XxxRepository`（介面）與 `XxxRepo`（實作）配對；是否加 `Yelp` 前綴由 0b 決定。

### D-2 受限端點（#4–#6）的 403 在 Repository 層怎麼呈現

| 選項 | 內容 | 評估 |
|------|------|------|
| **E1 原樣上拋 `DioException`（建議）** | Repository 不捕捉 403，與現行 `RestaurantDetailRepo`（不 catch）、`MainRepo`（`main_repo.dart:78-80` 記 log 後 `rethrow`）一致。介面用 `///` 標註「未開通時拋出 `DioException`，`response.statusCode == 403`」 | 沒有特殊情況。12 支端點的錯誤路徑完全相同。等 A-8.3 落地，所有端點會在 interceptor 這一個地方被統一對應成 `AppException`，不需要回頭改這三支 |
| E2 只在 #4–#6 把 403 轉成新型別（例如 `YelpAccessDeniedException implements Exception`） | 呼叫端不必依賴 Dio 型別 | 在 A-8.1 定義 `AppException` 階層之前，先做出一個平行的例外型別，之後還得併回去。而且只有三支有特殊處理，本身就是特殊情況 |
| E3 403 時回傳 `null` 或空物件 | 呼叫端不會遇到例外 | 把「沒有權限」和「沒有資料」混成同一件事，錯誤被吞掉，違反 flutter-styles §6.1 的「不吞錯」。**不建議** |
| E4 回傳 `Result<T>` | 型別最完整 | 依賴尚未落地的 A-8.1（`lib/features/foundation/` 沒有 `result/`）。**本次不可行** |

**建議 E1。** 是否像 `MainRepo` 一樣在 rethrow 前記 `logger.e`，由 0b 決定，但 12 支的作法要一致。

### D-3 Repository 回傳 DTO 還是新建 Entity

**建議直接回傳 DTO，不新建 Entity。** 依據：

- A-8.2 已裁定 Domain 依賴 Infra 的 DTO 是合法分層（brainstorm:1577），既有 entity 也直接 import DTO（`restaurant_entity.dart:1`）。
- A-8.4 正在評估 DTO 與 Entity 合一。
- 新建 Entity 等於再多約 15 個鏡像類別，加上 `fromDto` 和測試，但目前沒有任何消費端。

代價：domain 的 Repository 介面檔第一次 import `api/dto`。現有介面只 import `../entities/`，例如 `restaurant_detail_repository.dart:1`。不過這和 entity 已經在走的依賴方向相同。等某個功能真的需要 Entity（例如 A-8.9 的 UI model），再到那個功能裡新增。

### D-4 Business 回應（#1–#3）的 DTO 策略

| 選項 | 內容 | 評估 |
|------|------|------|
| **(a) 共用 `YelpSearchDto`（建議）** | #1、#3 的回應結構 `{businesses, total}` 和 `YelpSearchDto` 完全相同；#2 只少了 `total`，解析後就是 `null`。`YelpSearchDto` 改成 `final` + `Equatable` + `explicitToJson: true`，元素沿用 `YelpRestaurantSummaryDto` | 新增類別 0 個。同一個 Yelp Business 資源只有一種型別，結果可以直接走 `RestaurantEntity.fromDto`（`restaurant_entity.dart:35`），A-8.8 補欄位時也會自動受益。缺點：元素不是 Equatable，以 id 判斷相等；`alias` 等 6 個欄位暫時拿不到（§3.2）；需要確認改 `YelpSearchDto` 不違反 Q4（Q4 排除的是修正既有端點的參數與 Detail 欄位，本改動不屬於這兩類，但仍請 0b 確認） |
| (b) 新增 Equatable 外殼，元素沿用 Summary DTO | 不動任何既有 DTO | 與 `YelpSearchDto` 結構完全重複，只多了 `Equatable` |
| (c) 新增完整的 `YelpBusinessDto` | 涵蓋 spec 全部 17 個欄位，全部 Equatable | 欄位最完整，但同一資源出現兩種型別，`RestaurantEntity.fromDto` 吃不了它。A-8.8 補欄位時兩邊都得改，日後也容易漂移 |

**建議 (a)。** 這也決定了 Autocomplete 的 `categories` 元素要用 #10 新建的 Category DTO（Equatable），**不能**用 `YelpRestaurantCategoryDto`，理由見 §3.0 最後一列。

> **實作結果**：使用者在 STAGE 0a 確認時裁決「不要建立重複的 DTO」，所以 T1 把 `YelpRestaurantCategoryDto` 改成 Equatable，Autocomplete 與 #10／#11 都直接重用它，沒有新建 Category DTO。

### D-5 陣列 query 參數的序列化格式

涉及的參數：#3 的 `categories`、`price`；#4 的 `business_ids`；#7 的 `categories`、`excluded_events`。

**現況**：
- Dio 預設 `ListFormat.multi`（`dio-5.11.1/lib/src/options.dart:728`），送出的是 `k=a&k=b`。
- retrofit 4.10.0 的 annotation 不支援針對單一參數指定 `ListFormat`（以 `ListFormat` 搜尋整個套件，沒有任何結果）。

**建議**：
- `APIClz` 的這些參數宣告成 `String?`，也就是實際送上線的格式：逗號分隔。這和 A-8.7 對既有 search `price` 的處理方向一致（brainstorm:1625,1633）。
- Repository 對外接收 `List<…>`，由它負責 `join(',')`，不讓呼叫端知道序列化細節。
- 風險見 R-4。

### D-6 新 DTO 是否加 `checked: true`

既有 Yelp DTO 都沒有加；domain entity 從 2026-09-24 規格 v5.2 起已經加上。

- 不加：型別不符時，產生碼拋出的是 `TypeError`，這是一種 `Error`。依 flutter-styles §6.1，`Error` 不應該被捕捉。
- 加上：改拋 `CheckedFromJsonException`（`implements Exception`），呼叫端用 `on Exception` 就能接住。

**建議新 DTO 加上**，只影響新檔案，既有 DTO 維持原樣。
