import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'a2ui_fallback_strings.dart';
import 'dish_item_entity.dart';
import 'entity_json_converters.dart';

part 'a2ui_component.g.dart';

/// GenUI (A2UI) 宣告式元件協定基類
///
/// 使用 Dart 3 sealed class，編譯期強制窮盡檢查所有元件子型別。
@immutable
sealed class A2UIComponent extends Equatable {
  const A2UIComponent();

  factory A2UIComponent.fromJson(Map<String, Object?> json) {
    final componentType = _optString(json, 'component_type') ?? '';
    final data = switch (json['data']) {
      null => const <String, Object?>{},
      final Map<String, Object?> m => m,
      final v => throw FormatException('data 應為物件', v),
    };

    // json['text'] 只在降級分支讀取：合法元件遇到非字串 text 不可拋例外。
    return switch (componentType) {
      'dish_catalog' => switch (DishCatalogComponent.fromJson(data)) {
        final c when c.dishes?.isNotEmpty ?? false => c,
        final c => FallbackMarkdownComponent(
          text:
              _optString(json, 'text') ??
              c.restaurantTitle ??
              A2UIFallbackStrings.dishCatalogEmpty,
        ),
      },
      'comparison_matrix' => switch (ComparisonMatrixComponent.fromJson(data)) {
        final c when c.items?.isNotEmpty ?? false => c,
        final c => FallbackMarkdownComponent(
          text:
              _optString(json, 'text') ??
              c.title ??
              A2UIFallbackStrings.comparisonMatrixTitle,
        ),
      },
      'action_chip_group' => switch (ActionChipGroupComponent.fromJson(
        data,
      ).chips?.where((c) => c.isValid).toList(growable: false)) {
        final chips? when chips.isNotEmpty => ActionChipGroupComponent(
          chips: chips,
        ),
        _ => FallbackMarkdownComponent(
          text:
              _optString(json, 'text') ??
              A2UIFallbackStrings.actionChipGroupTitle,
        ),
      },
      'decision_roulette' => switch (DecisionRouletteComponent.fromJson(data)) {
        final c when (c.options?.length ?? 0) >= 2 => c,
        final c => FallbackMarkdownComponent(
          text:
              _optString(json, 'text') ??
              c.title ??
              A2UIFallbackStrings.decisionRouletteTitle,
        ),
      },
      _ => FallbackMarkdownComponent(
        text: _optString(json, 'text') ?? A2UIFallbackStrings.unknownComponent,
      ),
    };
  }

  Map<String, Object?> toJson();
}

/// 互動式菜單看板元件 (Dish Catalog Component)
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
  explicitToJson: true,
)
final class DishCatalogComponent extends A2UIComponent {
  const DishCatalogComponent({
    this.restaurantTitle,
    this.currency,
    this.dishes,
  });

  factory DishCatalogComponent.fromJson(Map<String, Object?> json) =>
      _$DishCatalogComponentFromJson(json);

  final String? restaurantTitle;
  final String? currency;
  @JsonKey(fromJson: _dishesFromJson)
  final List<DishItemEntity>? dishes;

  @override
  Map<String, Object?> toJson() => {
    'component_type': 'dish_catalog',
    'data': _$DishCatalogComponentToJson(this),
  };

  @override
  List<Object?> get props => [restaurantTitle, currency, dishes];
}

/// 多店對比矩陣元件 (Comparison Matrix Component)
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
  explicitToJson: true,
)
final class ComparisonMatrixComponent extends A2UIComponent {
  const ComparisonMatrixComponent({this.title, this.items});

  factory ComparisonMatrixComponent.fromJson(Map<String, Object?> json) =>
      _$ComparisonMatrixComponentFromJson(json);

  final String? title;
  @JsonKey(fromJson: _itemsFromJson)
  final List<RestaurantComparisonItem>? items;

  @override
  Map<String, Object?> toJson() => {
    'component_type': 'comparison_matrix',
    'data': _$ComparisonMatrixComponentToJson(this),
  };

  @override
  List<Object?> get props => [title, items];
}

/// 餐廳對比卡片項目
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
  explicitToJson: true,
)
final class RestaurantComparisonItem extends Equatable {
  const RestaurantComparisonItem({
    this.id,
    this.name,
    this.rating,
    this.price,
    this.highlights,
    this.address,
    this.category,
    this.imageUrl,
  });

  factory RestaurantComparisonItem.fromJson(Map<String, Object?> json) =>
      _$RestaurantComparisonItemFromJson(json);

  final String? id;
  final String? name;
  final double? rating;
  final String? price;
  @JsonKey(fromJson: stringListFromJson)
  final List<String>? highlights;
  final String? address;
  final String? category;
  final String? imageUrl;

  Map<String, Object?> toJson() => _$RestaurantComparisonItemToJson(this);

  @override
  List<Object?> get props => [
    id,
    name,
    rating,
    price,
    highlights,
    address,
    category,
    imageUrl,
  ];
}

/// 行動標籤群組元件 (Action Chip Group Component)
///
/// `isValid` 過濾由 [A2UIComponent.fromJson] 分派器負責，此處如實保留。
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
  explicitToJson: true,
)
final class ActionChipGroupComponent extends A2UIComponent {
  const ActionChipGroupComponent({this.chips});

  factory ActionChipGroupComponent.fromJson(Map<String, Object?> json) =>
      _$ActionChipGroupComponentFromJson(json);

  @JsonKey(fromJson: _chipsFromJson)
  final List<ActionChipItem>? chips;

  @override
  Map<String, Object?> toJson() => {
    'component_type': 'action_chip_group',
    'data': _$ActionChipGroupComponentToJson(this),
  };

  @override
  List<Object?> get props => [chips];
}

/// 行動標籤項目
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
  explicitToJson: true,
)
final class ActionChipItem extends Equatable {
  const ActionChipItem({this.label, this.action, this.payload});

  factory ActionChipItem.fromJson(Map<String, Object?> json) =>
      _$ActionChipItemFromJson(json);

  final String? label;
  final String? action;
  final Map<String, Object?>? payload;

  /// 檢查此行動標籤是否具備合法的必要欄位與載荷
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isValid {
    if ((label?.trim() ?? '').isEmpty || (action?.trim() ?? '').isEmpty) {
      return false;
    }
    // payload 來自不可信 JSON：型別不符即不合法，交由分派器過濾。
    return switch ((action, payload?['prompt'], payload?['options'])) {
      ('query', final String p, _) => p.trim().isNotEmpty,
      ('query', _, _) => false,
      ('open_roulette', _, final List<Object?> o) =>
        o.whereType<String>().where((s) => s.trim().isNotEmpty).length >= 2,
      ('open_roulette', _, _) => false,
      _ => true, // 保留對未知或未來自訂動作的向後相容性
    };
  }

  Map<String, Object?> toJson() => _$ActionChipItemToJson(this);

  @override
  List<Object?> get props => [label, action, payload];
}

/// 命運轉盤元件 (Decision Roulette Component)
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
  explicitToJson: true,
)
final class DecisionRouletteComponent extends A2UIComponent {
  const DecisionRouletteComponent({this.title, this.options});

  factory DecisionRouletteComponent.fromJson(Map<String, Object?> json) =>
      _$DecisionRouletteComponentFromJson(json);

  final String? title;
  @JsonKey(fromJson: stringListFromJson)
  final List<String>? options;

  @override
  Map<String, Object?> toJson() => {
    'component_type': 'decision_roulette',
    'data': _$DecisionRouletteComponentToJson(this),
  };

  @override
  List<Object?> get props => [title, options];
}

/// 安全降級文字卡片 (Fallback Markdown Component)
///
/// 當模型輸出結構異常、部分破損或非預期元件時安全降級，保證絕不崩潰。
/// 維持預設 `createFactory`（`false` 會把 Equatable getter 寫進 toJson），但不宣告 fromJson：
/// 它只由分派器建立，輸出維持扁平格式。
@JsonSerializable(checked: true, includeIfNull: false)
final class FallbackMarkdownComponent extends A2UIComponent {
  const FallbackMarkdownComponent({this.text});

  final String? text;

  @override
  Map<String, Object?> toJson() => {
    'component_type': 'fallback_markdown',
    ..._$FallbackMarkdownComponentToJson(this),
  };

  @override
  List<Object?> get props => [text];
}

List<DishItemEntity>? _dishesFromJson(List<Object?>? raw) =>
    mapListFromJson(raw, DishItemEntity.fromJson);

List<RestaurantComparisonItem>? _itemsFromJson(List<Object?>? raw) =>
    mapListFromJson(raw, RestaurantComparisonItem.fromJson);

List<ActionChipItem>? _chipsFromJson(List<Object?>? raw) =>
    mapListFromJson(raw, ActionChipItem.fromJson);

/// 不可信 JSON 的字串欄位：null 照舊回傳 null，非字串拋 [FormatException]（不拋 TypeError）。
String? _optString(Map<String, Object?> json, String key) =>
    switch (json[key]) {
      final String? v => v,
      final v => throw FormatException('$key 應為字串', v),
    };
