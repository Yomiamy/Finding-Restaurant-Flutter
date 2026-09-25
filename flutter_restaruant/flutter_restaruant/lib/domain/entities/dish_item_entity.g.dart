// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dish_item_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DishItemEntity _$DishItemEntityFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DishItemEntity',
      json,
      ($checkedConvert) {
        final val = DishItemEntity(
          id: $checkedConvert('id', (v) => v as String?),
          name: $checkedConvert('name', (v) => v as String?),
          originalName: $checkedConvert('original_name', (v) => v as String?),
          price: $checkedConvert('price', (v) => (v as num?)?.toDouble()),
          category: $checkedConvert(
            'category',
            (v) => _categoryFromJson(v as String?),
          ),
          allergens: $checkedConvert(
            'allergens',
            (v) => _allergensFromJson(v as List?),
          ),
          dietaryTags: $checkedConvert(
            'dietary_tags',
            (v) => stringListFromJson(v as List?),
          ),
          spiceLevel: $checkedConvert(
            'spice_level',
            (v) => (v as num?)?.toInt(),
          ),
          ingredients: $checkedConvert(
            'ingredients',
            (v) => stringListFromJson(v as List?),
          ),
          chefRecommendationScore: $checkedConvert(
            'chef_recommendation_score',
            (v) => (v as num?)?.toDouble(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'originalName': 'original_name',
        'dietaryTags': 'dietary_tags',
        'spiceLevel': 'spice_level',
        'chefRecommendationScore': 'chef_recommendation_score',
      },
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
