import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import '../../generated/l10n.dart';
import 'allergen_info.dart';
import 'entity_json_converters.dart';

part 'dish_item_entity.g.dart';

/// 菜色分類
enum DishCategory {
  appetizer,
  main,
  soup,
  dessert,
  beverage,
  other;

  static DishCategory fromString(String value) {
    return switch (value.toLowerCase()) {
      'appetizer' => DishCategory.appetizer,
      'main' => DishCategory.main,
      'soup' => DishCategory.soup,
      'dessert' => DishCategory.dessert,
      'beverage' => DishCategory.beverage,
      _ => DishCategory.other,
    };
  }

  String get displayName {
    try {
      return switch (this) {
        DishCategory.appetizer => S.current.dish_category_appetizer,
        DishCategory.main => S.current.dish_category_main,
        DishCategory.soup => S.current.dish_category_soup,
        DishCategory.dessert => S.current.dish_category_dessert,
        DishCategory.beverage => S.current.dish_category_beverage,
        DishCategory.other => S.current.dish_category_other,
      };
    } catch (_) {
      return switch (this) {
        DishCategory.appetizer => '前菜',
        DishCategory.main => '主食',
        DishCategory.soup => '湯品',
        DishCategory.dessert => '甜點',
        DishCategory.beverage => '飲品',
        DishCategory.other => '其他',
      };
    }
  }
}

/// 菜色領域實體模型
@immutable
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
  explicitToJson: true,
)
class DishItemEntity extends Equatable {
  const DishItemEntity({
    this.id,
    this.name,
    this.originalName,
    this.price,
    this.category,
    this.allergens,
    this.dietaryTags,
    this.spiceLevel,
    this.ingredients,
    this.chefRecommendationScore,
  });

  factory DishItemEntity.fromJson(Map<String, Object?> json) =>
      _$DishItemEntityFromJson(json);

  final String? id;
  final String? name;
  final String? originalName;
  final double? price;
  @JsonKey(fromJson: _categoryFromJson)
  final DishCategory? category;
  @JsonKey(fromJson: _allergensFromJson)
  final List<AllergenInfo>? allergens;
  @JsonKey(fromJson: stringListFromJson)
  final List<String>? dietaryTags;
  final int? spiceLevel; // 0: 不辣, 1: 微辣, 2: 中辣, 3: 大辣
  @JsonKey(fromJson: stringListFromJson)
  final List<String>? ingredients;
  final double? chefRecommendationScore;

  Map<String, Object?> toJson() => _$DishItemEntityToJson(this);

  @override
  List<Object?> get props => [
    id,
    name,
    originalName,
    price,
    category,
    allergens,
    dietaryTags,
    spiceLevel,
    ingredients,
    chefRecommendationScore,
  ];
}

DishCategory? _categoryFromJson(String? value) =>
    value == null ? null : DishCategory.fromString(value);

List<AllergenInfo>? _allergensFromJson(List<Object?>? raw) =>
    mapListFromJson(raw, AllergenInfo.fromJson);
