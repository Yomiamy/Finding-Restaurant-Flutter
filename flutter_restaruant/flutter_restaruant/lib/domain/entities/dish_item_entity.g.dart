// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dish_item_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DishItemEntity _$DishItemEntityFromJson(Map<String, dynamic> json) =>
    DishItemEntity(
      id: json['id'] as String?,
      name: json['name'] as String?,
      originalName: json['original_name'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      category: _categoryFromJson(json['category'] as String?),
      allergens: _allergensFromJson(json['allergens'] as List?),
      dietaryTags: stringListFromJson(json['dietary_tags'] as List?),
      spiceLevel: (json['spice_level'] as num?)?.toInt(),
      ingredients: stringListFromJson(json['ingredients'] as List?),
      chefRecommendationScore: (json['chef_recommendation_score'] as num?)
          ?.toDouble(),
    );

Map<String, dynamic> _$DishItemEntityToJson(DishItemEntity instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'name': ?instance.name,
      'original_name': ?instance.originalName,
      'price': ?instance.price,
      'category': ?_$DishCategoryEnumMap[instance.category],
      'allergens': ?instance.allergens?.map((e) => e.toJson()).toList(),
      'dietary_tags': ?instance.dietaryTags,
      'spice_level': ?instance.spiceLevel,
      'ingredients': ?instance.ingredients,
      'chef_recommendation_score': ?instance.chefRecommendationScore,
    };

const _$DishCategoryEnumMap = {
  DishCategory.appetizer: 'appetizer',
  DishCategory.main: 'main',
  DishCategory.soup: 'soup',
  DishCategory.dessert: 'dessert',
  DishCategory.beverage: 'beverage',
  DishCategory.other: 'other',
};
