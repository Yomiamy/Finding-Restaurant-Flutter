import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
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
      expect(
        componentTypeSchema?.enumValues,
        containsAll([
          'comparison_matrix',
          'action_chip_group',
          'decision_roulette',
        ]),
      );
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
        promptExecutor: (prompt, history, {candidateRestaurants}) async =>
            sampleJson,
      );

      final message = await repo.askAssistant('4人居酒屋');
      expect(message.isUser, isFalse);
      expect(message.text, '已為您找到 2 間優質聚餐推薦：');
      expect(message.components.length, 2);

      final comp1 = message.components[0];
      expect(comp1, isA<ComparisonMatrixComponent>());
      final matrix = comp1 as ComparisonMatrixComponent;
      expect(matrix.title, '精選對比');
      expect(matrix.items, hasLength(1));
      expect(matrix.items?.first.name, '頂級居酒屋');

      final comp2 = message.components[1];
      expect(comp2, isA<ActionChipGroupComponent>());
      final chipGroup = comp2 as ActionChipGroupComponent;
      expect(chipGroup.chips, hasLength(1));
      expect(chipGroup.chips?.first.action, 'open_roulette');
    });

    test('askAssistant 自動過濾缺少對應 UI 資料的殘缺元件，避免畫面出現無效 Fallback 標籤', () async {
      final incompleteJson = jsonEncode({
        'text': '為您推薦餐廳：',
        'components': [
          {
            // comparison_matrix 缺少 items
            'component_type': 'comparison_matrix',
            'data': {'title': '空比對清單', 'items': <Object>[]},
          },
          {
            // action_chip_group 缺少有效 prompt / options
            'component_type': 'action_chip_group',
            'data': {
              'chips': [
                {
                  'label': '無效',
                  'action': 'query',
                  'payload': <String, Object?>{},
                },
              ],
            },
          },
          {
            // decision_roulette options 少於 2
            'component_type': 'decision_roulette',
            'data': {
              'title': '單選項轉盤',
              'options': ['只有一家'],
            },
          },
          {
            // 合法有效的 action chip
            'component_type': 'action_chip_group',
            'data': {
              'chips': [
                {
                  'label': '有效標籤',
                  'action': 'query',
                  'payload': {'prompt': '有效 prompt'},
                },
              ],
            },
          },
        ],
      });

      final repo = AiFoodieRepo(
        promptExecutor: (prompt, history, {candidateRestaurants}) async =>
            incompleteJson,
      );

      final message = await repo.askAssistant('推薦美食');
      expect(message.isUser, isFalse);
      expect(message.text, '為您推薦餐廳：');
      // 前 3 個缺資料的無效元件應全被過濾，只留下第 4 個有效元件
      expect(message.components.length, 1);
      expect(message.components.first, isA<ActionChipGroupComponent>());
      final chipGroup = message.components.first as ActionChipGroupComponent;
      expect(chipGroup.chips?.first.label, '有效標籤');
    });

    test('askAssistant 當推論異常且有傳入真實候選餐廳時，平滑降級為使用真實餐廳資訊產生對比與轉盤', () async {
      final repo = AiFoodieRepo(
        promptExecutor: (prompt, history, {candidateRestaurants}) async =>
            throw Exception('網路連線逾時'),
      );

      final candidates = [
        const RestaurantEntity(
          id: 'real_yelp_101',
          name: '老鄧擔擔麵',
          rating: 4.8,
          price: '\$200',
        ),
        const RestaurantEntity(
          id: 'real_yelp_102',
          name: '鼎泰豐信義店',
          rating: 4.9,
          price: '\$500',
        ),
      ];

      final message = await repo.askAssistant(
        '我想吃麵',
        candidateRestaurants: candidates,
      );
      expect(message.isUser, isFalse);
      expect(message.text, contains('周邊店家'));
      expect(message.components.isNotEmpty, isTrue);

      final matrix = message.components.first as ComparisonMatrixComponent;
      expect(matrix.items, hasLength(2));
      expect(matrix.items?.first.id, 'real_yelp_101');
      expect(matrix.items?.first.name, '老鄧擔擔麵');
      expect(matrix.items?[1].id, 'real_yelp_102');
      expect(matrix.items?[1].name, '鼎泰豐信義店');
    });

    test('askAssistant 當推論異常且無候選餐廳時能平滑降級為本地靜態智慧推薦，保證零崩潰', () async {
      final repo = AiFoodieRepo(
        promptExecutor: (prompt, history, {candidateRestaurants}) async =>
            throw Exception('網路連線逾時'),
      );

      final message = await repo.askAssistant('我想找居酒屋喝一杯');
      expect(message.isUser, isFalse);
      expect(message.text, contains('居酒屋'));
      expect(message.components.isNotEmpty, isTrue);
      expect(message.components.first, isA<ComparisonMatrixComponent>());
    });

    test('formatCandidateRestaurants 正確將真實餐廳序列化為包含真實 ID 與店名的條列上下文', () {
      final candidates = [
        const RestaurantEntity(
          id: 'yelp_1',
          name: '野武士',
          rating: 4.5,
          price: '\$600',
          location: RestaurantLocationEntity(address1: '中山北路一段'),
        ),
      ];

      final formatted = AiFoodieRepo.formatCandidateRestaurants(candidates);
      expect(formatted, contains('[ID: yelp_1] 名稱: 野武士'));
      expect(formatted, contains('評分: 4.5★'));
      expect(formatted, contains('價位: \$600'));
      expect(formatted, contains('地址: 中山北路一段'));
    });

    test('getInitialSuggestions 傳回預設歡迎語與互動標籤', () async {
      final repo = AiFoodieRepo();
      final suggestions = await repo.getInitialSuggestions();

      expect(suggestions.length, 1);
      expect(suggestions.first.isUser, isFalse);
      expect(suggestions.first.text, contains('AI 覓食助手'));
      expect(suggestions.first.components.length, 1);
      expect(
        suggestions.first.components.first,
        isA<ActionChipGroupComponent>(),
      );
    });

    test(
      '多輪對話歷程中 formatAssistantHistory 正確序列化為符合 Schema 之 JSON 格式並保留元件實體',
      () async {
        final repo = AiFoodieRepo();

        // 1. 驗證空 components 序列化為合規 JSON 且保留純文字
        final plainMsg = AiFoodieMessage.assistant(text: '你好，想吃什麼？');
        final plainJson =
            jsonDecode(repo.formatAssistantHistory(plainMsg))
                as Map<String, Object?>;
        expect(plainJson['text'], '你好，想吃什麼？');
        expect(plainJson['components'], isEmpty);

        // 2. 驗證 ComparisonMatrixComponent 包含餐廳名稱、ID 與詳細資料
        final matrixMsg = AiFoodieMessage.assistant(
          text: '推薦以下餐廳：',
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
                RestaurantComparisonItem(
                  id: 'rest_102',
                  name: '阜杭豆漿',
                  rating: 4.6,
                  highlights: ['厚餅夾蛋'],
                ),
              ],
            ),
          ],
        );

        final formattedMatrix = repo.formatAssistantHistory(matrixMsg);
        final matrixJson = jsonDecode(formattedMatrix) as Map<String, Object?>;
        expect(matrixJson['text'], '推薦以下餐廳：');
        final components = matrixJson['components'] as List<Object?>;
        expect(components.length, 1);
        final firstComp = components.first as Map<String, Object?>;
        expect(firstComp['component_type'], 'comparison_matrix');
        final compData = firstComp['data'] as Map<String, Object?>;
        final items = compData['items'] as List<Object?>;
        expect(items.length, 2);
        expect((items[0] as Map<String, Object?>)['id'], 'rest_101');
        expect((items[0] as Map<String, Object?>)['name'], '鼎泰豐');
        expect((items[1] as Map<String, Object?>)['id'], 'rest_102');
        expect((items[1] as Map<String, Object?>)['name'], '阜杭豆漿');

        // 3. 驗證 DecisionRouletteComponent 包含轉盤候選選項
        final rouletteMsg = AiFoodieMessage.assistant(
          text: '幫您挑選出以下候選：',
          components: const [
            DecisionRouletteComponent(
              title: '今晚吃什麼',
              options: ['野武士居酒屋', '狸御殿和食酒場'],
            ),
          ],
        );

        final formattedRoulette = repo.formatAssistantHistory(rouletteMsg);
        final rouletteJson =
            jsonDecode(formattedRoulette) as Map<String, Object?>;
        expect(rouletteJson['text'], '幫您挑選出以下候選：');
        final rouletteComps = rouletteJson['components'] as List<Object?>;
        expect(rouletteComps.length, 1);
        final rouletteData =
            (rouletteComps.first as Map<String, Object?>)['data']
                as Map<String, Object?>;
        expect(rouletteData['options'], containsAll(['野武士居酒屋', '狸御殿和食酒場']));
      },
    );

    test('buildConversationContents 自動剔除開頭無前置提問的助理歡迎語，確保對話首輪必為 user 且嚴格交替', () {
      final welcome = AiFoodieMessage.assistant(text: '歡迎光臨');
      final user1 = AiFoodieMessage.user('想吃火鍋');
      final assistant1 = AiFoodieMessage.assistant(text: '推薦海底撈');

      // 僅有歡迎語時，過濾後首輪即為當前 finalPrompt
      final singleTurn = AiFoodieRepo.buildConversationContents([
        welcome,
      ], '我想吃拉麵');
      expect(singleTurn.length, 1);
      expect(singleTurn.first.parts.first, isA<TextPart>());
      expect((singleTurn.first.parts.first as TextPart).text, '我想吃拉麵');

      // 多輪歷程：剔除 leading welcome，形成 user -> model -> user 嚴格交替
      final multiTurn = AiFoodieRepo.buildConversationContents([
        welcome,
        user1,
        assistant1,
      ], '還有別的嗎？');
      expect(multiTurn.length, 3);
      expect((multiTurn[0].parts.first as TextPart).text, '想吃火鍋');
      expect((multiTurn[1].parts.first as TextPart).text, contains('推薦海底撈'));
      expect((multiTurn[2].parts.first as TextPart).text, '還有別的嗎？');
    });
  });

  group('A2UIComponent Schema Validation & Fallback Tests (反例測試)', () {
    test(
      'comparison_matrix 缺少 items 或 items 為空時降級為 FallbackMarkdownComponent',
      () {
        final emptyMatrixJson = {
          'component_type': 'comparison_matrix',
          'data': {'title': '空比對清單', 'items': <Object>[]},
        };

        final comp = A2UIComponent.fromJson(emptyMatrixJson);
        expect(comp, isA<FallbackMarkdownComponent>());
        expect((comp as FallbackMarkdownComponent).text, '空比對清單');
      },
    );

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
      expect(chipGroup.chips, hasLength(1));
      expect(chipGroup.chips?.first.label, '有效 query');
    });
  });
}
