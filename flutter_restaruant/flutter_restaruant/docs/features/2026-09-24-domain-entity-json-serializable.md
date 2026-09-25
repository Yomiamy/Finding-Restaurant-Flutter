# Feature: Domain Entity 導入 `@JsonSerializable`，欄位 nullable 化，預設值移至 BLoC UI Model

> 建立日期：2026-09-24
> 範圍：`lib/domain/entities/` 內手寫 `fromJson` / `toJson` 的 A2UI／AI 覓食相關類別，及其 BLoC、View 讀取端
> 狀態：草稿 v5（待確認）。修訂沿革見 §7

---

## 1. 使用者故事

身為維護者，我希望：

1. domain entity 的 JSON 轉換統一由 `@JsonSerializable` 產生，和 `lib/data_layer/dto/` 的既有慣例一致。
2. **entity 如實反映 server（LLM）給的資料**：server 沒給的欄位就是 `null`，不在解析時捏造預設值。
3. **預設值只在呈現層補**：由 BLoC 把 entity 轉成欄位都是 non-null 的 UI model，View 只讀 UI model。

**前提**：使用者看到的畫面與互動行為，要和現在完全一樣。

---

## 2. 背景（現況與動機）

### 2.1 既有慣例
- `json_annotation: ^4.9.0`（lock 4.12.0）、`json_serializable: ^6.8.0`（lock 6.14.1）、`build_runner: ^2.4.12` 都已安裝。專案沒有 `build.yaml`。
- `lib/data_layer/dto/` 下 13 個 DTO 與 `lib/model/result_vo.dart` 已經用 `@JsonSerializable`：逐類別指定 `fieldRename: FieldRename.snake`，巢狀類別加 `explicitToJson: true`。`.g.dart` 會 commit 進 repo。
- `analysis_options.yaml` 排除 `**/*.g.dart`。

### 2.2 資料來源與信任邊界

| 呼叫端 | 資料來源 | 對異常輸入的處理 |
|--------|----------|------------------|
| `ai_foodie_repo.dart::_parseResponse` → `A2UIComponent.fromJson` | **LLM 輸出（不可信）** | 外層 `on Exception catch` 降級成 `FallbackMarkdownComponent` |
| `menu_vision_repo.dart` → `A2UIComponent.fromJson({'component_type':'dish_catalog', ...})` | **LLM 視覺辨識輸出（不可信）** | v5.3 起不再捕捉：`FormatException`／`CheckedFromJsonException`／其他 `Exception` 直接拋給 `MenuVisionBloc`，由其 `on Exception catch` 顯示多語系錯誤訊息 |
| `ai_foodie_repo.dart::serializeAssistantHistory` → `component.toJson()` → `jsonEncode` | 本地 entity | **當成多輪對話歷史回送 LLM** |
| `AiFoodieBloc` → `state.messages` 當 `history` 傳給 repo | 本地 entity | history 必須是 entity（要能 `toJson`），不能只剩 UI model |

### 2.3 手寫程式裡的隱性語意
1. **List 用 `whereType<T>()` 靜默過濾**：`dishes`、`allergens`、`dietary_tags`、`ingredients`、`highlights`、`items`、`chips`、`options`、`components`。產生碼預設是 `e as T`，遇到混型元素會 throw。
2. **enum 容錯**：`AllergenRiskLevel.fromString` 不分大小寫，`may_contain`／`maycontain` 都對到 `mayContain`；`DishCategory.fromString` 未知值歸到 `other`。輸出是 `enum.name`。
3. **null 省略**：`restaurantTitle`、`price`、`address`、`category`、`imageUrl` 為 null 時不輸出 key。
4. **信封格式**：元件 `toJson` 輸出 `{'component_type', 'data': {...}}`，`fromJson` 只收 `data`。`FallbackMarkdownComponent` 是扁平的 `{'component_type', 'text'}`。
5. **分派器是元件 `fromJson` 的唯一呼叫端**（`a2ui_component.dart:21,30,39,48`），`isValid` 只在 `:212` 使用。
6. **型別錯誤會 throw**：`json['x'] as String?` 型別不符就丟 `TypeError`，由 repo 層接住。**v5.2 起改為 `checked: true`，產生碼改丟 `CheckedFromJsonException`；分派器的 `_optString` 與 `data` 型別檢查改丟 `FormatException`，見 §7。**

---

## 3. 設計

### 3.1 三層職責

| 層 | 職責 | 預設值 |
|----|------|--------|
| **Entity**（`lib/domain/entities/`） | 如實反映 server 資料。欄位 nullable，缺值就是 `null` | **無** |
| **分派器**（`A2UIComponent.fromJson`，唯一手寫） | 拆信封、依型別分派、`isValid` 過濾、不合格就降級成 `FallbackMarkdownComponent` | 只有降級文字（`A2UIFallbackStrings`），這是「降級」這個業務行為本身，不是欄位預設值 |
| **UI model**（BLoC 產生） | 欄位都是 non-null，給 View 直接用 | **全部預設值集中在這裡**（空字串、`0.0`、`'TWD'`、i18n 標題、`DishCategory.other`、`AllergenRiskLevel.none` 等） |

### 3.2 Entity 規則（10 個類別）

- 全部改用 `@JsonSerializable`，並設定 `includeIfNull: false`：**server 沒給的欄位，`toJson` 就不輸出該 key**，回送 LLM 的內容不會出現 `null`。
- **所有欄位改成 nullable**（包含 List 與 enum）。建構式參數全部改成 optional、不帶預設值。
- **不使用 `@JsonKey(defaultValue:)`，建構式也不放預設值。**
- 只保留兩種轉換器（`@JsonKey(fromJson:)`）：
  - **`whereType` 過濾的 List**：輸入 null 回傳 null；有值就過濾掉型別不符的元素。
  - **enum 容錯**：輸入 null 回傳 null；有值才走 `fromString`（保留別名與不分大小寫）。
- v4 的多語系字串、`DateTime.now()`、`'TWD'` 等轉換器**全部移除**，這些值改由 UI model 提供。
- `AiFoodieMessage.createdAt` 改為 `DateTime?`：`created_at` 缺值或解析失敗時就是 `null`（用轉換器處理 `tryParse`，不讓產生碼的 `DateTime.parse` 拋例外）。
- 不是建構式參數的 getter（`isAssistant`、`isValid`）明確標註 `@JsonKey(includeFromJson: false, includeToJson: false)`。
- 元件的 `toJson` 保留一行手寫信封，例如 `{'component_type': 'dish_catalog', 'data': _$DishCatalogComponentToJson(this)}`。`FallbackMarkdownComponent` 維持扁平：`{'component_type': 'fallback_markdown', ..._$FallbackMarkdownComponentToJson(this)}`。
- **`FallbackMarkdownComponent` 維持預設的 `createFactory: true`，但 class 裡不宣告 `fromJson` factory。** v3 原本寫 `createFactory: false`，那是錯的：json_serializable 6.14.1 在 `createFactory: false` 時，不會把 `toJson` 限縮到建構式有用到的欄位（`generator_helper.dart:87-109`），Equatable 的 `props`、`stringify`、`hashCode` 會被寫進 `toJson`。維持預設後，`.g.dart` 會多一個沒人用的私有函式，但 `.g.dart` 已被排除在 analyzer 之外，不會有警告。
- 型別不符（例如 `name: 123`）**v5.2 起改拋 `CheckedFromJsonException`**（`checked: true`；見 §7），不再是 `TypeError`。

### 3.3 分派器與 domain 內部邏輯改為接受 null

- 降級規則改成把 null 和空視為同一種情況：`dishes`、`items`、`chips` 是 null 或空就降級；`options` 是 null 或少於 2 個就降級；未知 type 照舊降級。
- `action_chip_group` 分支接手 `isValid` 過濾，從 `ActionChipGroupComponent.fromJson` 移過來。順序是：解析 → 過濾 → 判斷是否為空 → 降級或建立元件。
- `ActionChipItem.isValid` 改為接受 null 欄位：`label`、`action` 是 null 或空白就不合法。
- 降級文字的 fallback（`json['text'] ?? A2UIFallbackStrings.xxx`）維持在分派器。

### 3.4 UI model（BLoC 產生）

- 為 View 需要的 entity 建立對應的 UI model，欄位全部 non-null：
  - Menu Vision：catalog、dish、allergen
  - AI 覓食：message、comparison matrix 與其中的 item、action chip group 與其中的 chip、decision roulette、fallback 文字
- A2UI 元件的 UI model 同樣做成 sealed 階層，讓 View 維持窮盡式 `switch`。
- 預設值規則集中定義在 UI model 的轉換函式，數值與目前 entity 解析時給的完全相同，確保畫面不變：
  - 空字串
  - `rating`／`price`／`chefRecommendationScore` 預設 `0.0`，`spiceLevel` 預設 `0`
  - `currency` 預設 `'TWD'`
  - `category` 預設 `DishCategory.other`，`riskLevel` 預設 `AllergenRiskLevel.none`
  - `title`、`name` 缺值時使用對應的 `A2UIFallbackStrings`
  - `isUser` 預設 `false`
  - `createdAt` 缺值時使用轉換當下的時間
- **v5.1 調整（STAGE 0b 讀碼後經使用者確認）**：
  - UI model **只收 View 實際讀取的欄位**。`DishItemEntity` 的 `id`、`chefRecommendationScore`，`AllergenInfo.note`，`restaurantTitle`，`AiFoodieMessage` 的 `id`、`createdAt` 不進 UI model，所以上面「`createdAt` 缺值時用當下時間」「`chefRecommendationScore` 預設 0.0」不實作；這些欄位缺值時在 entity 維持 `null`，日後有讀取端時再補。
  - 比較卡片 UI model 的 `price`、`address`、`category`、`imageUrl` 維持 `String?`：View 用 `!= null` 決定是否渲染，改成 `''` 會改變畫面。
- **State 同時保存兩份資料**：`AiFoodieState` 保留 entity 形式的 `messages` 作為 LLM 對話歷史的來源（repo 需要呼叫 `toJson`），另外存一份 UI model 給 View 顯示。`MenuVisionSuccess` 改為持有 UI model。實際欄位設計在 STAGE 0b 決定。
- **Event 改帶 UI model**：`TriggerActionChip.chip`、點擊比較卡片等由 View 發出的事件，改為攜帶 UI model。BLoC 需要 entity 語意時，由 UI model 提供對應欄位。
- **View 不再 import domain entity**：`dish_card.dart`、`allergen_badge.dart`、`menu_vision_sheet.dart`、`comparison_matrix_card.dart`、`action_chip_group_widget.dart`、`ai_foodie_sheet.dart`、`decision_roulette_dialog.dart` 都只讀 UI model。

### 3.5 【核心判斷】

✅ 值得做，但**範圍已經遠大於原始需求**。原本只是「entity 改用 `@JsonSerializable`」，現在變成三層重構：entity nullable 化、分派器與 domain 邏輯接受 null、新增 UI model 並改寫兩條 flow 的 BLoC／State／Event／View。

- **資料結構**：entity 只保存 server 事實，UI model 保存呈現決策。v4 裡寫死在 entity 解析中的預設值（i18n、`DateTime.now()`、`'TWD'`）都搬到 UI model，domain 不再依賴 i18n 的預設文字（分派器的降級文字除外）。
- **消滅的複雜度**：entity 的轉換器從 v4 的 6 類減少到 2 類（List 過濾、enum 容錯）。
- **最大破壞風險**：UI model 的預設值只要和現在 entity 解析的預設值有一處不同，畫面就會改變。第 4 節用 widget 測試鎖住。

---

## 4. 驗收條件（可機械驗證）

1. **先寫特性測試，再改實作**：改動前先把以下「使用者可見行為」固定成測試，改動後必須全綠：
   - **畫面等價**：每個 View（dish card、allergen badge、comparison matrix card、action chip group、roulette、fallback 文字）在「全部欄位缺值」和「全部欄位有值」兩種輸入下，顯示的文字與數值和改動前一致（widget test）。
   - **混型 List**：上面 §2.3 第 1 點列出的 List 混入非預期型別元素時，被過濾，不 throw。
   - **分派器**：chips 部分不合法時只保留合法的，全部不合法時降級；dishes／items／chips 是 null 或空時降級；options 是 null 或少於 2 個時降級；未知 type 降級。
   - **enum**：`risk_level` 輸入 `"CONTAINS"`、`"may_contain"`、`"maycontain"`、`"MayContain"`、`"unknown"` 時，對應結果不變；缺值時 entity 為 `null`，UI model 為 `none`。`category` 同理，UI model 預設 `other`。
   - **數值**：`price`／`rating`／`chef_recommendation_score` 給 `int` 能正確轉成 double；`spice_level` 給 `2.7` 得到 `2`。
   - **純量型別錯誤**（例如 `name: 123`）**v5.2 起改拋 `CheckedFromJsonException`／`FormatException`**（見 §7），由 repo 層接住後降級。
2. **Entity 如實反映缺值**：缺欄位時，entity 對應欄位為 `null`（包含 List 與 enum）。
3. **toJson**：
   - 所有欄位都有值的實例：`jsonEncode(entity.toJson())` 的字串和改動前**逐字相同**（key 順序、enum 字串、信封格式都不變）。
   - 有欄位為 null 的實例：該 key **不輸出**，也不能出現 `null` 值。
   - 輸出不能多出 `props`、`stringify`、`hashCode`、`isValid`、`isAssistant` 等 key。
   - Round-trip：`A2UIComponent.fromJson(c.toJson())` 與 `c` 相等。
   - `FallbackMarkdownComponent` 維持扁平格式，`component_type` 排在第一個。
4. **簽章**：`fromJson(Map<String, Object?>)` 與 `Map<String, Object?> toJson()` 的簽章不變。
5. `dart run build_runner build --delete-conflicting-outputs` 成功，`*.g.dart` 一起 commit。
6. `flutter analyze` 零警告；本次範圍內的 10 個 entity 不得出現在 `lib/flow/**/view/`（範圍外的 `RestaurantEntity` 等以 `import … show` 限縮引入，屬 v5.1 確認的例外）。
7. 既有測試全綠（因型別變更必須調整斷言的，逐條列在 PR 描述中並說明理由），至少包含：`test/domain/menu_vision_entity_test.dart`、`test/domain/entities/a2ui_component_test.dart`、`test/data_layer/ai_foodie_repo_test.dart`、`test/data_layer/menu_vision_repo_test.dart`、`test/flow/menu_vision/*`、`test/flow/ai_foodie/*`、`test/empirical_m3_stress_test.dart`、`test/empirical_m4_stress_test.dart`。

---

## 5. 範圍邊界

### In scope
- 10 個 entity：`AllergenInfo`、`DishItemEntity`、`ActionChipItem`、`RestaurantComparisonItem`、`DishCatalogComponent`、`ComparisonMatrixComponent`、`ActionChipGroupComponent`、`DecisionRouletteComponent`、`FallbackMarkdownComponent`、`AiFoodieMessage`。全部改用 `@JsonSerializable`，欄位 nullable。
- `A2UIComponent.fromJson` 分派器：改為接受 null，並接手 `isValid` 過濾。
- 新增 Menu Vision 與 AI 覓食兩條 flow 的 UI model，以及 entity 轉 UI model 的轉換。
- 兩條 flow 的 BLoC／State／Event／View 改用 UI model。
- `ai_foodie_repo.dart`、`menu_vision_repo.dart` 內讀取 entity 欄位的地方改為接受 null（例如智慧降級流程、history 序列化）。
- 補齊第 4 節的特性測試。

### Out of scope
- 不動 `lib/data_layer/dto/`，也不動其他 entity（`RestaurantEntity`、`UserEntity` 等）。
- 不改 JSON schema（`ai_foodie_schema.dart`）、LLM prompt、任何 key 名稱或 enum 輸出字串。
- 不引入 `freezed`，也不做 sealed union 的自動分派。
- 不為 `FallbackMarkdownComponent` 宣告 `fromJson` factory，也不把它的輸出改成信封格式。
- 不新增 `build.yaml` 全域設定。

---

## 6. 風險

| 風險 | 影響 | 緩解 |
|------|------|------|
| UI model 的預設值和現在 entity 解析的預設值不同 | 畫面文字或數值改變 | 預設值集中在 UI model 轉換函式一處定義；第 4.1 節用 widget test 比對「全部缺值」的畫面 |
| `whereType` 被產生碼的 `as T` 取代 | 混型 List 從局部過濾變成整張卡降級 | 所有 List 都走轉換器；第 4.1 節的混型測試負責攔截 |
| `toJson` 省略 null 後，送回 LLM 的歷史和現在不同 | 以前缺值時送 `""`，現在不送這個 key | 屬於刻意的語意變更：如實反映 server 沒給的資料。只有「原本就缺值」的情況受影響，有值的實例輸出逐字相同 |
| History 來源誤用 UI model | 對話歷史少了原始資料，或帶入預設值 | State 保留 entity 作為 history 的唯一來源；BLoC 測試驗證傳給 repo 的 `history` 是 entity |
| 產生碼把 getter 寫進 `toJson` | 多出的 key 污染 LLM 歷史 | 非建構式參數的 getter 明確標註 `includeToJson: false`；`FallbackMarkdownComponent` 不用 `createFactory: false`；第 4.3 節做 key 集合比對 |
| 分派器或 `isValid` 漏處理 null | 原本會降級的情況變成拋例外或顯示空卡片 | 第 4.1 節的分派器測試逐條涵蓋 null 與空的組合 |
| 範圍擴大，單一 PR 過大 | review 困難、回歸風險上升 | STAGE 0b 拆成可獨立驗證的任務：entity 與分派器 → Menu Vision flow → AI 覓食 flow；每個任務都要測試全綠才進下一個 |

---

## 7. 修訂沿革

- **v1**：只改 4 個葉節點。元件層、`FallbackMarkdownComponent`、`AiFoodieMessage` 維持手寫。
- **v2**：使用者指出 `ActionChipGroupComponent` 應由外部處理。確認分派器是元件 `fromJson` 的唯一呼叫端後，把 `isValid` 過濾移到分派器，4 個元件改用產生碼。
- **v3**：為了一致性，納入 `FallbackMarkdownComponent`。當時寫的 `createFactory: false` 在 v5 更正。
- **v4**：納入 `AiFoodieMessage`；預設值從 `@JsonKey(defaultValue:)` 改為寫在建構式。
- **v5**：使用者要求 entity 如實反映 server 資料：欄位全部 nullable、不帶預設值，預設值由 BLoC 轉成 UI model 時提供；`toJson` 省略 null；`isAssistant` 等 getter 明確標註不序列化；更正 v3 的 `createFactory: false`。
- **v5.2**（PR #127 review 過程追加，違反 flutter-styles §6.1「不捕捉 Error」）：`@JsonSerializable` 加上 `checked: true`，型別不符時產生碼改拋 `CheckedFromJsonException`（`implements Exception`）取代 `TypeError`；分派器 `_optString` 與 `data` 型別檢查改拋 `FormatException`。`menu_vision_repo.dart` 的 `on TypeError` 改為 `on CheckedFromJsonException`。`test/domain/entities/a2ui_characterization_test.dart` 的「純量型別錯誤」一組 8 個 case 期望值同步從 `TypeError` 改為對應的 `Exception` 子類（輸入不變）；本檔與計畫文件相應章節的 `TypeError` 敘述一併更新。
- **v5.3**（PR #127 review 過程追加，對應 flutter-styles §Y.4「錯誤／`Exception` 說明一律英文、BLoC 與 Presentation 文字一律多語系」）：`FormatException` 說明與 `Logger` 訊息改為英文；`menu_vision_repo.dart::analyzeMenuImageBytes` 不再把錯誤包成寫死中文的 `FallbackMarkdownComponent`，空回應與非物件 JSON 改拋 `FormatException`，其餘例外原樣上拋，由 `MenuVisionBloc` 既有的 `on Exception catch` 以 `menu_vision_error_analyze_failed`／`menu_vision_error_retry_failed` 顯示。分派器產生的「無菜色」降級文字維持原樣。
- **v5.4**（PR #127 review 意見）：分派器降級文字改以 `_firstText` 取第一個**非空白**候選（`text` → 元件標題 → `A2UIFallbackStrings` 預設），空字串與空白不再被 `??` 當成有值，避免 LLM 回傳 `restaurant_title: ""` 且無菜色時 Menu Vision 顯示空白失敗訊息。此情況在本 PR 之前即存在。
