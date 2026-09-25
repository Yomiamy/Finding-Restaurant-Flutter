# Implementation Plan：Domain Entity 導入 `@JsonSerializable`，欄位 nullable 化，預設值移至 BLoC UI Model

> 關聯規格：[`docs/features/2026-09-24-domain-entity-json-serializable.md`](../features/2026-09-24-domain-entity-json-serializable.md)（v5，已確認）
> 建立日期：2026-09-24
> 狀態：草稿（待確認）
> 基準：`main` @ `95ea532`；`flutter analyze` 目前 **No issues found**（本計畫每個任務結束時都必須維持零 issue）

---

## 0. 已查證的產生器行為（計畫依據）

| 事實 | 來源 | 對計畫的影響 |
|------|------|--------------|
| `int` 欄位產生 `(json['x'] as num?)?.toInt()`；`double` 產生 `(… as num?)?.toDouble()` | `json_serializable-6.14.1/lib/src/utils.dart:267,271` | `spice_level: 2.7 → 2`、`price: 280 → 280.0` 不需轉換器 |
| `toJson` 的 key 順序＝**欄位宣告順序** | `field_helpers.dart:39 _sortByLocation` | 欄位宣告順序一律不動；現行手寫 `toJson` 的 key 順序剛好與欄位宣告順序一致 |
| `@JsonKey(fromJson: f)` 會先把輸入 cast 成 `f` 的參數型別（`List<Object?>?` → `as List?`，`String?` → `as String?`） | `lambda_result.dart::_cast` | 轉換器參數寫成 `String?`／`List<Object?>?`，型別不符仍會 throw；**v5.2 起 `checked: true` 把這個 cast 包進 try/catch，改拋 `CheckedFromJsonException`（不再是 `TypeError`），見規格 §7** |
| 無 `defaultValue` 時使用建構式預設值；`createFactory: false` 會把 Equatable getter 寫進 `toJson` | 規格 §3.2 | entity 建構式不放預設值；`FallbackMarkdownComponent` 維持預設 `createFactory` 但不宣告 `fromJson` |
| `analysis_options.yaml` 排除 `**/*.g.dart` | repo | 產生碼裡未使用的 `_$FallbackMarkdownComponentFromJson` 不會觸發警告 |

---

## 1. 實作方向與 trade-off

三條路都能到同一個終點，差別在「中途每個 commit 是否可編譯、預設值在任何時刻是否只存在一處」。

| 方案 | 順序 | 優點 | 缺點 |
|------|------|------|------|
| **A（推薦）先 UI model，後 entity** | T1 特性測試 → T2/T3 兩條 flow 改用 UI model（entity 仍 non-null，轉換只是欄位複製）→ T4a–c entity nullable 化，**同一個 commit** 把預設值從 entity 搬到 UI model 轉換函式 | 每個任務結束都可編譯、全綠；預設值在任何 commit 都只存在一處；T2、T3 寫入路徑不重疊可並行 | 與規格 §6「entity 先 → Menu Vision → AI 覓食」順序相反（規格該列是拆分建議，不是驗收條件） |
| B 規格原順序：先 entity | entity nullable 化後，BLoC／View 立刻編譯失敗，只能先在 View 塞 `?? ''` 墊片，T2/T3 再拆掉 | 符合規格文字順序 | 中間產生一批注定被刪的墊片；墊片期間預設值同時存在於 View 與（未來的）UI model，正是規格 §6 第一條風險 |
| C 一次到位 | 單一大 commit | 最少協調 | review 困難、回滾粒度粗，直接踩到規格 §6 最後一條風險 |

**結論：採方案 A。** 關鍵洞察：entity 的欄位型別一改，所有讀取端同時壞掉；先把讀取端全部改走 UI model，entity 的 nullable 化就只剩「entity 檔 + 兩個轉換函式 + repo」三處，並且預設值是在同一個 commit 內從 entity「搬家」到 UI model，不會有兩份。

---

## 2. 資料結構設計

### 2.1 資料流（完成後）

```
LLM JSON ──► A2UIComponent.fromJson（唯一手寫分派器：拆信封／isValid 過濾／降級）
             │  entity：欄位全 nullable、無預設值、toJson 省略 null
             ▼
Repo ──► BLoC ──(fromEntity：所有預設值只在這裡)──► UI model（non-null）──► View
          │
          └─ AiFoodieState.messages（entity）──► repo.askAssistant(history:) ──► toJson ──► LLM
```

- entity 擁有「server 給了什麼」；UI model 擁有「畫面顯示什麼」。View 只讀 UI model。
- `AiFoodieState` 同時持有 `messages`（entity，history 唯一來源）與 `messageModels`（UI model，由 `copyWith` 從 `messages` 衍生，兩者不可能不同步）。

### 2.2 檔案位置（feature-first）

| 新檔 | 內容 |
|------|------|
| `lib/flow/menu_vision/model/menu_vision_model.dart` | `DishCatalogModel`、`DishModel`、`AllergenModel`；`export … show AllergenRiskLevel, DishCategory` |
| `lib/flow/ai_foodie/model/ai_foodie_model.dart` | `AiFoodieMessageModel`、sealed `A2UIComponentModel` 及其 4 個子類、`ComparisonItemModel`、`ActionChipModel` |
| `lib/domain/entities/entity_json_converters.dart` | 共用轉換器 `stringListFromJson`、`mapListFromJson`（不從 barrel 匯出） |

兩個 flow barrel（`menu_vision_barrel.dart`、`ai_foodie_barrel.dart`）各加一行 `export 'model/…_model.dart';`。不另建 `model_barrel.dart`（每個 flow 只有一個 model 檔）。

**enum 的處理**：`AllergenRiskLevel`、`DishCategory`（含 `displayName`／`toDisplayString()`）留在 domain，由 `menu_vision_model.dart` 以 `export '../../../domain/entities/allergen_info.dart' show AllergenRiskLevel;` 與 `export '../../../domain/entities/dish_item_entity.dart' show DishCategory;` 轉出。View 只 import model 檔，不直接 import `domain/entities`。

### 2.3 Menu Vision UI model

```dart
class DishCatalogModel extends Equatable {
  const DishCatalogModel({required this.currency, required this.dishes});
  factory DishCatalogModel.fromEntity(DishCatalogComponent entity);
  final String currency;
  final List<DishModel> dishes;
}

class DishModel extends Equatable {
  const DishModel({
    required this.name,
    required this.originalName,
    required this.price,
    required this.category,
    required this.allergens,
    required this.dietaryTags,
    required this.spiceLevel,
    required this.ingredients,
  });
  factory DishModel.fromEntity(DishItemEntity entity);
  final String name;
  final String originalName;
  final double price;
  final DishCategory category;
  final List<AllergenModel> allergens;
  final List<String> dietaryTags;
  final int spiceLevel;
  final List<String> ingredients;
}

class AllergenModel extends Equatable {
  const AllergenModel({required this.name, required this.riskLevel});
  factory AllergenModel.fromEntity(AllergenInfo entity);
  final String name;
  final AllergenRiskLevel riskLevel;
}
```

`MenuVisionSuccess.catalog` 型別：`DishCatalogComponent` → `DishCatalogModel`。
BLoC 轉換時機：`analyzeMenuImageBytes` 回傳 `DishCatalogComponent` 的那一刻（`CaptureAndAnalyzeMenu`、`RetryMenuAnalysis` 兩處），`emit(MenuVisionSuccess(catalog: DishCatalogModel.fromEntity(result)))`。
`MenuVisionFailure.message`：T4b 起改為 `result.text ?? ''`（BLoC 提供預設）。

### 2.4 AI 覓食 UI model（sealed 階層）

```dart
class AiFoodieMessageModel extends Equatable {
  const AiFoodieMessageModel({required this.isUser, required this.text, required this.components});
  factory AiFoodieMessageModel.fromEntity(AiFoodieMessage entity);
  final bool isUser;
  final String text;
  final List<A2UIComponentModel> components;
}

sealed class A2UIComponentModel extends Equatable {
  const A2UIComponentModel();
  /// `DishCatalogComponent` 在 AI 覓食畫布不渲染（現行為 `SizedBox.shrink()`），回傳 null 由呼叫端以 `.nonNulls` 略過。
  static A2UIComponentModel? fromEntity(A2UIComponent entity) => switch (entity) {
    ComparisonMatrixComponent() => ComparisonMatrixModel.fromEntity(entity),
    ActionChipGroupComponent() => ActionChipGroupModel.fromEntity(entity),
    DecisionRouletteComponent() => DecisionRouletteModel.fromEntity(entity),
    FallbackMarkdownComponent() => FallbackTextModel(text: entity.text),   // T4b 起 `?? ''`
    DishCatalogComponent() => null,
  };
}

final class ComparisonMatrixModel extends A2UIComponentModel { String title; List<ComparisonItemModel> items; }
final class ActionChipGroupModel  extends A2UIComponentModel { List<ActionChipModel> chips; }
final class DecisionRouletteModel extends A2UIComponentModel { String title; List<String> options; }
final class FallbackTextModel     extends A2UIComponentModel { String text; }

class ComparisonItemModel extends Equatable {
  final String id;
  final String name;
  final double rating;
  final String? price;      // 刻意 nullable，見下方說明
  final List<String> highlights;
  final String? address;    // 同上
  final String? category;   // 同上
  final String? imageUrl;   // 同上
}

class ActionChipModel extends Equatable {
  const ActionChipModel({required this.label, required this.action, required this.payload});
  factory ActionChipModel.fromEntity(ActionChipItem entity);
  final String label;
  final String action;
  final Map<String, Object?> payload;
}
```

> **為何 `price／address／category／imageUrl` 在 UI model 仍是 `String?`**：現行 entity 對這四個欄位的「解析預設」就是 `null`，而 View 以 `!= null` 決定是否渲染（`comparison_matrix_card.dart:144,153,192`），導航時也以 `address != null` 決定是否建 `RestaurantLocationEntity`（`ai_foodie_sheet.dart:92`）。改成 `''` 會讓 LLM 給 `""` 的情況多出／少掉 8px 間距與一個空 `Text`，違反「畫面完全一樣」。UI model 預設值＝現行 entity 預設值＝`null`，View 改用 `if (item.category case final category?)` 取代 `item.category!`（同時消滅 `!`）。

AI 覓食 State／Event：

| 類別 | 變更 |
|------|------|
| `AiFoodieState` | 新增 `final List<AiFoodieMessageModel> messageModels;`（預設 `const []`，加入 `props`）。`copyWith` **不接受** `messageModels` 參數；只要傳入 `messages`，就同步 `messageModels = messages.map(AiFoodieMessageModel.fromEntity).toList(growable: false)`。`messages` 保持 `List<AiFoodieMessage>`（history 來源） |
| `TriggerActionChip.chip` | `ActionChipItem` → `ActionChipModel`。BLoC 讀 `chip.action`／`chip.payload`，欄位名相同，`_onTriggerActionChip` 邏輯不變 |
| `ComparisonMatrixCard.onRestaurantTap`／`ActionChipGroupWidget.onChipTap` | callback 參數型別改為 `ComparisonItemModel`／`ActionChipModel`（這兩個是 View 內 callback，非 BLoC event） |
| `_MessageItem` | 讀 `AiFoodieMessageModel`；`switch` 窮盡 4 個 `A2UIComponentModel` 子類，**移除 `_ =>` 分支** |
| 轉盤按鈕 | 由 `DecisionRouletteModel` 組 `ActionChipModel(label: m.title, action: 'open_roulette', payload: {'title': m.title, 'options': m.options})` |
| `_navigateToRestaurantDetail` | 參數改 `ComparisonItemModel`，組 `RestaurantEntity` 的欄位對應不變 |

BLoC 轉換時機：所有 `emit(state.copyWith(messages: …))` 自動帶出 `messageModels`，BLoC 本體不需要逐處呼叫轉換。View 一律讀 `state.messageModels`。

### 2.5 預設值對照表（每一列都必須逐一相同）

「現行 entity 解析預設」＝ `main@95ea532` 手寫 `fromJson` 在欄位缺值時給的值。「UI model 預設」＝ T4 之後 `fromEntity` 的 `??` 右側。

| Entity.欄位 | 現行 entity 解析預設 | T4 後 entity | UI model 欄位 | UI model 預設 | 備註 |
|-------------|---------------------|--------------|---------------|---------------|------|
| `AllergenInfo.name` | `''` | `null` | `AllergenModel.name` | `''` | |
| `AllergenInfo.riskLevel` | `AllergenRiskLevel.none` | `null` | `AllergenModel.riskLevel` | `AllergenRiskLevel.none` | |
| `AllergenInfo.note` | `''` | `null` | —（View 未讀） | — | 見 §7 問題 3 |
| `DishItemEntity.id` | `''` | `null` | —（View 未讀） | — | |
| `DishItemEntity.name` | `''` | `null` | `DishModel.name` | `''` | |
| `DishItemEntity.originalName` | `''` | `null` | `DishModel.originalName` | `''` | |
| `DishItemEntity.price` | `0.0` | `null` | `DishModel.price` | `0.0` | |
| `DishItemEntity.category` | `DishCategory.other` | `null` | `DishModel.category` | `DishCategory.other` | |
| `DishItemEntity.allergens` | `[]` | `null` | `DishModel.allergens` | `const []` | |
| `DishItemEntity.dietaryTags` | `[]` | `null` | `DishModel.dietaryTags` | `const []` | |
| `DishItemEntity.spiceLevel` | `0` | `null` | `DishModel.spiceLevel` | `0` | |
| `DishItemEntity.ingredients` | `[]` | `null` | `DishModel.ingredients` | `const []` | |
| `DishItemEntity.chefRecommendationScore` | `0.0` | `null` | —（View 未讀） | — | |
| `DishCatalogComponent.restaurantTitle` | `null` | `null` | —（View 用 `MenuVisionSheet.restaurantTitle`） | — | 仍是分派器降級文字來源之一 |
| `DishCatalogComponent.currency` | `'TWD'` | `null` | `DishCatalogModel.currency` | `'TWD'` | |
| `DishCatalogComponent.dishes` | `[]`（空則分派器降級） | `null` | `DishCatalogModel.dishes` | `const []` | |
| `ComparisonMatrixComponent.title` | `A2UIFallbackStrings.comparisonMatrixTitle` | `null` | `ComparisonMatrixModel.title` | `A2UIFallbackStrings.comparisonMatrixTitle` | 分派器降級文字亦補同值 |
| `ComparisonMatrixComponent.items` | `[]`（空則降級） | `null` | `ComparisonMatrixModel.items` | `const []` | |
| `RestaurantComparisonItem.id` | `''` | `null` | `ComparisonItemModel.id` | `''` | |
| `RestaurantComparisonItem.name` | `A2UIFallbackStrings.comparisonItemName` | `null` | `ComparisonItemModel.name` | `A2UIFallbackStrings.comparisonItemName` | |
| `RestaurantComparisonItem.rating` | `0.0` | `null` | `ComparisonItemModel.rating` | `0.0` | |
| `RestaurantComparisonItem.price` | `null` | `null` | `ComparisonItemModel.price` | `null` | 刻意 nullable |
| `RestaurantComparisonItem.highlights` | `[]` | `null` | `ComparisonItemModel.highlights` | `const []` | |
| `RestaurantComparisonItem.address` | `null` | `null` | `ComparisonItemModel.address` | `null` | 刻意 nullable |
| `RestaurantComparisonItem.category` | `null` | `null` | `ComparisonItemModel.category` | `null` | 刻意 nullable |
| `RestaurantComparisonItem.imageUrl` | `null` | `null` | `ComparisonItemModel.imageUrl` | `null` | 刻意 nullable |
| `ActionChipGroupComponent.chips` | `[]`（isValid 過濾；空則降級） | `null`（過濾移到分派器） | `ActionChipGroupModel.chips` | `const []` | |
| `ActionChipItem.label` | `''` | `null` | `ActionChipModel.label` | `''` | |
| `ActionChipItem.action` | `''` | `null` | `ActionChipModel.action` | `''` | |
| `ActionChipItem.payload` | `const {}` | `null` | `ActionChipModel.payload` | `const {}` | |
| `DecisionRouletteComponent.title` | `A2UIFallbackStrings.decisionRouletteTitle` | `null` | `DecisionRouletteModel.title` | `A2UIFallbackStrings.decisionRouletteTitle` | 分派器降級文字亦補同值 |
| `DecisionRouletteComponent.options` | `[]`（<2 則降級） | `null` | `DecisionRouletteModel.options` | `const []` | |
| `FallbackMarkdownComponent.text` | 無（required，分派器一定給值） | `null` | `FallbackTextModel.text` | `''` | 實務上不會觸發 |
| `AiFoodieMessage.id` | `''` | `null` | —（View 未讀） | — | |
| `AiFoodieMessage.isUser` | `false` | `null` | `AiFoodieMessageModel.isUser` | `false` | |
| `AiFoodieMessage.text` | `''` | `null` | `AiFoodieMessageModel.text` | `''` | |
| `AiFoodieMessage.components` | `[]` | `null` | `AiFoodieMessageModel.components` | `const []` | |
| `AiFoodieMessage.createdAt` | `DateTime.now()` | `null`（`tryParse` 失敗亦 `null`） | —（View 未讀） | — | 見 §7 問題 3 |

---

## 3. 任務總覽與並行判斷

| # | 標題 | 寫入路徑 | 依賴 | 可並行 | 推論等級 |
|---|------|----------|------|--------|----------|
| T1 | 特性測試固定現行行為 | `test/domain/entities/a2ui_characterization_test.dart`（新）、`test/flow/menu_vision/menu_vision_view_characterization_test.dart`（新）、`test/flow/ai_foodie/ai_foodie_view_characterization_test.dart`（新） | — | 三個檔可由不同人同時寫 | 整合 |
| T2 | Menu Vision 改用 UI model | `lib/flow/menu_vision/**`、`test/flow/menu_vision/menu_vision_model_test.dart`（新）、`test/flow/menu_vision/menu_vision_bloc_test.dart`、`test/flow/menu_vision/menu_vision_sheet_test.dart` | T1 | **可與 T3 並行**（寫入不重疊） | 整合 |
| T3 | AI 覓食改用 UI model | `lib/flow/ai_foodie/**`（`decision_roulette_dialog.dart` 除外）、`test/flow/ai_foodie/ai_foodie_model_test.dart`（新）、`test/flow/ai_foodie/ai_foodie_bloc_test.dart` | T1 | **可與 T2、T4a 並行** | 整合 |
| T4a | 葉節點 entity（`AllergenInfo`、`DishItemEntity`）改 `@JsonSerializable` | `lib/domain/entities/entity_json_converters.dart`（新）、`allergen_info.dart`(+`.g.dart`)、`dish_item_entity.dart`(+`.g.dart`)、`lib/flow/menu_vision/model/menu_vision_model.dart`、`test/domain/entities/entity_nullability_test.dart`（新）、`test/domain/menu_vision_entity_test.dart`、`test/data_layer/menu_vision_repo_test.dart` | T2 | 可與 T3 並行（寫入不重疊） | 機械性＋整合 |
| T4b | A2UI 元件 entity 與分派器 | `lib/domain/entities/a2ui_component.dart`(+`.g.dart`)、`lib/data_layer/repositories/ai_foodie_repo.dart`、`lib/flow/menu_vision/bloc/menu_vision_bloc.dart`、`lib/flow/menu_vision/model/menu_vision_model.dart`、`lib/flow/ai_foodie/model/ai_foodie_model.dart`、`test/domain/entities/entity_nullability_test.dart`、`test/domain/entities/a2ui_component_test.dart`、`test/domain/menu_vision_entity_test.dart`、`test/data_layer/ai_foodie_repo_test.dart`、`test/data_layer/menu_vision_repo_test.dart` | T3、T4a | 否 | **設計判斷**（分派器） |
| T4c | `AiFoodieMessage` entity | `lib/domain/entities/ai_foodie_message.dart`(+`.g.dart`)、`lib/data_layer/repositories/ai_foodie_repo.dart`、`lib/flow/ai_foodie/model/ai_foodie_model.dart`、`test/domain/entities/entity_nullability_test.dart`、`test/domain/entities/a2ui_component_test.dart` | T4b | 否 | 整合 |
| T5 | 收尾驗證與 PR 說明素材 | 無程式碼寫入 | T4c | 否 | 機械性 |

寫入重疊：T4a／T4b 都寫 `menu_vision_model.dart`、`menu_vision_entity_test.dart`、`menu_vision_repo_test.dart`、`entity_nullability_test.dart`；T4b／T4c 都寫 `ai_foodie_repo.dart`、`ai_foodie_model.dart`、`entity_nullability_test.dart`、`a2ui_component_test.dart` → 三者必須串行。
關鍵路徑：T1 → T2 → T4a → T4b → T4c → T5（T3 與 T2／T4a 並行，只要在 T4b 之前完成即可）。

**鐵律**：
1. T1 的三個檔在 T2–T5 **禁止修改**。任何一條失敗都代表使用者可見行為改變 → 停下回報，不得改測試。
2. 每個任務結束時：`flutter analyze` 零 issue、`flutter test` 全綠、可以單獨 commit。
3. 每個任務一個 commit（含 `.g.dart`），commit 由使用者授權後才執行。

---

## 4. 任務細節

### T1：特性測試固定現行行為

**目標**：在不動任何 `lib/` 的前提下，把規格 §4.1 與 §4.3 中「現況就成立」的行為寫成測試並全綠。這批測試是後續每一步的回歸網。

**設計原則（讓測試在 T2–T4 期間不需修改）**：
- entity 層測試只用 `expect(x.field, matcher)`、`hasLength`、`isA<T>().having(...)`、`jsonEncode(x.toJson())`；**不寫 `x.list.first`、`x.list.length`**（欄位改 nullable 後會編譯失敗）。
- widget 測試一律走 **Sheet + 真實 BLoC + 假 repo**（repo 回傳 `A2UIComponent.fromJson(json)`／`AiFoodieMessage.fromJson(json)`），這條接縫在整個重構中簽章不變，所以同一份測試能證明「重構前後畫面一樣」。
- 「entity 缺值為 `null`」「`toJson` 省略 null key」是**新行為**，放在 T4 的 `entity_nullability_test.dart`，不放這裡。

**步驟**：
1. 新增 `test/domain/entities/a2ui_characterization_test.dart`（程式碼見下）。
2. 新增 `test/flow/menu_vision/menu_vision_view_characterization_test.dart`（程式碼見下）。
3. 新增 `test/flow/ai_foodie/ai_foodie_view_characterization_test.dart`（程式碼見下）。
4. 執行驗收指令。**若有字串快照不符，以現行程式實際輸出為準修正期望值**（此時 `lib/` 未改，現況就是規格），並在 commit 訊息中記錄。

**驗收**：
```bash
flutter test test/domain/entities/a2ui_characterization_test.dart \
  test/flow/menu_vision/menu_vision_view_characterization_test.dart \
  test/flow/ai_foodie/ai_foodie_view_characterization_test.dart
flutter analyze
flutter test
```

#### T1-1 `test/domain/entities/a2ui_characterization_test.dart`

> **v5.2 追記**：下方程式碼是 T1 當時（`checked: true` 尚未導入）的原始版本，保留供對照。§3「鐵律」1 原則上禁止 T2 之後修改此檔；PR #127 review 過程中導入 `checked: true`（見規格 §7 v5.2）是刻意的例外——`純量型別錯誤拋 TypeError` 群組的期望值改為 `CheckedFromJsonException`／`FormatException`（`isA<Exception>()` 系列），輸入不變，測試名稱同步改為「純量型別錯誤拋 Exception（不拋 TypeError）」。實際最終內容以 `test/domain/entities/a2ui_characterization_test.dart` 為準。

```dart
import 'dart:convert';

import 'package:flutter_restaruant/data_layer/repositories/ai_foodie_repo.dart';
import 'package:flutter_restaruant/domain/entities/a2ui_fallback_strings.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

/// 特性測試：固定 entity 與分派器的現行可觀察行為。
/// T2 之後禁止修改本檔；任何失敗都代表行為改變。
void main() {
  A2UIComponent parse(Map<String, Object?> json) => A2UIComponent.fromJson(json);
  Object? fallbackText(A2UIComponent c) => (c as FallbackMarkdownComponent).text;

  group('toJson 逐字快照（全欄位有值）', () {
    test('AllergenInfo', () {
      expect(jsonEncode(AllergenInfo.fromJson(_Data.allergen).toJson()), _Data.allergenJson);
    });
    test('DishItemEntity', () {
      expect(jsonEncode(DishItemEntity.fromJson(_Data.dish).toJson()), _Data.dishJson);
    });
    test('DishCatalogComponent', () {
      expect(jsonEncode(parse(_Data.catalog).toJson()), _Data.catalogJson);
    });
    test('ComparisonMatrixComponent + RestaurantComparisonItem', () {
      expect(jsonEncode(parse(_Data.matrix).toJson()), _Data.matrixJson);
    });
    test('ActionChipGroupComponent + ActionChipItem', () {
      expect(jsonEncode(parse(_Data.chips).toJson()), _Data.chipsJson);
    });
    test('DecisionRouletteComponent', () {
      expect(jsonEncode(parse(_Data.roulette).toJson()), _Data.rouletteJson);
    });
    test('FallbackMarkdownComponent 扁平格式且 component_type 在第一個', () {
      expect(
        jsonEncode(parse({'component_type': 'mystery', 'text': '降級'}).toJson()),
        '{"component_type":"fallback_markdown","text":"降級"}',
      );
    });
    test('AiFoodieMessage', () {
      expect(jsonEncode(AiFoodieMessage.fromJson(_Data.message).toJson()), _Data.messageJson);
    });
    test('送回 LLM 的 history 字串', () {
      final msg = AiFoodieMessage.fromJson(_Data.message);
      expect(AiFoodieRepo.serializeAssistantHistory(msg), _Data.historyJson);
    });
  });

  group('round-trip（全欄位有值）', () {
    for (final json in [_Data.catalog, _Data.matrix, _Data.chips, _Data.roulette]) {
      test('${json['component_type']}', () {
        final c = parse(json);
        expect(parse(c.toJson()), c);
      });
    }
    test('FallbackMarkdownComponent', () {
      const c = FallbackMarkdownComponent(text: '降級');
      expect(parse(c.toJson()), c);
    });
    test('AiFoodieMessage', () {
      final m = AiFoodieMessage.fromJson(_Data.message);
      expect(AiFoodieMessage.fromJson(m.toJson()), m);
    });
  });

  group('混型 List 靜默過濾', () {
    test('dishes／allergens／dietary_tags／ingredients', () {
      final c = parse({
        'component_type': 'dish_catalog',
        'data': {
          'dishes': [
            {
              'name': 'A',
              'allergens': [{'name': '蛋'}, 'x', 1],
              'dietary_tags': ['t', 1, null],
              'ingredients': ['i', false],
            },
            'str',
            1,
            null,
          ],
        },
      });
      expect(
        c,
        isA<DishCatalogComponent>().having((c) => c.dishes, 'dishes', [
          isA<DishItemEntity>()
              .having((d) => d.allergens, 'allergens', hasLength(1))
              .having((d) => d.dietaryTags, 'dietaryTags', ['t'])
              .having((d) => d.ingredients, 'ingredients', ['i']),
        ]),
      );
    });
    test('items／highlights', () {
      final c = parse({
        'component_type': 'comparison_matrix',
        'data': {
          'items': [
            {'name': 'A', 'highlights': ['h', 2]},
            'x',
          ],
        },
      });
      expect(
        c,
        isA<ComparisonMatrixComponent>().having((c) => c.items, 'items', [
          isA<RestaurantComparisonItem>().having((i) => i.highlights, 'highlights', ['h']),
        ]),
      );
    });
    test('chips', () {
      final c = parse({
        'component_type': 'action_chip_group',
        'data': {
          'chips': [
            {'label': 'L', 'action': 'custom'},
            3,
            'x',
          ],
        },
      });
      expect(c, isA<ActionChipGroupComponent>().having((c) => c.chips, 'chips', hasLength(1)));
    });
    test('options', () {
      final c = parse({
        'component_type': 'decision_roulette',
        'data': {'options': ['A', 3, 'B', null]},
      });
      expect(c, isA<DecisionRouletteComponent>().having((c) => c.options, 'options', ['A', 'B']));
    });
    test('message.components', () {
      final m = AiFoodieMessage.fromJson({'components': [_Data.roulette, 'x', 1]});
      expect(m.components, hasLength(1));
    });
  });

  group('分派器降級', () {
    test('dish_catalog：data 缺值 → dishCatalogEmpty', () {
      expect(fallbackText(parse({'component_type': 'dish_catalog'})), A2UIFallbackStrings.dishCatalogEmpty);
    });
    test('dish_catalog：dishes 空 → restaurant_title', () {
      final c = parse({'component_type': 'dish_catalog', 'data': {'restaurant_title': '店', 'dishes': <Object?>[]}});
      expect(fallbackText(c), '店');
    });
    test('dish_catalog：text 優先於 restaurant_title', () {
      final c = parse({'component_type': 'dish_catalog', 'text': 'T', 'data': {'restaurant_title': '店'}});
      expect(fallbackText(c), 'T');
    });
    test('dish_catalog：dishes 全為非 Map → 降級', () {
      final c = parse({'component_type': 'dish_catalog', 'data': {'dishes': ['x', 1]}});
      expect(c, isA<FallbackMarkdownComponent>());
    });
    test('comparison_matrix：items 與 title 皆缺 → comparisonMatrixTitle', () {
      expect(fallbackText(parse({'component_type': 'comparison_matrix'})), A2UIFallbackStrings.comparisonMatrixTitle);
    });
    test('comparison_matrix：items 空 → title', () {
      final c = parse({'component_type': 'comparison_matrix', 'data': {'title': 'X', 'items': <Object?>[]}});
      expect(fallbackText(c), 'X');
    });
    test('action_chip_group：chips 缺值 → actionChipGroupTitle', () {
      expect(fallbackText(parse({'component_type': 'action_chip_group'})), A2UIFallbackStrings.actionChipGroupTitle);
    });
    test('action_chip_group：chips 全不合法 → 降級', () {
      final c = parse({
        'component_type': 'action_chip_group',
        'data': {
          'chips': [
            {'label': '  ', 'action': 'query', 'payload': {'prompt': 'p'}},
            {'label': 'L'},
            {'label': 'L', 'action': 'query'},
            {'label': 'L', 'action': 'open_roulette', 'payload': {'options': ['A']}},
            {'label': 'L', 'action': 'open_roulette', 'payload': {'options': [' ', 'A']}},
          ],
        },
      });
      expect(c, isA<FallbackMarkdownComponent>());
    });
    test('action_chip_group：部分合法只保留合法', () {
      final c = parse({
        'component_type': 'action_chip_group',
        'data': {
          'chips': [
            {'label': '無效', 'action': 'query', 'payload': <String, Object?>{}},
            {'label': '有效', 'action': 'query', 'payload': {'prompt': 'p'}},
          ],
        },
      });
      expect(
        c,
        isA<ActionChipGroupComponent>().having((c) => c.chips, 'chips', [
          isA<ActionChipItem>().having((i) => i.label, 'label', '有效'),
        ]),
      );
    });
    test('action_chip_group：未知 action 且無 payload 視為合法', () {
      final c = parse({'component_type': 'action_chip_group', 'data': {'chips': [{'label': 'L', 'action': 'custom'}]}});
      expect(c, isA<ActionChipGroupComponent>());
    });
    test('decision_roulette：options 缺值 → decisionRouletteTitle', () {
      expect(fallbackText(parse({'component_type': 'decision_roulette'})), A2UIFallbackStrings.decisionRouletteTitle);
    });
    test('decision_roulette：options 少於 2 → title', () {
      final c = parse({'component_type': 'decision_roulette', 'data': {'title': 'T', 'options': ['A']}});
      expect(fallbackText(c), 'T');
    });
    test('未知 type → unknownComponent；有 text 用 text；缺 component_type 亦降級', () {
      expect(fallbackText(parse({'component_type': 'zzz'})), A2UIFallbackStrings.unknownComponent);
      expect(fallbackText(parse({'component_type': 'zzz', 'text': 'T'})), 'T');
      expect(fallbackText(parse(const {})), A2UIFallbackStrings.unknownComponent);
    });
    test('合法元件不讀 text：text 型別錯誤也不拋', () {
      final c = parse({'component_type': 'decision_roulette', 'text': 123, 'data': {'options': ['A', 'B']}});
      expect(c, isA<DecisionRouletteComponent>());
    });
  });

  group('enum 容錯', () {
    test('risk_level', () {
      AllergenRiskLevel? risk(String v) => AllergenInfo.fromJson({'risk_level': v}).riskLevel;
      expect(risk('CONTAINS'), AllergenRiskLevel.contains);
      expect(risk('may_contain'), AllergenRiskLevel.mayContain);
      expect(risk('maycontain'), AllergenRiskLevel.mayContain);
      expect(risk('MayContain'), AllergenRiskLevel.mayContain);
      expect(risk('unknown'), AllergenRiskLevel.none);
    });
    test('category', () {
      expect(DishItemEntity.fromJson({'category': 'Dessert'}).category, DishCategory.dessert);
      expect(DishItemEntity.fromJson({'category': 'xyz'}).category, DishCategory.other);
    });
  });

  group('數值轉換', () {
    test('int → double；spice_level 2.7 → 2', () {
      final d = DishItemEntity.fromJson({'price': 280, 'spice_level': 2.7, 'chef_recommendation_score': 1});
      expect(d.price, isA<double>());
      expect(d.price, 280.0);
      expect(d.spiceLevel, 2);
      expect(d.chefRecommendationScore, 1.0);
      final c = parse({'component_type': 'comparison_matrix', 'data': {'items': [{'rating': 4}]}});
      expect(c, isA<ComparisonMatrixComponent>().having((c) => c.items, 'items', [
        isA<RestaurantComparisonItem>().having((i) => i.rating, 'rating', 4.0),
      ]));
    });
  });

  group('純量型別錯誤拋 TypeError', () {
    final cases = <String, void Function()>{
      'dish.name': () => DishItemEntity.fromJson({'name': 123}),
      'allergen.risk_level': () => AllergenInfo.fromJson({'risk_level': 1}),
      'catalog.restaurant_title': () => parse({'component_type': 'dish_catalog', 'data': {'restaurant_title': 1}}),
      'catalog.dishes 非 List': () => parse({'component_type': 'dish_catalog', 'data': {'dishes': 'x'}}),
      'item.name': () => parse({'component_type': 'comparison_matrix', 'data': {'items': [{'name': 1}]}}),
      'chip.label': () => parse({'component_type': 'action_chip_group', 'data': {'chips': [{'label': 1}]}}),
      'data 非 Map': () => parse({'component_type': 'dish_catalog', 'data': 'x'}),
      'message.created_at': () => AiFoodieMessage.fromJson({'created_at': 5}),
    };
    cases.forEach((name, body) {
      test(name, () => expect(body, throwsA(isA<TypeError>())));
    });
  });
}

class _Data {
  static const Map<String, Object?> allergen = {'name': '花生', 'risk_level': 'may_contain', 'note': '產線共用'};
  static const allergenJson = '{"name":"花生","risk_level":"mayContain","note":"產線共用"}';

  static const Map<String, Object?> dish = {
    'id': 'd1',
    'name': '豚骨拉麵',
    'original_name': 'とんこつラーメン',
    'price': 280,
    'category': 'MAIN',
    'allergens': [allergen],
    'dietary_tags': ['招牌'],
    'spice_level': 2.7,
    'ingredients': ['叉燒', '糖心蛋'],
    'chef_recommendation_score': 1,
  };
  static const dishJson =
      '{"id":"d1","name":"豚骨拉麵","original_name":"とんこつラーメン","price":280.0,"category":"main",'
      '"allergens":[$allergenJson],"dietary_tags":["招牌"],"spice_level":2,"ingredients":["叉燒","糖心蛋"],'
      '"chef_recommendation_score":1.0}';

  static const Map<String, Object?> catalog = {
    'component_type': 'dish_catalog',
    'data': {'restaurant_title': '一風堂', 'currency': 'JPY', 'dishes': [dish]},
  };
  static const catalogJson =
      '{"component_type":"dish_catalog","data":{"restaurant_title":"一風堂","currency":"JPY","dishes":[$dishJson]}}';

  static const Map<String, Object?> matrix = {
    'component_type': 'comparison_matrix',
    'data': {
      'title': '精選對比',
      'items': [
        {
          'id': 'r1',
          'name': '野武士',
          'rating': 4,
          'price': '\$550',
          'highlights': ['串燒', '包廂', '深夜'],
          'address': '台北市中山區',
          'category': '日式',
          'image_url': 'https://img/1.jpg',
        },
      ],
    },
  };
  static const matrixJson =
      '{"component_type":"comparison_matrix","data":{"title":"精選對比","items":[{"id":"r1","name":"野武士",'
      '"rating":4.0,"price":"\$550","highlights":["串燒","包廂","深夜"],"address":"台北市中山區",'
      '"category":"日式","image_url":"https://img/1.jpg"}]}}';

  static const Map<String, Object?> chips = {
    'component_type': 'action_chip_group',
    'data': {
      'chips': [
        {'label': '找宵夜', 'action': 'query', 'payload': {'prompt': '深夜拉麵'}},
        {'label': '轉盤', 'action': 'open_roulette', 'payload': {'title': '抽', 'options': ['A', 'B']}},
      ],
    },
  };
  static const chipsJson =
      '{"component_type":"action_chip_group","data":{"chips":[{"label":"找宵夜","action":"query",'
      '"payload":{"prompt":"深夜拉麵"}},{"label":"轉盤","action":"open_roulette",'
      '"payload":{"title":"抽","options":["A","B"]}}]}}';

  static const Map<String, Object?> roulette = {
    'component_type': 'decision_roulette',
    'data': {'title': '今晚吃啥', 'options': ['A', 'B']},
  };
  static const rouletteJson = '{"component_type":"decision_roulette","data":{"title":"今晚吃啥","options":["A","B"]}}';

  static const Map<String, Object?> message = {
    'id': 'm1',
    'is_user': false,
    'text': '推薦如下',
    'components': [matrix, roulette, {'component_type': 'mystery', 'text': '降級'}],
    'created_at': '2026-09-24T12:00:00.000',
  };
  static const messageJson =
      '{"id":"m1","is_user":false,"text":"推薦如下","components":[$matrixJson,$rouletteJson,'
      '{"component_type":"fallback_markdown","text":"降級"}],"created_at":"2026-09-24T12:00:00.000"}';
  static const historyJson = '{"text":"推薦如下","components":[$matrixJson,$rouletteJson]}';
}
```

#### T1-2 `test/flow/menu_vision/menu_vision_view_characterization_test.dart`

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_restaruant/domain/domain_barrel.dart';
import 'package:flutter_restaruant/domain/entities/a2ui_fallback_strings.dart';
import 'package:flutter_restaruant/flow/menu_vision/menu_vision_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

/// 特性測試：Menu Vision 畫面在「全缺值／全有值」下的顯示。T2 之後禁止修改。
class _FakeRepo implements MenuVisionRepository {
  _FakeRepo(this.data);
  final Map<String, Object?> data;

  @override
  Future<Uint8List?> captureImage() async => Uint8List.fromList([1]);
  @override
  Future<Uint8List?> pickImageFromGallery() async => Uint8List.fromList([1]);
  @override
  Future<A2UIComponent?> captureAndAnalyzeMenu() async => null;
  @override
  Future<A2UIComponent?> pickFromGalleryAndAnalyzeMenu() async => null;
  @override
  Future<A2UIComponent> analyzeMenuImageBytes(Uint8List imageBytes) async =>
      A2UIComponent.fromJson({'component_type': 'dish_catalog', 'data': data});
}

Future<void> _pumpCatalog(WidgetTester tester, Map<String, Object?> data) async {
  final bloc = MenuVisionBloc(repository: _FakeRepo(data));
  addTearDown(bloc.close);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: MenuVisionSheet(bloc: bloc))));
  await tester.tap(find.byKey(const Key('take_photo_button')));
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump();
}

void main() {
  setUpAll(() async => S.load(const Locale('zh', 'TW')));

  testWidgets('全欄位有值', (tester) async {
    await _pumpCatalog(tester, {
      'restaurant_title': '一風堂',
      'currency': 'JPY',
      'dishes': [
        {
          'id': 'd1',
          'name': '豚骨拉麵',
          'original_name': 'とんこつラーメン',
          'price': 280,
          'category': 'main',
          'allergens': [
            {'name': '蛋', 'risk_level': 'contains', 'note': 'n'},
            {'name': '花生', 'risk_level': 'may_contain', 'note': 'n'},
            {'name': '芝麻', 'risk_level': 'none', 'note': 'n'},
          ],
          'dietary_tags': ['招牌'],
          'spice_level': 2,
          'ingredients': ['叉燒', '糖心蛋'],
          'chef_recommendation_score': 0.9,
        },
      ],
    });
    expect(find.text('全部 (1)'), findsOneWidget);
    expect(find.text('主食 (1)'), findsOneWidget);
    expect(find.text('豚骨拉麵'), findsOneWidget);
    expect(find.text('とんこつラーメン'), findsOneWidget);
    expect(find.text('¥280'), findsOneWidget);
    expect(find.text('🌶️🌶️'), findsOneWidget);
    expect(find.text('主要食材：叉燒、糖心蛋'), findsOneWidget);
    expect(find.text('蛋 (含)'), findsOneWidget);
    expect(find.text('花生 (可能含有)'), findsOneWidget);
    expect(find.textContaining('芝麻'), findsNothing);
    expect(find.text('招牌'), findsOneWidget);
  });

  testWidgets('全欄位缺值', (tester) async {
    await _pumpCatalog(tester, {
      'dishes': [<String, Object?>{}],
    });
    expect(find.text('全部 (1)'), findsOneWidget);
    expect(find.text('其他 (1)'), findsOneWidget);
    expect(find.textContaining('NT\$'), findsNothing);
    expect(find.text(S.current.dish_card_spice_level_prefix), findsNothing);
    expect(find.textContaining(S.current.dish_card_ingredients_prefix), findsNothing);
    expect(find.byType(Chip), findsNothing);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    expect(find.byIcon(Icons.help_outline_rounded), findsNothing);
  });

  testWidgets('currency 缺值 → TWD；小數價格', (tester) async {
    await _pumpCatalog(tester, {
      'dishes': [
        {'name': 'A', 'price': 60},
        {'name': 'B', 'price': 60.5},
      ],
    });
    expect(find.text('NT\$60'), findsOneWidget);
    expect(find.text('NT\$60.50'), findsOneWidget);
  });

  testWidgets('allergen：缺 name 顯示空名；缺 risk_level 視為 none 不顯示', (tester) async {
    await _pumpCatalog(tester, {
      'dishes': [
        {
          'name': 'A',
          'allergens': [
            {'risk_level': 'contains'},
            {'name': '花生'},
          ],
        },
      ],
    });
    expect(find.text(' (含)'), findsOneWidget);
    expect(find.textContaining('花生'), findsNothing);
  });

  testWidgets('category 缺值與未知值都歸到其他', (tester) async {
    await _pumpCatalog(tester, {
      'dishes': [
        {'name': 'A'},
        {'name': 'B', 'category': 'xyz'},
      ],
    });
    expect(find.text('其他 (2)'), findsOneWidget);
  });

  testWidgets('dishes 缺值 → 失敗畫面顯示降級文字', (tester) async {
    await _pumpCatalog(tester, const {});
    expect(find.text(S.current.menu_vision_failure_title), findsOneWidget);
    expect(find.text(A2UIFallbackStrings.dishCatalogEmpty), findsOneWidget);
  });
}
```

#### T1-3 `test/flow/ai_foodie/ai_foodie_view_characterization_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_restaruant/domain/domain_barrel.dart';
import 'package:flutter_restaruant/domain/entities/a2ui_fallback_strings.dart';
import 'package:flutter_restaruant/features/utils/utils_barrel.dart';
import 'package:flutter_restaruant/flow/ai_foodie/ai_foodie_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

/// 特性測試：AI 覓食畫布在「全缺值／全有值」下的顯示與互動。T2 之後禁止修改。
class _FakeRepo implements AiFoodieRepository {
  _FakeRepo(this.initial);
  final List<AiFoodieMessage> initial;
  List<AiFoodieMessage>? lastHistory;

  @override
  Future<List<AiFoodieMessage>> getInitialSuggestions() async => initial;

  @override
  Future<AiFoodieMessage> askAssistant(
    String prompt, {
    List<AiFoodieMessage>? history,
    List<RestaurantEntity>? candidateRestaurants,
  }) async {
    lastHistory = history;
    return AiFoodieMessage.assistant(text: '回覆：$prompt');
  }
}

class _Harness {
  _Harness(this.repo);
  final _FakeRepo repo;
  final routeArgs = <Object?>[];
}

Future<_Harness> _pump(WidgetTester tester, Map<String, Object?> messageJson) async {
  await tester.binding.setSurfaceSize(const Size(800, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final h = _Harness(_FakeRepo([AiFoodieMessage.fromJson(messageJson)]));
  final bloc = AiFoodieBloc(repository: h.repo);
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale('zh', 'TW'),
      onGenerateRoute: (settings) {
        h.routeArgs.add(settings.arguments);
        return MaterialPageRoute<void>(builder: (_) => const SizedBox());
      },
      home: Scaffold(body: AiFoodieSheet(bloc: bloc)),
    ),
  );
  await tester.pump();
  await tester.pump();
  return h;
}

RestaurantEntity _navigated(_Harness h) =>
    (h.routeArgs.last as Tuple2<RestaurantEntity, dynamic>).item1;

class _Data {
  static const Map<String, Object?> full = {
    'id': 'm1',
    'is_user': false,
    'text': '推薦如下',
    'created_at': '2026-09-24T12:00:00.000',
    'components': [
      {
        'component_type': 'comparison_matrix',
        'data': {
          'title': '精選對比',
          'items': [
            {
              'id': 'r1',
              'name': '野武士',
              'rating': 4,
              'price': '\$550',
              'highlights': ['串燒', '包廂', '深夜'],
              'address': '台北市中山區',
              'category': '日式',
              'image_url': 'https://img/1.jpg',
            },
          ],
        },
      },
      {
        'component_type': 'action_chip_group',
        'data': {
          'chips': [
            {'label': '找宵夜', 'action': 'query', 'payload': {'prompt': '深夜拉麵'}},
          ],
        },
      },
      {
        'component_type': 'decision_roulette',
        'data': {'title': '今晚吃啥', 'options': ['A', 'B']},
      },
      {'component_type': 'mystery', 'text': '降級文字'},
    ],
  };

  static const Map<String, Object?> missing = {
    'components': [
      {
        'component_type': 'comparison_matrix',
        'data': {'items': [<String, Object?>{}]},
      },
      {
        'component_type': 'action_chip_group',
        'data': {
          'chips': [
            {'label': '只有標籤', 'action': 'custom'},
          ],
        },
      },
      {
        'component_type': 'decision_roulette',
        'data': {'options': ['A', 'B']},
      },
      {'component_type': 'mystery'},
    ],
  };
}

void main() {
  setUpAll(() async => S.load(const Locale('zh', 'TW')));

  group('全欄位有值', () {
    testWidgets('顯示', (tester) async {
      await _pump(tester, _Data.full);
      expect(find.text('推薦如下'), findsOneWidget);
      expect(find.text('精選對比'), findsOneWidget);
      expect(find.text('野武士'), findsOneWidget);
      expect(find.text('4.0'), findsOneWidget);
      expect(find.text('日式'), findsOneWidget);
      expect(find.text('\$550'), findsOneWidget);
      expect(find.text('串燒'), findsOneWidget);
      expect(find.text('包廂'), findsOneWidget);
      expect(find.text('深夜'), findsNothing);
      expect(find.text('台北市中山區'), findsOneWidget);
      expect(find.text('找宵夜'), findsOneWidget);
      expect(find.text('今晚吃啥'), findsOneWidget);
      expect(find.text('降級文字'), findsOneWidget);
    });

    testWidgets('點比較卡片 → 導航參數', (tester) async {
      final h = await _pump(tester, _Data.full);
      await tester.tap(find.text('野武士'));
      await tester.pump();
      final e = _navigated(h);
      expect(e.id, 'r1');
      expect(e.name, '野武士');
      expect(e.rating, 4.0);
      expect(e.price, '\$550');
      expect(e.imageUrl, 'https://img/1.jpg');
      expect(e.location?.address1, '台北市中山區');
    });

    testWidgets('點 query chip → 送出 prompt，history 為 entity', (tester) async {
      final h = await _pump(tester, _Data.full);
      await tester.tap(find.text('找宵夜'));
      await tester.pump();
      await tester.pump();
      expect(find.text('深夜拉麵'), findsOneWidget);
      // history 是送出前的 state.messages（entity），與重新解析的同一份 JSON 相等
      expect(h.repo.lastHistory, [AiFoodieMessage.fromJson(_Data.full)]);
    });

    testWidgets('點轉盤按鈕 → 開啟轉盤並帶標題', (tester) async {
      await _pump(tester, _Data.full);
      await tester.tap(find.text('今晚吃啥'));
      await tester.pump();
      await tester.pump();
      expect(find.text('今晚吃啥'), findsNWidgets(2));
    });
  });

  group('全欄位缺值', () {
    testWidgets('顯示', (tester) async {
      await _pump(tester, _Data.missing);
      expect(find.text(A2UIFallbackStrings.comparisonMatrixTitle), findsOneWidget);
      expect(find.text(A2UIFallbackStrings.comparisonItemName), findsOneWidget);
      expect(find.text('0.0'), findsOneWidget);
      expect(find.text('只有標籤'), findsOneWidget);
      expect(find.text(A2UIFallbackStrings.decisionRouletteTitle), findsOneWidget);
      expect(find.text(A2UIFallbackStrings.unknownComponent), findsOneWidget);
      // 缺 is_user → 助理訊息：header 與訊息頭像各一個 auto_awesome
      expect(find.byIcon(Icons.auto_awesome), findsNWidgets(2));
    });

    testWidgets('點比較卡片 → 導航參數', (tester) async {
      final h = await _pump(tester, _Data.missing);
      await tester.tap(find.text(A2UIFallbackStrings.comparisonItemName));
      await tester.pump();
      final e = _navigated(h);
      expect(e.id, '');
      expect(e.name, A2UIFallbackStrings.comparisonItemName);
      expect(e.rating, 0.0);
      expect(e.price, isNull);
      expect(e.imageUrl, isNull);
      expect(e.location, isNull);
    });

    testWidgets('點轉盤按鈕 → 轉盤標題為預設', (tester) async {
      await _pump(tester, _Data.missing);
      await tester.tap(find.text(A2UIFallbackStrings.decisionRouletteTitle));
      await tester.pump();
      await tester.pump();
      expect(find.text(A2UIFallbackStrings.decisionRouletteTitle), findsNWidgets(2));
    });

    testWidgets('點未知 action chip → 無動作', (tester) async {
      final h = await _pump(tester, _Data.missing);
      await tester.tap(find.text('只有標籤'));
      await tester.pump();
      expect(h.repo.lastHistory, isNull);
    });
  });
}
```

> 若 `find.byIcon(Icons.auto_awesome)` 數量因 widget 樹實際結構不同而不符，以現況實測值為準修正（T1 期間 `lib/` 未改）。

---

### T2：Menu Vision 改用 UI model

**目標**：新增 `menu_vision_model.dart`；`MenuVisionSuccess` 持 `DishCatalogModel`；三個 View 只讀 UI model、不 import `domain/`（repository 介面除外，見步驟 6）。entity 此時仍 non-null，`fromEntity` 是純欄位複製。

**先寫的測試**：`test/flow/menu_vision/menu_vision_model_test.dart`（新）
```dart
void main() {
  test('fromEntity：全缺值 → UI 預設值', () {
    final m = DishModel.fromEntity(DishItemEntity.fromJson(const {}));
    expect(m, const DishModel(
      name: '', originalName: '', price: 0.0, category: DishCategory.other,
      allergens: [], dietaryTags: [], spiceLevel: 0, ingredients: [],
    ));
    expect(AllergenModel.fromEntity(AllergenInfo.fromJson(const {})),
        const AllergenModel(name: '', riskLevel: AllergenRiskLevel.none));
    final c = DishCatalogModel.fromEntity(
      A2UIComponent.fromJson({'component_type': 'dish_catalog', 'data': {'dishes': [{}]}}) as DishCatalogComponent,
    );
    expect(c.currency, 'TWD');
    expect(c.dishes, hasLength(1));
  });
  test('fromEntity：全有值 → 原值', () { /* 以 T1 的 _Data.dish 等值 JSON 建 entity，逐欄比對 */ });
}
```
（此測試在 T2 通過是因為 entity 目前還在給預設；T4 把預設搬到 `fromEntity` 後，這份測試**不改**也必須繼續通過——它就是「搬家沒搬錯」的證明。）

**步驟**：
1. 寫 `menu_vision_model_test.dart` → 執行，確認因類別不存在而失敗。
2. 新增 `lib/flow/menu_vision/model/menu_vision_model.dart`（§2.3 結構，`fromEntity` 直接複製欄位；`export … show AllergenRiskLevel` / `show DishCategory`）；`menu_vision_barrel.dart` 加 `export 'model/menu_vision_model.dart';`。
3. `menu_vision_state.dart`：`MenuVisionSuccess.catalog` 型別改 `DishCatalogModel`；`menu_vision_bloc.dart` import model 檔，兩處 `MenuVisionSuccess(catalog: DishCatalogModel.fromEntity(result))`。
4. `allergen_badge.dart`：`final AllergenModel allergen;`，import 改為 `../model/menu_vision_model.dart`。
5. `dish_card.dart`：`final DishModel dish;`；`significantAllergens` 改讀 `AllergenModel`；import 同上。
6. `menu_vision_sheet.dart`：`_CatalogContentView.catalog` 改 `DishCatalogModel`；`import '../../../domain/domain_barrel.dart'` 改為 `import '../../../domain/repositories/menu_vision_repository.dart'`（只為 `GetIt.I<MenuVisionRepository>()`）＋ model 檔。
7. 調整既有測試（僅型別）：
   - `menu_vision_bloc_test.dart`：期望狀態 `MenuVisionSuccess(catalog: DishCatalogModel.fromEntity(sampleCatalog))`（4 處含 `seed`）。
   - `menu_vision_sheet_test.dart`：`AllergenBadge(allergen: AllergenModel(name: '海鮮', riskLevel: AllergenRiskLevel.contains))`、`DishCard(dish: DishModel.fromEntity(sampleDish), …)`。
8. `dart format lib/flow/menu_vision test/flow/menu_vision`。

**驗收**：
```bash
flutter test test/flow/menu_vision/
flutter test test/domain/entities/a2ui_characterization_test.dart
rtk proxy grep -rn "domain/" lib/flow/menu_vision/view   # 期望：只有 domain/repositories/menu_vision_repository.dart
flutter analyze && flutter test
```
**回滾點**：單一 commit，`git revert` 即回到 T1 狀態。

---

### T3：AI 覓食改用 UI model（可與 T2／T4a 並行）

**目標**：新增 `ai_foodie_model.dart`；`AiFoodieState` 增 `messageModels`（由 `copyWith` 衍生）；`TriggerActionChip` 帶 `ActionChipModel`；三個 View 只讀 UI model。

**先寫的測試**：
1. `test/flow/ai_foodie/ai_foodie_model_test.dart`（新）：
   - `AiFoodieMessageModel.fromEntity(AiFoodieMessage.fromJson(const {}))` → `isUser: false, text: '', components: []`。
   - 全缺值 matrix／item／chip／roulette → §2.5 表中的 UI 預設（`A2UIFallbackStrings.*`、`0.0`、`''`、`price == null` 等）。
   - `A2UIComponentModel.fromEntity(DishCatalogComponent)` → `null`；訊息轉換時被 `.nonNulls` 略過。
   - Fallback → `FallbackTextModel(text: …)`。
2. `ai_foodie_bloc_test.dart` 新增：
   - `messageModels` 與 `messages` 同步：`LoadInitialSuggestions` 後 `state.messageModels.single.text == state.messages.single.text`。
   - **history 是 entity**：mock 記錄 `askAssistant` 收到的 `history`，`SendUserPrompt` 後斷言 `history` 等於送出前的 `state.messages`（`List<AiFoodieMessage>`）。

**步驟**：
1. 寫上面兩組測試 → 執行確認失敗。
2. 新增 `lib/flow/ai_foodie/model/ai_foodie_model.dart`（§2.4；`import '../../../domain/entities/entities_barrel.dart'` 與 `a2ui_fallback_strings.dart`；`fromEntity` 直接複製欄位，唯一邏輯是 `DishCatalogComponent() => null` 與 `.nonNulls`）；`ai_foodie_barrel.dart` 加 export。
3. `ai_foodie_state.dart`：新增 `messageModels` 欄位與 `props`；`copyWith` 內 `messageModels: messages == null ? this.messageModels : messages.map(AiFoodieMessageModel.fromEntity).toList(growable: false)`。
4. `ai_foodie_event.dart`：`TriggerActionChip(this.chip)` 的 `chip` 型別改 `ActionChipModel`，import model 檔。`ai_foodie_bloc.dart` 加 import，邏輯不動。
5. `action_chip_group_widget.dart`：`component: ActionChipGroupModel`、`onChipTap: void Function(ActionChipModel)`；import 改 model 檔。
6. `comparison_matrix_card.dart`：`component: ComparisonMatrixModel`、`onRestaurantTap: void Function(ComparisonItemModel)?`；`_ComparisonItemCard.item: ComparisonItemModel`；`if (item.category != null) …[Text(item.category!)…]` 改為 `if (item.category case final category?) …[Text(category)…]`，`price`、`address` 同理（渲染樹不變、消滅 `!`）。
7. `ai_foodie_sheet.dart`：
   - `itemCount`／`itemBuilder` 改讀 `state.messageModels`；`_MessageItem.message: AiFoodieMessageModel`。
   - `switch (comp)` 改窮盡 `ComparisonMatrixModel／ActionChipGroupModel／DecisionRouletteModel／FallbackTextModel`，刪除 `_ =>`。
   - 轉盤按鈕改建 `ActionChipModel`。
   - `_navigateToRestaurantDetail(ComparisonItemModel item)`，欄位對應不變。
   - import：`domain/entities/entities_barrel.dart` 改為 `import '../../../domain/entities/entities_barrel.dart' show RestaurantEntity, RestaurantLocationEntity;`（導航參數與 `candidateRestaurants` 需要，屬範圍外 entity，見 §7 問題 1）。
8. `ai_foodie_bloc_test.dart`：`TriggerActionChip` 測試改用 `const ActionChipModel(label: …, action: 'query', payload: {'prompt': …})`。
9. `dart format lib/flow/ai_foodie test/flow/ai_foodie`。

**驗收**：
```bash
flutter test test/flow/ai_foodie/
flutter test test/domain/entities/a2ui_characterization_test.dart
rtk proxy grep -rn "domain/" lib/flow/ai_foodie/view   # 期望：只有 entities_barrel show RestaurantEntity, RestaurantLocationEntity 與 repositories/ai_foodie_repository.dart
flutter analyze && flutter test
```
**回滾點**：單一 commit。

---

### T4a：葉節點 entity（`AllergenInfo`、`DishItemEntity`）

**目標**：兩個 entity 改 `@JsonSerializable`、欄位 nullable、無預設值；預設值在**同一 commit** 搬進 `DishModel.fromEntity`／`AllergenModel.fromEntity`。

**先寫的測試**：`test/domain/entities/entity_nullability_test.dart`（新）
```dart
group('AllergenInfo / DishItemEntity', () {
  test('缺值 → 欄位為 null（含 List 與 enum）', () {
    final a = AllergenInfo.fromJson(const {});
    expect([a.name, a.riskLevel, a.note], everyElement(isNull));
    final d = DishItemEntity.fromJson(const {});
    expect([d.id, d.name, d.originalName, d.price, d.category, d.allergens,
            d.dietaryTags, d.spiceLevel, d.ingredients, d.chefRecommendationScore],
        everyElement(isNull));
  });
  test('toJson 省略 null key，且不含 props/stringify/hashCode', () {
    expect(const AllergenInfo(name: '蛋').toJson(), {'name': '蛋'});
    expect(const DishItemEntity(name: 'A').toJson(), {'name': 'A'});
    expect(jsonEncode(const DishItemEntity().toJson()), '{}');
  });
});
```
執行 → 失敗（現行給預設值）。

**步驟**：
1. 新增 `lib/domain/entities/entity_json_converters.dart`：
   ```dart
   /// 手寫 `whereType` 語意：null 維持 null，型別不符的元素靜默丟棄。
   List<String>? stringListFromJson(List<Object?>? raw) =>
       raw?.whereType<String>().toList(growable: false);

   List<T>? mapListFromJson<T>(
     List<Object?>? raw,
     T Function(Map<String, Object?> json) fromJson,
   ) => raw?.whereType<Map<String, Object?>>().map(fromJson).toList(growable: false);
   ```
2. `allergen_info.dart`：
   ```dart
   part 'allergen_info.g.dart';

   @immutable
   @JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
   class AllergenInfo extends Equatable {
     const AllergenInfo({this.name, this.riskLevel, this.note});
     factory AllergenInfo.fromJson(Map<String, Object?> json) => _$AllergenInfoFromJson(json);

     final String? name;
     @JsonKey(fromJson: _riskLevelFromJson)
     final AllergenRiskLevel? riskLevel;
     final String? note;

     Map<String, Object?> toJson() => _$AllergenInfoToJson(this);
     @override
     List<Object?> get props => [name, riskLevel, note];
   }

   AllergenRiskLevel? _riskLevelFromJson(String? value) =>
       value == null ? null : AllergenRiskLevel.fromString(value);
   ```
3. `dish_item_entity.dart`：同樣模式，`explicitToJson: true`；欄位宣告順序**不動**；`category` 用 `_categoryFromJson(String?)`；`allergens` 用 `_allergensFromJson(List<Object?>? raw) => mapListFromJson(raw, AllergenInfo.fromJson)`；`dietaryTags`／`ingredients` 用 `stringListFromJson`；`price`／`spiceLevel`／`chefRecommendationScore` 不需轉換器。
4. `dart run build_runner build --delete-conflicting-outputs`。
5. `menu_vision_model.dart`：`DishModel.fromEntity` 與 `AllergenModel.fromEntity` 加上 §2.5 的 `??`（`name ?? ''`、`price ?? 0.0`、`category ?? DishCategory.other`、`(allergens ?? const []).map(...)`、`riskLevel ?? AllergenRiskLevel.none` …）。
6. 調整既有測試（只為型別／新語意，逐條記入 PR 說明）：
   - `test/domain/menu_vision_entity_test.dart`：`'DishItemEntity handles nulls…'` 的 `''`／`0.0`／`other`／`isEmpty` 期望改為 `isNull`（**語意變更**，規格 §4.2）；`dish.allergens.length`／`.first` 改 `hasLength(1)`／`dish.allergens?.first`。
   - `test/data_layer/menu_vision_repo_test.dart`：`dish.allergens.length`／`.first.riskLevel` 同上改寫。
7. `dart format`。

**驗收**：
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/domain/ test/flow/menu_vision/ test/data_layer/menu_vision_repo_test.dart
flutter analyze && flutter test
```
**T1 特性測試必須不改一字全綠**；`menu_vision_model_test.dart` 必須不改全綠。
**若 `spice_level: 2.7` 特性測試失敗**（產生器未輸出 `toInt()`）：補 `@JsonKey(fromJson: _intFromJson)`，`int? _intFromJson(num? v) => v?.toInt();`。
**回滾點**：單一 commit（含 `.g.dart`）。

---

### T4b：A2UI 元件 entity 與分派器

**目標**：`DishCatalogComponent`、`ComparisonMatrixComponent`、`RestaurantComparisonItem`、`ActionChipGroupComponent`、`ActionChipItem`、`DecisionRouletteComponent`、`FallbackMarkdownComponent` 改 `@JsonSerializable`、nullable；分派器接受 null 並接手 `isValid` 過濾；預設值搬進兩個 model 檔。

**先寫的測試**（加到 `entity_nullability_test.dart`）：
- 7 個類別 `fromJson(const {})` 後欄位全為 `null`（元件透過各自 `XComponent.fromJson(data)` 直接呼叫，不經分派器）。
- `toJson` 省略 null：`const DecisionRouletteComponent(options: ['A', 'B']).toJson()` 等於 `{'component_type': 'decision_roulette', 'data': {'options': ['A', 'B']}}`；`const ActionChipItem(label: 'L').toJson()` 等於 `{'label': 'L'}`（不含 `isValid`）；`const FallbackMarkdownComponent().toJson()` 等於 `{'component_type': 'fallback_markdown'}`。
- `ActionChipGroupComponent.fromJson` 不再過濾（`chips` 含不合法項也保留），過濾只發生在分派器。
- `ActionChipItem(label: null, action: 'query')`／`(label: 'L', action: null)`／`(label: 'L', action: 'query', payload: null)` 的 `isValid` 為 `false`，且不拋例外。

**步驟**：
1. 寫測試 → 失敗。
2. `a2ui_component.dart` 加 `part 'a2ui_component.g.dart';`，每個 concrete 類別加 `@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false, explicitToJson: true)`（`FallbackMarkdownComponent` 只需 `includeIfNull: false`，不宣告 `fromJson`）。欄位宣告順序不動。
3. 各元件 `toJson` 改為一行信封，例如：
   ```dart
   @override
   Map<String, Object?> toJson() => {
     'component_type': 'dish_catalog',
     'data': _$DishCatalogComponentToJson(this),
   };
   // Fallback：{'component_type': 'fallback_markdown', ..._$FallbackMarkdownComponentToJson(this)}
   ```
4. List 欄位轉換器：`dishes`→`mapListFromJson(raw, DishItemEntity.fromJson)`、`items`→`RestaurantComparisonItem.fromJson`、`chips`→`ActionChipItem.fromJson`、`highlights`／`options`→`stringListFromJson`。`payload` 不需轉換器。
5. `ActionChipItem.isValid` 加 `@JsonKey(includeFromJson: false, includeToJson: false)`，改寫為：
   ```dart
   bool get isValid {
     if ((label?.trim() ?? '').isEmpty || (action?.trim() ?? '').isEmpty) return false;
     return switch (action) {
       'query' => (payload?['prompt'] as String?)?.trim().isNotEmpty ?? false,
       'open_roulette' => ((payload?['options'] as List<Object?>?)
                   ?.whereType<String>()
                   .where((s) => s.trim().isNotEmpty)
                   .length ??
               0) >= 2,
       _ => true,
     };
   }
   ```
6. 分派器改寫（**`json['text']` 必須只在降級分支內讀取**，保持現行惰性求值，否則合法元件遇到非字串 `text` 會開始拋例外——T1 已有測試攔截）：
   ```dart
   return switch (componentType) {
     'dish_catalog' => switch (DishCatalogComponent.fromJson(data)) {
         final c when c.dishes?.isNotEmpty ?? false => c,
         final c => FallbackMarkdownComponent(
             text: (json['text'] as String?) ?? c.restaurantTitle ?? A2UIFallbackStrings.dishCatalogEmpty,
           ),
       },
     'comparison_matrix' => switch (ComparisonMatrixComponent.fromJson(data)) {
         final c when c.items?.isNotEmpty ?? false => c,
         final c => FallbackMarkdownComponent(
             text: (json['text'] as String?) ?? c.title ?? A2UIFallbackStrings.comparisonMatrixTitle,
           ),
       },
     'action_chip_group' => switch (ActionChipGroupComponent.fromJson(data)
           .chips
           ?.where((c) => c.isValid)
           .toList(growable: false)) {
         final chips? when chips.isNotEmpty => ActionChipGroupComponent(chips: chips),
         _ => FallbackMarkdownComponent(
             text: (json['text'] as String?) ?? A2UIFallbackStrings.actionChipGroupTitle,
           ),
       },
     'decision_roulette' => switch (DecisionRouletteComponent.fromJson(data)) {
         final c when (c.options?.length ?? 0) >= 2 => c,
         final c => FallbackMarkdownComponent(
             text: (json['text'] as String?) ?? c.title ?? A2UIFallbackStrings.decisionRouletteTitle,
           ),
       },
     _ => FallbackMarkdownComponent(
         text: (json['text'] as String?) ?? A2UIFallbackStrings.unknownComponent,
       ),
   };
   ```
7. `dart run build_runner build --delete-conflicting-outputs`。
8. 讀取端補 null：
   - `ai_foodie_repo.dart::_generateSmartFallback`：`RestaurantComparisonItem(id: r.id, name: r.name, …)`（順手移除 `!`）；轉盤 `options` 改 `items.map((e) => e.name).nonNulls.toList(growable: false)`（避免 `List<String?>`）。
   - `menu_vision_bloc.dart`：兩處 `message: result.text ?? ''`。
   - `menu_vision_model.dart`：`currency ?? 'TWD'`、`dishes ?? const []`。
   - `ai_foodie_model.dart`：matrix／item／chip group／chip／roulette／fallback 依 §2.5 補 `??`。
   - `menu_vision_repo.dart`：預期無需修改（只建構 `FallbackMarkdownComponent(text: …)` 與呼叫分派器）；以 `flutter analyze` 確認。
9. 調整既有測試（只為型別，逐條記入 PR 說明）：
   - `test/domain/entities/a2ui_component_test.dart`：`matrix.items.length`→`hasLength`、`matrix.items.first.x`→`matrix.items?.first.x`、`chipGroup.chips.length`／`chips[1]`／`chips.first` 同理。
   - `test/data_layer/ai_foodie_repo_test.dart`：`matrix.items.length／.first／[1]`、`chipGroup.chips.length／.first` 同理。
   - `test/data_layer/menu_vision_repo_test.dart`：`catalog.dishes.length／.first` 同理。
   - `test/domain/menu_vision_entity_test.dart`：A2UI group 的 `catalog.dishes.length／.first` 同理。
10. `dart format`。

**驗收**：
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/domain/ test/data_layer/ test/flow/
flutter analyze && flutter test
```
T1 三個檔、`menu_vision_model_test.dart`、`ai_foodie_model_test.dart` 必須不改全綠。
**回滾點**：單一 commit（含 `.g.dart`）。

---

### T4c：`AiFoodieMessage` entity

**目標**：`AiFoodieMessage` 改 `@JsonSerializable`、欄位 nullable；`createdAt` 以轉換器 `tryParse`；history 序列化與對話組裝接受 null。

**先寫的測試**（加到 `entity_nullability_test.dart`）：
- `AiFoodieMessage.fromJson(const {})`：`id／isUser／text／components／createdAt` 全為 `null`。
- `AiFoodieMessage.fromJson({'created_at': 'not-a-date'}).createdAt` 為 `null`（不拋例外）。
- `const AiFoodieMessage(text: 'x').toJson()` 等於 `{'text': 'x'}`（不含 `is_assistant`／`props`）。
- `AiFoodieMessage.user('hi').components` 為 `[]`（factory 行為不變）。
- `AiFoodieRepo.buildConversationContents([AiFoodieMessage.fromJson({'text': 'u', 'is_user': true}), AiFoodieMessage.fromJson(const {})], 'p')` 不拋例外，`isUser == null` 視為助理訊息。

**步驟**：
1. 寫測試 → 失敗。
2. `ai_foodie_message.dart`：
   ```dart
   part 'ai_foodie_message.g.dart';

   @immutable
   @JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false, explicitToJson: true)
   final class AiFoodieMessage extends Equatable {
     const AiFoodieMessage({this.id, this.isUser, this.text, this.components, this.createdAt});

     factory AiFoodieMessage.user(String text) => AiFoodieMessage(
       id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
       isUser: true,
       text: text,
       components: const [],          // 維持現行 user 訊息 components 為 []
       createdAt: DateTime.now(),
     );
     // assistant({required text, components = const []}) 不變

     factory AiFoodieMessage.fromJson(Map<String, Object?> json) => _$AiFoodieMessageFromJson(json);

     final String? id;
     final bool? isUser;
     @JsonKey(includeFromJson: false, includeToJson: false)
     bool get isAssistant => isUser != true;
     final String? text;
     @JsonKey(fromJson: _componentsFromJson)
     final List<A2UIComponent>? components;
     @JsonKey(fromJson: _createdAtFromJson)
     final DateTime? createdAt;

     Map<String, Object?> toJson() => _$AiFoodieMessageToJson(this);
     …
   }

   List<A2UIComponent>? _componentsFromJson(List<Object?>? raw) =>
       mapListFromJson(raw, A2UIComponent.fromJson);

   /// 參數型別 `String?`：非字串仍會 throw（v5.2 起 `checked: true` 包成 CheckedFromJsonException，見規格 §7）；字串解析失敗回傳 null。
   DateTime? _createdAtFromJson(String? value) =>
       value == null ? null : DateTime.tryParse(value);
   ```
3. `dart run build_runner build --delete-conflicting-outputs`。
4. `ai_foodie_repo.dart`：
   - `buildConversationContents`：`skipWhile((m) => m.isUser != true)`、`if (msg.isUser == true)`、`Content.text(msg.text ?? '')`。
   - `serializeAssistantHistory`：`(msg.components ?? const []).where(...)`、`'text': msg.text ?? ''`（手組 payload，維持現行 key 永遠存在）。
5. `ai_foodie_model.dart`：`isUser ?? false`、`text ?? ''`、`(components ?? const [])`。
6. `test/domain/entities/a2ui_component_test.dart`：`restored.components.length`／`.first` 改 `hasLength`／`?.first`。
7. `dart format`。

**驗收**：
```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze && flutter test
```
**回滾點**：單一 commit（含 `.g.dart`）。

---

### T5：收尾驗證

**步驟與驗收**（全部必須通過）：
```bash
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- '*.g.dart'   # 產生碼已是最新
flutter analyze                                   # No issues found
flutter test                                      # 全綠
git diff main --stat -- test/domain/entities/a2ui_characterization_test.dart \
  test/flow/menu_vision/menu_vision_view_characterization_test.dart \
  test/flow/ai_foodie/ai_foodie_view_characterization_test.dart   # 期望：只有 T1 新增，之後零修改
rtk proxy grep -rn "domain/" lib/flow/menu_vision/view lib/flow/ai_foodie/view
# 期望只有：menu_vision_sheet → domain/repositories/menu_vision_repository.dart
#           ai_foodie_sheet  → entities_barrel show RestaurantEntity, RestaurantLocationEntity
#                             domain/repositories/ai_foodie_repository.dart
rtk proxy grep -rn "fromJson\|toJson" lib/domain/entities/{allergen_info,dish_item_entity,a2ui_component,ai_foodie_message}.dart
# 人工確認：除分派器外，沒有手寫欄位解析殘留
```
整理 PR 說明素材：T4a–T4c 步驟中「調整既有測試」的每一條斷言（檔案:行、原斷言、新斷言、理由：型別 nullable／規格 §4.2 語意變更）。

---

## 5. 風險與回滾

| 風險 | 偵測點 | 緩解／回滾 |
|------|--------|------------|
| UI model 預設值與現行 entity 預設值不一致 → 畫面改變 | T1-2、T1-3 widget 特性測試；`menu_vision_model_test`／`ai_foodie_model_test` 在 T4 不改仍須綠 | 預設值只在 `fromEntity` 一處；在 T4 同一 commit 內搬家。失敗即 revert 該 T4 子任務 |
| 產生碼 `as T` 取代 `whereType` → 混型整張卡降級 | T1-1「混型 List」群組 | 所有 List 欄位走 `stringListFromJson`／`mapListFromJson` |
| `toJson` key 順序或 enum 字串改變 → history 字串不同 | T1-1 逐字快照＋`serializeAssistantHistory` 快照 | 欄位宣告順序不動（產生器依宣告順序輸出） |
| 產生碼把 Equatable getter／`isValid`／`isAssistant` 寫進 `toJson` | T1-1 快照（全欄位）＋ T4 `toJson` 等值斷言 | 不用 `createFactory: false`；getter 標 `includeToJson: false` |
| 分派器改寫後提早讀 `json['text']` → 合法元件開始拋例外 | T1-1「合法元件不讀 text」 | 降級分支內才讀 |
| 分派器／`isValid` 漏處理 null | T1-1 分派器群組＋T4b `isValid` null 測試 | — |
| history 誤用 UI model | T1-3 `lastHistory` 斷言＋T3 bloc 測試 | State 保留 entity；`messageModels` 無法經 `copyWith` 單獨設定 |
| 中途不可編譯 | 每個任務的 `flutter analyze && flutter test` | 方案 A 的順序保證；每任務單一 commit，可獨立 revert |
| `spice_level` 產生碼非 `toInt()` | T1-1 數值群組 | 已查證 6.14.1 會輸出 `toInt()`；備援轉換器見 T4a |

回滾點：T1、T2、T3、T4a、T4b、T4c 各為一個 commit。T4 系列任一失敗只需 revert 該 commit，前面的 UI model 重構仍然有效（UI model 在 entity non-null 下同樣正確）。

---

## 6. 執行方式選項

- **Subagent-driven（推薦）**：主 session 依序派工 T1 → [T2 ∥ T3] → T4a（可與 T3 重疊）→ T4b → T4c → T5。每個任務完成後由主 session 跑驗收指令並 review diff 再派下一個。T4b 建議由較高推論等級的 agent 執行（分派器改寫是唯一的設計判斷點）。
- **Parallel session**：T1 完成並 commit 後，開兩個 worktree：session A 做 T2 → T4a，session B 做 T3；兩者合併後由單一 session 做 T4b → T4c → T5。注意：兩個 session 都會跑 `build_runner`，T3 不新增註解類別，所以不會產生 `.g.dart` 衝突。

---

## 7. 規格未明寫、由本計畫決定的事項（請確認）

1. **View 無法做到 import `domain/entities` 為 0**：`ai_foodie_sheet.dart` 的建構參數 `candidateRestaurants` 與導航參數 `Tuple2<RestaurantEntity, dynamic>` 都需要 `RestaurantEntity`／`RestaurantLocationEntity`（範圍外 entity）。本計畫改為 `import … entities_barrel.dart show RestaurantEntity, RestaurantLocationEntity`，並把規格 §4.6 解讀為「本次 10 個 entity 不得出現在 View」。`menu_vision_sheet.dart` 的 `domain_barrel.dart` 改為只 import `MenuVisionRepository`。
2. **UI model 並非「全部 non-null」**：`ComparisonItemModel.price／address／category／imageUrl` 保留 `String?`，因為現行預設就是 `null`，且 View 以 `!= null` 分支渲染；改成 `''` 會讓 LLM 給空字串時畫面不同。
3. **UI model 只收 View 會讀的欄位**：`DishItemEntity.id／chefRecommendationScore`、`AllergenInfo.note`、`DishCatalogComponent.restaurantTitle`、`AiFoodieMessage.id／createdAt` 沒有進 UI model（View 未使用）。因此規格 §3.4 的「`createdAt` 缺值時用轉換當下時間」與「`chefRecommendationScore` 預設 0.0」沒有落點；日後 View 需要時再加欄位與預設值。
4. **enum 仍在 domain**：`AllergenRiskLevel`、`DishCategory`（含多語系顯示）由 `menu_vision_model.dart` 以 `export … show` 轉出，View 經 model 檔取得，不直接 import domain。
5. **`DishCatalogComponent` 在 AI 覓食畫布**：現行渲染為 `SizedBox.shrink()`；UI model 轉換時直接略過（`fromEntity` 回傳 `null`），View 的 `switch` 因此可窮盡且移除 `_ =>`。畫面高度皆為 0，不影響顯示。
6. **`AiFoodieMessage.user()` 明確給 `components: const []`**：建構式移除預設值後，若不補，user 訊息的 `components` 會變 `null`，既有測試 `expect(userMsg.components, isEmpty)` 會失敗。`assistant()` factory 的參數預設 `const []` 保留（本地建立的訊息，不屬於「server 資料」）。
7. **分派器的 `json['text']` 必須惰性讀取**：現行只有降級時才經 `_optString` 讀 `json['text']`；若重構時提前讀，合法元件遇到非字串 `text` 會開始拋 `FormatException`（v5.2 前為 `TypeError`）。T1 已加測試攔截。
8. **規格 §6 的任務順序被調換**（先 UI model 後 entity），理由見 §1。
9. **`serializeAssistantHistory` 是手組 payload**：`text` 以 `msg.text ?? ''` 保持 key 永遠存在，與「entity `toJson` 省略 null」是兩件事；不改其格式。
10. **v5.2（PR #127 review 追加）：T1 檔案例外修改**——review 過程發現手寫 `fromJson` 把 `TypeError` 吞掉違反 flutter-styles §6.1「不捕捉 Error」，改為 `@JsonSerializable(checked: true)` 讓型別錯誤改拋 `CheckedFromJsonException`／`FormatException`。這個修正必須更動 T1 產出的 `test/domain/entities/a2ui_characterization_test.dart`（「純量型別錯誤」一組 8 個 case 的期望型別），違反 §3「鐵律」1「T2 之後禁止修改 T1 三個檔」。判定為刻意例外：只動期望的例外型別、不動輸入與其餘斷言，且是本計畫成立時未預見的既有 bug 修正，不代表原有特性測試失去回歸網的效力。細節見規格 §7 v5.2。
