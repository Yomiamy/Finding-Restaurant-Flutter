import 'dart:convert';

import 'package:flutter_restaruant/data_layer/repositories/ai_foodie_repo.dart';
import 'package:flutter_restaruant/domain/entities/a2ui_fallback_strings.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

/// 特性測試：固定 entity 與分派器的現行可觀察行為。
/// 修改斷言的期望值＝行為改變，必須在 PR 中說明；替換測試替身或排版不受限制。
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
      expect(jsonEncode(parse(_Data.catalog).toEnvelopeJson()), _Data.catalogJson);
    });
    test('ComparisonMatrixComponent + RestaurantComparisonItem', () {
      expect(jsonEncode(parse(_Data.matrix).toEnvelopeJson()), _Data.matrixJson);
    });
    test('ActionChipGroupComponent + ActionChipItem', () {
      expect(jsonEncode(parse(_Data.chips).toEnvelopeJson()), _Data.chipsJson);
    });
    test('DecisionRouletteComponent', () {
      expect(jsonEncode(parse(_Data.roulette).toEnvelopeJson()), _Data.rouletteJson);
    });
    test('FallbackMarkdownComponent 扁平格式且 component_type 在第一個', () {
      expect(
        jsonEncode(parse({'component_type': 'mystery', 'text': '降級'}).toEnvelopeJson()),
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
        expect(parse(c.toEnvelopeJson()), c);
      });
    }
    test('FallbackMarkdownComponent', () {
      const c = FallbackMarkdownComponent(text: '降級');
      expect(parse(c.toEnvelopeJson()), c);
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

  group('純量型別錯誤拋 Exception（不拋 TypeError）', () {
    final checked = isA<CheckedFromJsonException>();
    final cases = <String, (void Function(), Matcher)>{
      'dish.name': (() => DishItemEntity.fromJson({'name': 123}), checked),
      'allergen.risk_level': (() => AllergenInfo.fromJson({'risk_level': 1}), checked),
      'catalog.restaurant_title': (() => parse({'component_type': 'dish_catalog', 'data': {'restaurant_title': 1}}), checked),
      'catalog.dishes 非 List': (() => parse({'component_type': 'dish_catalog', 'data': {'dishes': 'x'}}), checked),
      'item.name': (() => parse({'component_type': 'comparison_matrix', 'data': {'items': [{'name': 1}]}}), checked),
      'chip.label': (() => parse({'component_type': 'action_chip_group', 'data': {'chips': [{'label': 1}]}}), checked),
      'data 非 Map': (() => parse({'component_type': 'dish_catalog', 'data': 'x'}), isA<FormatException>()),
      'message.created_at': (() => AiFoodieMessage.fromJson({'created_at': 5}), checked),
    };
    cases.forEach((name, c) {
      final (body, matcher) = c;
      test(name, () => expect(body, throwsA(allOf(isA<Exception>(), matcher))));
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
