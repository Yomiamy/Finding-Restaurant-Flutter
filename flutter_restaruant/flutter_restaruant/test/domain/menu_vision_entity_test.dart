import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AllergenRiskLevel & AllergenInfo Tests', () {
    test('AllergenRiskLevel parses correctly', () {
      expect(AllergenRiskLevel.fromString('contains'), AllergenRiskLevel.contains);
      expect(AllergenRiskLevel.fromString('CONTAINS'), AllergenRiskLevel.contains);
      expect(AllergenRiskLevel.fromString('may_contain'), AllergenRiskLevel.mayContain);
      expect(AllergenRiskLevel.fromString('maycontain'), AllergenRiskLevel.mayContain);
      expect(AllergenRiskLevel.fromString('none'), AllergenRiskLevel.none);
      expect(AllergenRiskLevel.fromString('unknown_value'), AllergenRiskLevel.none);
    });

    test('AllergenInfo fromJson and toJson', () {
      final json = <String, Object?>{
        'name': '花生',
        'risk_level': 'contains',
        'note': '醬汁含花生顆粒',
      };

      final allergen = AllergenInfo.fromJson(json);
      expect(allergen.name, '花生');
      expect(allergen.riskLevel, AllergenRiskLevel.contains);
      expect(allergen.note, '醬汁含花生顆粒');
      expect(allergen.toJson(), {
        'name': '花生',
        'risk_level': 'contains',
        'note': '醬汁含花生顆粒',
      });
    });

    test('AllergenInfo equality', () {
      const a1 = AllergenInfo(
        name: '蛋',
        riskLevel: AllergenRiskLevel.contains,
      );
      const a2 = AllergenInfo(
        name: '蛋',
        riskLevel: AllergenRiskLevel.contains,
      );
      expect(a1, equals(a2));
    });
  });

  group('DishCategory & DishItemEntity Tests', () {
    test('DishCategory parses and provides display names', () {
      expect(DishCategory.fromString('appetizer'), DishCategory.appetizer);
      expect(DishCategory.fromString('main'), DishCategory.main);
      expect(DishCategory.fromString('soup'), DishCategory.soup);
      expect(DishCategory.fromString('dessert'), DishCategory.dessert);
      expect(DishCategory.fromString('beverage'), DishCategory.beverage);
      expect(DishCategory.fromString('other'), DishCategory.other);
      expect(DishCategory.fromString('xyz'), DishCategory.other);

      expect(DishCategory.appetizer.displayName, '前菜');
      expect(DishCategory.main.displayName, '主食');
      expect(DishCategory.soup.displayName, '湯品');
      expect(DishCategory.dessert.displayName, '甜點');
      expect(DishCategory.beverage.displayName, '飲品');
      expect(DishCategory.other.displayName, '其他');
    });

    test('DishItemEntity fromJson with complete data', () {
      final json = <String, Object?>{
        'id': 'yakitori-negima',
        'name': '鹽烤蔥蔥雞肉串',
        'original_name': 'ねぎま',
        'price': 120.0,
        'category': 'appetizer',
        'allergens': [
          {'name': '大豆', 'risk_level': 'may_contain', 'note': '醬料產線'},
        ],
        'dietary_tags': ['halal'],
        'spice_level': 1,
        'ingredients': ['雞腿肉', '大蔥', '海鹽'],
        'chef_recommendation_score': 0.95,
      };

      final dish = DishItemEntity.fromJson(json);
      expect(dish.id, 'yakitori-negima');
      expect(dish.name, '鹽烤蔥蔥雞肉串');
      expect(dish.originalName, 'ねぎま');
      expect(dish.price, 120.0);
      expect(dish.category, DishCategory.appetizer);
      expect(dish.allergens.length, 1);
      expect(dish.allergens.first.name, '大豆');
      expect(dish.allergens.first.riskLevel, AllergenRiskLevel.mayContain);
      expect(dish.dietaryTags, ['halal']);
      expect(dish.spiceLevel, 1);
      expect(dish.ingredients, ['雞腿肉', '大蔥', '海鹽']);
      expect(dish.chefRecommendationScore, 0.95);
    });

    test('DishItemEntity handles nulls and invalid numbers gracefully', () {
      final json = <String, Object?>{
        'id': null,
        'name': null,
        'price': null,
        'category': null,
        'allergens': null,
      };

      final dish = DishItemEntity.fromJson(json);
      expect(dish.id, '');
      expect(dish.name, '');
      expect(dish.price, 0.0);
      expect(dish.category, DishCategory.other);
      expect(dish.allergens, isEmpty);
      expect(dish.dietaryTags, isEmpty);
      expect(dish.ingredients, isEmpty);
    });
  });

  group('A2UIComponent Sealed Hierarchy Tests', () {
    test('A2UIComponent.fromJson returns DishCatalogComponent for dish_catalog', () {
      final json = <String, Object?>{
        'component_type': 'dish_catalog',
        'data': {
          'restaurant_title': '野武士居酒屋',
          'currency': 'JPY',
          'dishes': [
            {
              'id': 'sashimi-set',
              'name': '特選生魚片拼盤',
              'original_name': '刺身盛り合わせ',
              'price': 2500,
              'category': 'main',
              'allergens': [
                {'name': '甲殼類', 'risk_level': 'contains', 'note': '內含甜蝦'},
              ],
            },
          ],
        },
      };

      final component = A2UIComponent.fromJson(json);
      expect(component, isA<DishCatalogComponent>());

      final catalog = component as DishCatalogComponent;
      expect(catalog.restaurantTitle, '野武士居酒屋');
      expect(catalog.currency, 'JPY');
      expect(catalog.dishes.length, 1);
      expect(catalog.dishes.first.name, '特選生魚片拼盤');

      const A2UIComponent unpromoted = DishCatalogComponent(
        restaurantTitle: 'Test',
        dishes: [],
      );
      final description = switch (unpromoted) {
        DishCatalogComponent(:final dishes) => '有 ${dishes.length} 道菜',
        FallbackMarkdownComponent(:final text) => text,
      };
      expect(description, '有 0 道菜');
    });

    test('A2UIComponent.fromJson falls back to FallbackMarkdownComponent on unknown type', () {
      final json = <String, Object?>{
        'component_type': 'unknown_future_component',
        'text': '未知元件降級文字',
      };

      final component = A2UIComponent.fromJson(json);
      expect(component, isA<FallbackMarkdownComponent>());

      final fallback = component as FallbackMarkdownComponent;
      expect(fallback.text, '未知元件降級文字');
      expect(fallback.toJson(), {
        'component_type': 'fallback_markdown',
        'text': '未知元件降級文字',
      });
    });

    test('DishCatalogComponent toJson round-trip', () {
      const catalog = DishCatalogComponent(
        restaurantTitle: '美味小館',
        currency: 'TWD',
        dishes: [
          DishItemEntity(
            id: 'd1',
            name: '蔥油餅',
            originalName: 'Scallion Pancake',
            price: 60.0,
            category: DishCategory.appetizer,
            allergens: [],
            dietaryTags: ['vegetarian'],
            spiceLevel: 0,
          ),
        ],
      );

      final json = catalog.toJson();
      final restored = A2UIComponent.fromJson(json);
      expect(restored, equals(catalog));
    });
  });
}
