import 'dart:convert';

import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

/// 驗證 entity 改用 `@JsonSerializable` 後：缺欄位為 null、`toJson` 省略 null key。
void main() {
  group('AllergenInfo / DishItemEntity', () {
    test('缺值 → 欄位為 null（含 List 與 enum）', () {
      final a = AllergenInfo.fromJson(const {});
      expect([a.name, a.riskLevel, a.note], everyElement(isNull));
      final d = DishItemEntity.fromJson(const {});
      expect([
        d.id,
        d.name,
        d.originalName,
        d.price,
        d.category,
        d.allergens,
        d.dietaryTags,
        d.spiceLevel,
        d.ingredients,
        d.chefRecommendationScore,
      ], everyElement(isNull));
    });

    test('toJson 省略 null key，且不含 props/stringify/hashCode', () {
      expect(const AllergenInfo(name: '蛋').toJson(), {'name': '蛋'});
      expect(const DishItemEntity(name: 'A').toJson(), {'name': 'A'});
      expect(jsonEncode(const DishItemEntity().toJson()), '{}');
    });
  });

  group('A2UI 元件', () {
    test('缺值 → 欄位為 null（直接呼叫元件 fromJson，不經分派器）', () {
      final catalog = DishCatalogComponent.fromJson(const {});
      final matrix = ComparisonMatrixComponent.fromJson(const {});
      final item = RestaurantComparisonItem.fromJson(const {});
      final chip = ActionChipItem.fromJson(const {});
      final roulette = DecisionRouletteComponent.fromJson(const {});
      expect([
        catalog.restaurantTitle,
        catalog.currency,
        catalog.dishes,
        matrix.title,
        matrix.items,
        item.id,
        item.name,
        item.rating,
        item.price,
        item.highlights,
        item.address,
        item.category,
        item.imageUrl,
        ActionChipGroupComponent.fromJson(const {}).chips,
        chip.label,
        chip.action,
        chip.payload,
        roulette.title,
        roulette.options,
        const FallbackMarkdownComponent().text,
      ], everyElement(isNull));
    });

    test('toJson 省略 null key，且不含 isValid/props', () {
      expect(const DecisionRouletteComponent(options: ['A', 'B']).toJson(), {
        'component_type': 'decision_roulette',
        'data': {
          'options': ['A', 'B'],
        },
      });
      expect(const ActionChipItem(label: 'L').toJson(), {'label': 'L'});
      expect(const RestaurantComparisonItem(name: 'N').toJson(), {'name': 'N'});
      expect(const FallbackMarkdownComponent().toJson(), {
        'component_type': 'fallback_markdown',
      });
      expect(const FallbackMarkdownComponent(text: 't').toJson(), {
        'component_type': 'fallback_markdown',
        'text': 't',
      });
    });

    test('ActionChipGroupComponent.fromJson 不過濾，過濾只在分派器', () {
      final json = {
        'chips': [
          {'label': 'L', 'action': 'query'},
        ],
      };
      expect(ActionChipGroupComponent.fromJson(json).chips, hasLength(1));
      expect(
        A2UIComponent.fromJson({
          'component_type': 'action_chip_group',
          'data': json,
        }),
        isA<FallbackMarkdownComponent>(),
      );
    });

    test('isValid 接受 null 欄位且不拋例外', () {
      expect(const ActionChipItem(action: 'query').isValid, isFalse);
      expect(const ActionChipItem(label: 'L').isValid, isFalse);
      expect(
        const ActionChipItem(label: 'L', action: 'query').isValid,
        isFalse,
      );
      expect(
        const ActionChipItem(label: 'L', action: 'open_roulette').isValid,
        isFalse,
      );
      expect(
        const ActionChipItem(label: 'L', action: 'custom').isValid,
        isTrue,
      );
    });
  });

  group('AiFoodieMessage', () {
    test('缺值 → 欄位為 null（含 List）', () {
      final m = AiFoodieMessage.fromJson(const {});
      expect([
        m.id,
        m.isUser,
        m.text,
        m.components,
        m.createdAt,
      ], everyElement(isNull));
    });

    test('created_at 非法字串 → null（不拋例外）', () {
      expect(
        AiFoodieMessage.fromJson(const {'created_at': 'not-a-date'}).createdAt,
        isNull,
      );
    });

    test('toJson 省略 null key，且不含 is_assistant/props', () {
      expect(const AiFoodieMessage(text: 'x').toJson(), {'text': 'x'});
    });

    test('toJson key 順序 id/is_user/text/components/created_at', () {
      final json = AiFoodieMessage(
        id: 'm1',
        isUser: true,
        text: 't',
        components: const [],
        createdAt: DateTime.utc(2026, 9, 24, 12),
      ).toJson();
      expect(json.keys.toList(), [
        'id',
        'is_user',
        'text',
        'components',
        'created_at',
      ]);
    });

    test('.user() factory 明確給 components: []', () {
      expect(AiFoodieMessage.user('hi').components, isEmpty);
    });
  });
}
