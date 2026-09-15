import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../../domain/entities/entities_barrel.dart';
import '../../domain/repositories/ai_foodie_repository.dart';

/// AI 推論執行函式簽章（便於測試與無網路/離線打樁）
typedef AiPromptFunction =
    Future<String> Function(String prompt, List<AiFoodieMessage>? history);

/// AI 覓食助理 Repository 實作
class AiFoodieRepo implements AiFoodieRepository {
  AiFoodieRepo({
    FirebaseAI? firebaseAI,
    AiPromptFunction? promptExecutor,
  })  : _firebaseAI = firebaseAI,
        _promptExecutor = promptExecutor;

  final FirebaseAI? _firebaseAI;
  final AiPromptFunction? _promptExecutor;

  static const String _systemInstruction = '''
你是一位擁有米其林指南品味、通曉在地街巷私房菜的專業 AI 覓食助理。
請針對使用者的用餐情境（如人數、預算、喜好、時間）：
1. 提供溫暖、專業且生動的自然語言推薦語。
2. 推薦 2~4 家符合條件的餐廳進行對比分析。
3. 提供後續行動建議（如地圖瀏覽、轉盤抽籤）。
一律以 JSON 格式回應，包含 text 與 components。
''';

  @override
  Future<List<AiFoodieMessage>> getInitialSuggestions() async {
    // 預設歡迎語與引導標籤
    final welcomeMessage = AiFoodieMessage.assistant(
      text: '嗨！我是你的專屬 AI 覓食助手 🍽️\n不管是 4 人聚餐想找安靜包廂、深夜想來碗熱呼呼的拉麵，或是約會不想踩雷，告訴我你的情境與預算，我來幫你精挑細選！',
      components: [
        const ActionChipGroupComponent(
          chips: [
            ActionChipItem(
              label: '🍢 4 人中山站居酒屋 (每人 \$600)',
              action: 'query',
              payload: {'prompt': '4 人在中山站想找適合聊天的居酒屋，每人預算約 600 元'},
            ),
            ActionChipItem(
              label: '🍷 氣氛佳約會西餐廳 (不限預算)',
              action: 'query',
              payload: {'prompt': '推薦兩個人約會氣氛好、適合拍照的法義西餐廳'},
            ),
            ActionChipItem(
              label: '🌙 深夜 12 點後的熱門宵夜',
              action: 'query',
              payload: {'prompt': '深夜食堂推薦，想吃熱炒或拉麵宵夜'},
            ),
            ActionChipItem(
              label: '💰 中午百元高 CP 值排隊小吃',
              action: 'query',
              payload: {'prompt': '推薦商業午餐高 CP 值的銅板美食'},
            ),
          ],
        ),
      ],
    );

    return [welcomeMessage];
  }

  @override
  Future<AiFoodieMessage> askAssistant(
    String prompt, {
    List<AiFoodieMessage>? history,
  }) async {
    if (_promptExecutor != null) {
      final rawResponse = await _promptExecutor(prompt, history);
      return _parseResponse(rawResponse);
    }

    try {
      final ai = _firebaseAI ?? FirebaseAI.googleAI();
      final model = ai.generativeModel(
        model: 'gemini-3.5-flash-lite',
        systemInstruction: Content.system(_systemInstruction),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final response = await model.generateContent([
        Content.text(prompt),
      ]);

      final text = response.text;
      if (text != null && text.isNotEmpty) {
        return _parseResponse(text);
      }
    } catch (_) {
      // 網路中斷或 API 異常時優雅降級為本地智慧推薦引擎
    }

    return _generateSmartFallback(prompt);
  }

  AiFoodieMessage _parseResponse(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson) as Map<String, Object?>;
      final text = decoded['text'] as String? ?? '為您整理出以下推薦：';
      final rawComponents = decoded['components'] as List<Object?>? ?? const [];
      final components = rawComponents
          .whereType<Map<String, Object?>>()
          .map(A2UIComponent.fromJson)
          .toList(growable: false);

      return AiFoodieMessage.assistant(
        text: text,
        components: components,
      );
    } catch (_) {
      return AiFoodieMessage.assistant(
        text: rawJson,
        components: [FallbackMarkdownComponent(text: rawJson)],
      );
    }
  }

  /// 本地確定性智慧兜底推論引擎
  AiFoodieMessage _generateSmartFallback(String prompt) {
    final lower = prompt.toLowerCase();

    if (lower.contains('居酒屋') || lower.contains('酒') || lower.contains('串燒')) {
      return AiFoodieMessage.assistant(
        text: '為您挑選了 3 間最適合聚會暢聊的優質居酒屋：',
        components: [
          const ComparisonMatrixComponent(
            title: '人氣居酒屋精選對比',
            items: [
              RestaurantComparisonItem(
                id: 'izakaya_1',
                name: '野武士炭火居酒屋',
                rating: 4.7,
                price: '\$550/人',
                highlights: ['串燒炭香十足', '梅酒與清酒種類極多', '半開放包廂適聚餐'],
                category: '日式居酒屋',
                address: '台北市中山區南京西路 12 巷 5 號',
              ),
              RestaurantComparisonItem(
                id: 'izakaya_2',
                name: '狸御殿和食酒場',
                rating: 4.5,
                price: '\$650/人',
                highlights: ['明太子烤山藥必點', '氣氛熱絡好聊天', '近捷運站步行 3 分鐘'],
                category: '日式料理',
                address: '台北市中山區中山北路一段 105 巷',
              ),
              RestaurantComparisonItem(
                id: 'izakaya_3',
                name: '鳥幸本格炭火串燒',
                rating: 4.6,
                price: '\$700/人',
                highlights: ['手作雞肉丸附生蛋黃', '環境靜謐精緻', '無煙燒烤技術'],
                category: '串燒酒吧',
                address: '台北市中山區林森北路 119 巷',
              ),
            ],
          ),
          const ActionChipGroupComponent(
            chips: [
              ActionChipItem(
                label: '📍 在地圖上標記這 3 間',
                action: 'show_on_map',
                payload: {'ids': ['izakaya_1', 'izakaya_2', 'izakaya_3']},
              ),
              ActionChipItem(
                label: '🎲 選擇困難？轉盤隨機挑一家',
                action: 'open_roulette',
                payload: {
                  'title': '今晚居酒屋命運轉盤',
                  'options': ['野武士炭火居酒屋', '狸御殿和食酒場', '鳥幸本格炭火串燒'],
                },
              ),
            ],
          ),
        ],
      );
    }

    if (lower.contains('約會') || lower.contains('浪漫') || lower.contains('義') || lower.contains('法')) {
      return AiFoodieMessage.assistant(
        text: '推薦 2 間燈光美、氣氛佳且口碑極高的浪漫約會餐廳：',
        components: [
          const ComparisonMatrixComponent(
            title: '浪漫約會餐廳對比',
            items: [
              RestaurantComparisonItem(
                id: 'date_1',
                name: 'Bistro 9 燭光小館',
                rating: 4.8,
                price: '\$1,200/人',
                highlights: ['手工黑松露義大利麵', '浪漫燭光花園座', '精選侍酒師餐酒搭配'],
                category: '義式餐酒館',
                address: '台北市大安區敦化南路一段 160 巷',
              ),
              RestaurantComparisonItem(
                id: 'date_2',
                name: 'L\'Atelier 精緻法式小館',
                rating: 4.6,
                price: '\$1,500/人',
                highlights: ['法式油封鴨腿外酥內嫩', '法式舒芙蕾驚艷', '低調隱密適合談心'],
                category: '法式料理',
                address: '台北市大安區仁愛路四段 27 巷',
              ),
            ],
          ),
          const ActionChipGroupComponent(
            chips: [
              ActionChipItem(
                label: '📍 在地圖上查看約會地點',
                action: 'show_on_map',
                payload: {'ids': ['date_1', 'date_2']},
              ),
              ActionChipItem(
                label: '🎲 轉盤交給命運決定',
                action: 'open_roulette',
                payload: {
                  'title': '約會餐廳命運二選一',
                  'options': ['Bistro 9 燭光小館', 'L\'Atelier 精緻法式小館'],
                },
              ),
            ],
          ),
        ],
      );
    }

    // 通用覓食推薦
    return AiFoodieMessage.assistant(
      text: '已為您精選評分最高且最具特色的熱門代表店家：',
      components: [
        const ComparisonMatrixComponent(
          title: '熱門精選餐廳對比',
          items: [
            RestaurantComparisonItem(
              id: 'top_1',
              name: '鼎泰豐 (信義旗艦店)',
              rating: 4.8,
              price: '\$450/人',
              highlights: ['黃金 18 摺小籠包', '排骨蛋炒飯粒粒分明', '極致貼心服務'],
              category: '台灣小吃點心',
              address: '台北市信義區市府路 45 號 B1',
            ),
            RestaurantComparisonItem(
              id: 'top_2',
              name: '阿城鵝肉 (吉林店)',
              rating: 4.6,
              price: '\$280/人',
              highlights: ['米其林必比登推薦', '煙燻鵝肉鮮甜多汁', '鵝油拌飯香氣濃郁'],
              category: '台菜小吃',
              address: '台北市中山區吉林路 105 號',
            ),
            RestaurantComparisonItem(
              id: 'top_3',
              name: '一蘭拉麵 (台灣台北本店)',
              rating: 4.5,
              price: '\$350/人',
              highlights: ['24 小時營業不打烊', '獨立味集中座位', '濃郁天然豚骨湯頭'],
              category: '日式拉麵',
              address: '台北市信義區松仁路 97 號',
            ),
          ],
        ),
        const ActionChipGroupComponent(
          chips: [
            ActionChipItem(
              label: '📍 在地圖上高亮這些餐廳',
              action: 'show_on_map',
              payload: {'ids': ['top_1', 'top_2', 'top_3']},
            ),
            ActionChipItem(
              label: '🎲 轉盤抽籤：今晚吃哪家？',
              action: 'open_roulette',
              payload: {
                'title': '今晚吃什麼？命運大轉盤',
                'options': ['鼎泰豐 (信義旗艦店)', '阿城鵝肉 (吉林店)', '一蘭拉麵 (台灣台北本店)'],
              },
            ),
          ],
        ),
      ],
    );
  }
}
