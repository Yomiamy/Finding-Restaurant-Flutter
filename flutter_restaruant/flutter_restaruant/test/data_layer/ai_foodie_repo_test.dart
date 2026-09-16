import 'dart:convert';

import 'package:flutter_restaruant/data_layer/data_layer_barrel.dart';
import 'package:flutter_restaruant/domain/domain_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiFoodieSchema Tests', () {
    test('aiFoodieResponseSchema 包含完整的文字與元件約束', () {
      expect(aiFoodieResponseSchema.properties?['text'], isNotNull);
      expect(aiFoodieResponseSchema.properties?['components'], isNotNull);

      final componentsSchema = aiFoodieResponseSchema.properties?['components'];
      final itemSchema = componentsSchema?.items;
      expect(itemSchema, isNotNull);

      final componentTypeSchema = itemSchema?.properties?['component_type'];
      expect(componentTypeSchema, isNotNull);
      expect(componentTypeSchema?.enumValues, containsAll([
        'comparison_matrix',
        'action_chip_group',
        'decision_roulette',
      ]));
      expect(componentTypeSchema?.enumValues?.length, 3);
    });
  });

  group('AiFoodieRepo Unit Tests', () {
    test('askAssistant 正確解析包含對比與行動標籤之合法 JSON 回應', () async {
      final sampleJson = jsonEncode({
        'text': '已為您找到 2 間優質聚餐推薦：',
        'components': [
          {
            'component_type': 'comparison_matrix',
            'data': {
              'title': '精選對比',
              'items': [
                {
                  'id': 'rest_1',
                  'name': '頂級居酒屋',
                  'rating': 4.8,
                  'price': '\$600/人',
                  'highlights': ['氣氛極佳', '特色串燒'],
                  'address': '台北市中山區',
                  'category': '日式',
                },
              ],
            },
          },
          {
            'component_type': 'action_chip_group',
            'data': {
              'chips': [
                {
                  'label': '🎲 轉盤抽籤',
                  'action': 'open_roulette',
                  'payload': {
                    'title': '抽籤轉盤',
                    'options': ['頂級居酒屋', '狸御殿'],
                  },
                },
              ],
            },
          },
        ],
      });

      final repo = AiFoodieRepo(
        promptExecutor: (prompt, history) async => sampleJson,
      );

      final message = await repo.askAssistant('4人居酒屋');
      expect(message.isUser, isFalse);
      expect(message.text, '已為您找到 2 間優質聚餐推薦：');
      expect(message.components.length, 2);

      final comp1 = message.components[0];
      expect(comp1, isA<ComparisonMatrixComponent>());
      final matrix = comp1 as ComparisonMatrixComponent;
      expect(matrix.title, '精選對比');
      expect(matrix.items.length, 1);
      expect(matrix.items.first.name, '頂級居酒屋');

      final comp2 = message.components[1];
      expect(comp2, isA<ActionChipGroupComponent>());
      final chipGroup = comp2 as ActionChipGroupComponent;
      expect(chipGroup.chips.length, 1);
      expect(chipGroup.chips.first.action, 'open_roulette');
    });

    test('askAssistant 當推論異常時能平滑降級為本地智慧推薦，保證零崩潰', () async {
      final repo = AiFoodieRepo(
        promptExecutor: (prompt, history) async => throw Exception('網路連線逾時'),
      );

      final message = await repo.askAssistant('我想找居酒屋喝一杯');
      expect(message.isUser, isFalse);
      expect(message.text, contains('居酒屋'));
      expect(message.components.isNotEmpty, isTrue);
      expect(message.components.first, isA<ComparisonMatrixComponent>());
    });

    test('getInitialSuggestions 傳回預設歡迎語與互動標籤', () async {
      final repo = AiFoodieRepo();
      final suggestions = await repo.getInitialSuggestions();

      expect(suggestions.length, 1);
      expect(suggestions.first.isUser, isFalse);
      expect(suggestions.first.text, contains('AI 覓食助手'));
      expect(suggestions.first.components.length, 1);
      expect(suggestions.first.components.first, isA<ActionChipGroupComponent>());
    });

    test('多輪對話歷程中攜帶前輪元件的餐廳實體資訊', () async {
      List<AiFoodieMessage>? capturedHistory;
      final repo = AiFoodieRepo(
        promptExecutor: (prompt, history) async {
          capturedHistory = history;
          return jsonEncode({
            'text': '推薦您這兩家都很合適！',
            'components': <Object>[],
          });
        },
      );

      final prevAssistantMsg = AiFoodieMessage.assistant(
        text: '推薦以下兩家：',
        components: const [
          ComparisonMatrixComponent(
            title: '精選比對',
            items: [
              RestaurantComparisonItem(
                id: 'rest_101',
                name: '鼎泰豐',
                rating: 4.8,
                highlights: ['小籠包'],
              ),
            ],
          ),
        ],
      );

      await repo.askAssistant(
        '這家有訂位嗎？',
        history: [
          AiFoodieMessage.user('想吃小籠包'),
          prevAssistantMsg,
        ],
      );

      expect(capturedHistory, isNotNull);
      expect(capturedHistory!.length, 2);
      expect(capturedHistory![1].isAssistant, isTrue);
    });
  });

  group('A2UIComponent Schema Validation & Fallback Tests (反例測試)', () {
    test('comparison_matrix 缺少 items 或 items 為空時降級為 FallbackMarkdownComponent', () {
      final emptyMatrixJson = {
        'component_type': 'comparison_matrix',
        'data': {
          'title': '空比對清單',
          'items': <Object>[],
        },
      };

      final comp = A2UIComponent.fromJson(emptyMatrixJson);
      expect(comp, isA<FallbackMarkdownComponent>());
      expect((comp as FallbackMarkdownComponent).text, '空比對清單');
    });

    test('decision_roulette options 小於 2 時降級為 FallbackMarkdownComponent', () {
      final invalidRouletteJson = {
        'component_type': 'decision_roulette',
        'data': {
          'title': '單一選項轉盤',
          'options': ['只有一家無法轉'],
        },
      };

      final comp = A2UIComponent.fromJson(invalidRouletteJson);
      expect(comp, isA<FallbackMarkdownComponent>());
      expect((comp as FallbackMarkdownComponent).text, '單一選項轉盤');
    });

    test('action_chip_group 缺少必要 prompt 或 options 時自動過濾，無效時降級', () {
      final invalidChipsJson = {
        'component_type': 'action_chip_group',
        'data': {
          'chips': [
            {
              'label': '無效 query',
              'action': 'query',
              'payload': <String, Object?>{}, // 缺少 prompt
            },
            {
              'label': '無效 roulette',
              'action': 'open_roulette',
              'payload': {
                'title': '選項不足',
                'options': ['單店'], // 選項 < 2
              },
            },
          ],
        },
      };

      final comp = A2UIComponent.fromJson(invalidChipsJson);
      expect(comp, isA<FallbackMarkdownComponent>());
    });

    test('action_chip_group 包含部分有效項目時保留有效項目', () {
      final partiallyValidChipsJson = {
        'component_type': 'action_chip_group',
        'data': {
          'chips': [
            {
              'label': '無效 query',
              'action': 'query',
              'payload': <String, Object?>{},
            },
            {
              'label': '有效 query',
              'action': 'query',
              'payload': {'prompt': '我想吃拉麵'},
            },
          ],
        },
      };

      final comp = A2UIComponent.fromJson(partiallyValidChipsJson);
      expect(comp, isA<ActionChipGroupComponent>());
      final chipGroup = comp as ActionChipGroupComponent;
      expect(chipGroup.chips.length, 1);
      expect(chipGroup.chips.first.label, '有效 query');
    });
  });
}
