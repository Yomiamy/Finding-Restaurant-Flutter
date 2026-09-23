import 'package:equatable/equatable.dart';

import '../../../domain/entities/a2ui_component.dart';
import '../../../domain/entities/allergen_info.dart';
import '../../../domain/entities/dish_item_entity.dart';

export '../../../domain/entities/allergen_info.dart' show AllergenRiskLevel;
export '../../../domain/entities/dish_item_entity.dart' show DishCategory;

/// Menu Vision 畫面用的菜單看板 UI model（欄位 non-null，預設值集中於 [fromEntity]）
class DishCatalogModel extends Equatable {
  const DishCatalogModel({required this.currency, required this.dishes});

  factory DishCatalogModel.fromEntity(DishCatalogComponent entity) {
    return DishCatalogModel(
      currency: entity.currency,
      dishes: entity.dishes.map(DishModel.fromEntity).toList(growable: false),
    );
  }

  final String currency;
  final List<DishModel> dishes;

  @override
  List<Object?> get props => [currency, dishes];
}

/// 菜色 UI model
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

  factory DishModel.fromEntity(DishItemEntity entity) {
    return DishModel(
      name: entity.name,
      originalName: entity.originalName,
      price: entity.price,
      category: entity.category,
      allergens: entity.allergens
          .map(AllergenModel.fromEntity)
          .toList(growable: false),
      dietaryTags: entity.dietaryTags,
      spiceLevel: entity.spiceLevel,
      ingredients: entity.ingredients,
    );
  }

  final String name;
  final String originalName;
  final double price;
  final DishCategory category;
  final List<AllergenModel> allergens;
  final List<String> dietaryTags;
  final int spiceLevel;
  final List<String> ingredients;

  @override
  List<Object?> get props => [
    name,
    originalName,
    price,
    category,
    allergens,
    dietaryTags,
    spiceLevel,
    ingredients,
  ];
}

/// 過敏原 UI model
class AllergenModel extends Equatable {
  const AllergenModel({required this.name, required this.riskLevel});

  factory AllergenModel.fromEntity(AllergenInfo entity) {
    return AllergenModel(name: entity.name, riskLevel: entity.riskLevel);
  }

  final String name;
  final AllergenRiskLevel riskLevel;

  @override
  List<Object?> get props => [name, riskLevel];
}
