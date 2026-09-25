import 'package:flutter_restaruant/domain/entities/a2ui_fallback_strings.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('A2UIComponent Tests', () {
    test('ComparisonMatrixComponent 正確序列化與反序列化', () {
      final json = {
        'component_type': 'comparison_matrix',
        'data': {
          'title': '居酒屋對比',
          'items': [
            {
              'id': 'res_1',
              'name': '野武士居酒屋',
              'rating': 4.7,
              'price': '\$550/人',
              'highlights': ['串燒極香', '包廂安靜'],
              'address': '台北市中山區',
              'category': '日式料理',
            },
          ],
        },
      };

      final comp = A2UIComponent.fromJson(json);
      expect(comp, isA<ComparisonMatrixComponent>());

      final matrix = comp as ComparisonMatrixComponent;
      expect(matrix.title, '居酒屋對比');
      expect(matrix.items, hasLength(1));
      expect(matrix.items?.first.name, '野武士居酒屋');
      expect(matrix.items?.first.rating, 4.7);
      expect(matrix.items?.first.highlights, contains('串燒極香'));

      final encoded = matrix.toEnvelopeJson();
      expect(encoded['component_type'], 'comparison_matrix');
    });

    test('ActionChipGroupComponent 正確序列化與反序列化', () {
      final json = {
        'component_type': 'action_chip_group',
        'data': {
          'chips': [
            {
              'label': '📍 在地圖上查看',
              'action': 'show_on_map',
              'payload': {'id': 'res_1'},
            },
            {
              'label': '🎲 轉盤抽籤',
              'action': 'open_roulette',
              'payload': {
                'options': ['A', 'B'],
              },
            },
          ],
        },
      };

      final comp = A2UIComponent.fromJson(json);
      expect(comp, isA<ActionChipGroupComponent>());

      final chipGroup = comp as ActionChipGroupComponent;
      expect(chipGroup.chips, hasLength(2));
      expect(chipGroup.chips?.first.label, '📍 在地圖上查看');
      expect(chipGroup.chips?.first.action, 'show_on_map');
      expect(chipGroup.chips?[1].action, 'open_roulette');
    });

    test('DecisionRouletteComponent 正確序列化與反序列化', () {
      final json = {
        'component_type': 'decision_roulette',
        'data': {
          'title': '今晚吃什麼',
          'options': ['拉麵', '火鍋', '居酒屋'],
        },
      };

      final comp = A2UIComponent.fromJson(json);
      expect(comp, isA<DecisionRouletteComponent>());

      final roulette = comp as DecisionRouletteComponent;
      expect(roulette.title, '今晚吃什麼');
      expect(roulette.options, ['拉麵', '火鍋', '居酒屋']);
    });

    test('未知元件類型安全降級為 FallbackMarkdownComponent', () {
      final json = {
        'component_type': 'future_unknown_component',
        'text': '未知的新版元件內容',
      };

      final comp = A2UIComponent.fromJson(json);
      expect(comp, isA<FallbackMarkdownComponent>());

      final fallback = comp as FallbackMarkdownComponent;
      expect(fallback.text, '未知的新版元件內容');
    });

    test('降級文字遇到空白字串時改用預設文字', () {
      final comp = A2UIComponent.fromJson({
        'component_type': 'dish_catalog',
        'text': ' ',
        'data': {'restaurant_title': '', 'dishes': <Object?>[]},
      });

      expect(
        (comp as FallbackMarkdownComponent).text,
        A2UIFallbackStrings.dishCatalogEmpty,
      );
    });

    test('AiFoodieMessage factory 與 JSON 轉換正確', () {
      final userMsg = AiFoodieMessage.user('我想吃拉麵');
      expect(userMsg.isUser, isTrue);
      expect(userMsg.text, '我想吃拉麵');
      expect(userMsg.components, isEmpty);

      final assistantMsg = AiFoodieMessage.assistant(
        text: '推薦這家拉麵',
        components: const [
          DecisionRouletteComponent(
            options: ['一蘭', '一風堂'],
            title: '今晚吃什麼？命運大轉盤',
          ),
        ],
      );
      expect(assistantMsg.isUser, isFalse);
      expect(assistantMsg.components, hasLength(1));

      final json = assistantMsg.toJson();
      final restored = AiFoodieMessage.fromJson(json);
      expect(restored.text, assistantMsg.text);
      expect(restored.components, hasLength(1));
      expect(restored.components?.first, isA<DecisionRouletteComponent>());
    });

    test('分派器：component_type 非字串拋 FormatException', () {
      expect(
        () => A2UIComponent.fromJson({'component_type': 1}),
        throwsA(isA<FormatException>()),
      );
    });

    test('分派器：降級分支 text 非字串拋 FormatException', () {
      expect(
        () => A2UIComponent.fromJson({'component_type': 'x', 'text': 1}),
        throwsA(isA<FormatException>()),
      );
    });

    test('isValid：payload 欄位型別錯誤視為不合法且不拋', () {
      const badQuery = ActionChipItem(
        label: 'q',
        action: 'query',
        payload: {'prompt': 1},
      );
      const badRoulette = ActionChipItem(
        label: 'r',
        action: 'open_roulette',
        payload: {'options': 'x'},
      );
      expect(badQuery.isValid, isFalse);
      expect(badRoulette.isValid, isFalse);
    });

    test('分派器：payload 型別錯誤的 chip 被過濾，全部不合法則降級', () {
      Map<String, Object?> group(List<Object?> chips) => {
        'component_type': 'action_chip_group',
        'data': {'chips': chips},
      };
      const good = {
        'label': 'ok',
        'action': 'query',
        'payload': {'prompt': '吃什麼'},
      };
      const bad = {
        'label': 'bad',
        'action': 'query',
        'payload': {'prompt': 1},
      };
      const badRoulette = {
        'label': 'r',
        'action': 'open_roulette',
        'payload': {'options': 'x'},
      };

      final kept = A2UIComponent.fromJson(group([good, bad, badRoulette]));
      expect(kept, isA<ActionChipGroupComponent>());
      expect((kept as ActionChipGroupComponent).chips?.map((c) => c.label), [
        'ok',
      ]);

      expect(
        A2UIComponent.fromJson(group([bad, badRoulette])),
        isA<FallbackMarkdownComponent>(),
      );
    });
  });
}
