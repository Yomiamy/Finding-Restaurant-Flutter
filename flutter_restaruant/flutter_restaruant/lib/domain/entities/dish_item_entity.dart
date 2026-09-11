import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'allergen_info.dart';

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

  String get displayName => switch (this) {
    DishCategory.appetizer => '前菜',
    DishCategory.main => '主食',
    DishCategory.soup => '湯品',
    DishCategory.dessert => '甜點',
    DishCategory.beverage => '飲品',
    DishCategory.other => '其他',
  };
}

/// 菜色領域實體模型
@immutable
class DishItemEntity extends Equatable {
  const DishItemEntity({
    required this.id,
    required this.name,
    required this.originalName,
    required this.price,
    required this.category,
    required this.allergens,
    required this.dietaryTags,
    required this.spiceLevel,
    this.ingredients = const [],
    this.chefRecommendationScore = 0.0,
  });

  factory DishItemEntity.fromJson(Map<String, Object?> json) {
    final rawAllergens = json['allergens'] as List<Object?>? ?? const [];
    final allergens = rawAllergens
        .whereType<Map<String, Object?>>()
        .map(AllergenInfo.fromJson)
        .toList(growable: false);

    final rawTags = json['dietary_tags'] as List<Object?>? ?? const [];
    final dietaryTags = rawTags.whereType<String>().toList(growable: false);

    final rawIngredients = json['ingredients'] as List<Object?>? ?? const [];
    final ingredients = rawIngredients
        .whereType<String>()
        .toList(growable: false);

    final categoryStr = json['category'] as String? ?? 'other';

    return DishItemEntity(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      originalName: json['original_name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: DishCategory.fromString(categoryStr),
      allergens: allergens,
      dietaryTags: dietaryTags,
      spiceLevel: (json['spice_level'] as num?)?.toInt() ?? 0,
      ingredients: ingredients,
      chefRecommendationScore:
          (json['chef_recommendation_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String id;
  final String name;
  final String originalName;
  final double price;
  final DishCategory category;
  final List<AllergenInfo> allergens;
  final List<String> dietaryTags;
  final int spiceLevel; // 0: 不辣, 1: 微辣, 2: 中辣, 3: 大辣
  final List<String> ingredients;
  final double chefRecommendationScore;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'original_name': originalName,
    'price': price,
    'category': category.name,
    'allergens': allergens.map((e) => e.toJson()).toList(growable: false),
    'dietary_tags': dietaryTags,
    'spice_level': spiceLevel,
    'ingredients': ingredients,
    'chef_recommendation_score': chefRecommendationScore,
  };

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
