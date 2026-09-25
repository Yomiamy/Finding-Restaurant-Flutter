import 'package:flutter_restaruant/domain/domain_barrel.dart';
import 'package:flutter_restaruant/flow/menu_vision/menu_vision_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromEntity：全缺值 → UI 預設值', () {
    final m = DishModel.fromEntity(DishItemEntity.fromJson(const {}));
    expect(
      m,
      const DishModel(
        name: '',
        originalName: '',
        price: 0.0,
        category: DishCategory.other,
        allergens: [],
        dietaryTags: [],
        spiceLevel: 0,
        ingredients: [],
      ),
    );
    expect(
      AllergenModel.fromEntity(AllergenInfo.fromJson(const {})),
      const AllergenModel(name: '', riskLevel: AllergenRiskLevel.none),
    );
    final c = DishCatalogModel.fromEntity(
      A2UIComponent.fromJson({
            'component_type': 'dish_catalog',
            'data': {
              'dishes': [<String, Object?>{}],
            },
          })
          as DishCatalogComponent,
    );
    expect(c.currency, 'TWD');
    expect(c.dishes, hasLength(1));
  });

  test('fromEntity：全有值 → 原值', () {
    final allergenEntity = AllergenInfo.fromJson(const {
      'name': '花生',
      'risk_level': 'may_contain',
      'note': '產線共用',
    });
    final allergenModel = AllergenModel.fromEntity(allergenEntity);
    expect(allergenModel.name, '花生');
    expect(allergenModel.riskLevel, AllergenRiskLevel.mayContain);

    final dishEntity = DishItemEntity.fromJson(const {
      'id': 'd1',
      'name': '豚骨拉麵',
      'original_name': 'とんこつラーメン',
      'price': 280,
      'category': 'main',
      'allergens': [
        {'name': '花生', 'risk_level': 'may_contain', 'note': '產線共用'},
      ],
      'dietary_tags': ['招牌'],
      'spice_level': 2,
      'ingredients': ['叉燒', '糖心蛋'],
    });
    final dishModel = DishModel.fromEntity(dishEntity);
    expect(dishModel.name, '豚骨拉麵');
    expect(dishModel.originalName, 'とんこつラーメン');
    expect(dishModel.price, 280.0);
    expect(dishModel.category, DishCategory.main);
    expect(dishModel.allergens, [allergenModel]);
    expect(dishModel.dietaryTags, ['招牌']);
    expect(dishModel.spiceLevel, 2);
    expect(dishModel.ingredients, ['叉燒', '糖心蛋']);

    final catalogEntity =
        A2UIComponent.fromJson({
              'component_type': 'dish_catalog',
              'data': {
                'restaurant_title': '一風堂',
                'currency': 'JPY',
                'dishes': [
                  {'name': '豚骨拉麵', 'price': 280},
                ],
              },
            })
            as DishCatalogComponent;
    final catalogModel = DishCatalogModel.fromEntity(catalogEntity);
    expect(catalogModel.currency, 'JPY');
    expect(catalogModel.dishes, hasLength(1));
    expect(catalogModel.dishes.single.name, '豚骨拉麵');
  });

  test('fromEntity：entity 全 null（非缺欄位建構）→ UI 預設值', () {
    expect(
      DishCatalogModel.fromEntity(const DishCatalogComponent()),
      const DishCatalogModel(currency: 'TWD', dishes: []),
    );
  });
}
