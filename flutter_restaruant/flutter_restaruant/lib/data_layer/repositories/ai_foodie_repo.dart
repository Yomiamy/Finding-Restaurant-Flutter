import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:meta/meta.dart';

import '../../domain/entities/entities_barrel.dart';
import '../../domain/repositories/ai_foodie_repository.dart';
import 'ai_foodie_schema.dart';

/// AI 推論執行函式簽章（便於測試與無網路/離線打樁）
typedef AiPromptFunction =
    Future<String> Function(
      String prompt,
      List<AiFoodieMessage>? history, {
      List<RestaurantEntity>? candidateRestaurants,
    });

/// AI 覓食助理 Repository 實作
class AiFoodieRepo implements AiFoodieRepository {
  AiFoodieRepo({FirebaseAI? firebaseAI, AiPromptFunction? promptExecutor})
    : _firebaseAI = firebaseAI,
      _promptExecutor = promptExecutor;

  final FirebaseAI? _firebaseAI;
  final AiPromptFunction? _promptExecutor;

  static const String _systemInstruction = '''
你是一位擁有米其林指南品味、通曉在地街巷私房菜的專業 AI 覓食助理。
請針對使用者的用餐情境（如人數、預算、喜好、時間）：
1. 提供簡短溫暖的自然語言引言 (text)，字數 ≤ 80 字。所有餐廳詳細資料一律留給 components，嚴禁在 text 中條列或重複。
2. 挑選 2~3 家符合條件的餐廳封裝在 components 陣列中 (comparison_matrix)。
3. 提供後續行動建議（快捷標籤 action_chip_group 或轉盤抽籤 decision_roulette）。

【真實店家接地約束 (Grounding Constraint) — 關鍵原則】
- 若使用者提示中附帶了【目前已加載的周邊真實候選餐廳名單】：
  * 推薦與比對的店家【必須且只能】從該名單挑選！
  * 嚴禁捏造名單以外的餐廳、嚴禁隨意編造假 ID！
  * comparison_matrix 中的 id 必須與名單中的真實 ID 完全一致（前端需透過真實 ID 跳轉店家詳細頁）！
  * 轉盤 options 也必須使用名單中的真實店名。
  * 若名單中無完全符合者，可推薦最接近者並在 text 中說明；切勿捏造虛構店家。
- 若未提供候選餐廳名單，則給予一般性餐飲建議與文字指引，不要產出 comparison_matrix。

【職責嚴格切分與防重複約束 (Strict Role Separation & Anti-Repetition) — 杜絕自我複讀】
- text 的單一職責：
  * 僅能作為情境總結或推薦引言（例如：「針對您想找中山站適合聊天的居酒屋，為您精選兩家氣氛熱絡的店家：」）。
  * 【絕對禁止】在 text 提及或條列任何餐廳細節（店名、地址、電話、評分、價格、菜色）！
  * 所有具體的店家比對與資訊【必須且只能】封裝在 components 的 comparison_matrix 中。
  * 【絕對禁止】自我複讀：嚴禁重複輸出相同的詞彙、句子或無意義的循環贅字。
- components 的單一職責：
  * comparison_matrix 內的 items 嚴禁包含重複店家。
  * action_chip_group 的 chips 嚴禁出現重複標籤。
  * decision_roulette 的 options 嚴禁出現重複選項。

【長度與容量硬性限制 — 杜絕 Payload 超限】
為避免傳輸負載過大 (Payload dropped: exceeded size limit)，必須嚴格控制輸出規模：
- 自然語言推薦語 (text)：精簡扼要，繁體中文嚴格限制在 80 字以內，禁止冗長開場與客套話。
- 元件列表 (components)：陣列總長度嚴格限制最多 2 個元件。
- 餐廳比對 (comparison_matrix)：
  * title 長度：嚴格限制在 10 個字以內（例如「精選店家對比」）。絕對禁止串接同義詞與長篇大論！
  * items 數量：嚴格限制 2~3 家。
  * 每家 highlights：嚴格限制 1~2 項短標籤，每項長度不得超過 10 個字。
  * address / price / category：簡短填寫，不可冗長。
- 快捷標籤 (action_chip_group)：
  * chips 數量：嚴格限制 2~3 個。
  * label 長度：不得超過 15 個字（含 Emoji）。
  * prompt 長度：不得超過 30 個字。
- 命運轉盤 (decision_roulette)：
  * options 數量：嚴格限制 2~4 個簡短店名。
  * title 長度：嚴格限制在 10 個字以內。絕對禁止串接同義詞與長篇大論！

【嚴格元件型別規範】
components 陣列內的每個物件必須包含 component_type 與 data：
- component_type 嚴格限定為下列三者之一：
  1. "comparison_matrix": 多店橫向評分與特色對比 (data 內部【絕對必須】包含 items 陣列，嚴禁省略！)
  2. "action_chip_group": 快捷行動按鈕 (data 包含 chips 陣列，action 為 "query" 或 "open_roulette")
  3. "decision_roulette": 命運轉盤隨機抽籤 (data 包含 title 與 options 陣列)

【各元件最低資料門檻 — 不符合即禁止產出該元件，改用 text 描述】

1. comparison_matrix:
   ✅ data.items 至少 2 筆餐廳。
   ✅ 每筆須含 id、name、rating、highlights（至少 1 項）。
   ❌ items 為空陣列或少於 2 筆 → 禁止輸出此元件。

2. action_chip_group:
   ✅ data.chips 至少 1 筆。
   ✅ 每筆須含非空 label、合法 action（"query" 或 "open_roulette"）。
   ✅ action 為 "query" 時 payload 須含非空 prompt。
   ✅ action 為 "open_roulette" 時 payload 須含 title 與至少 2 項 options。
   ❌ chips 為空陣列 → 禁止輸出此元件。

3. decision_roulette:
   ✅ data.options 至少 2 項非空字串。
   ✅ data.title 須為非空字串。
   ❌ options 少於 2 項 → 禁止輸出此元件。

一律以符合定義 Schema 的 JSON 格式回應。
''';

  @override
  Future<List<AiFoodieMessage>> getInitialSuggestions() async {
    // 預設歡迎語與引導標籤
    final welcomeMessage = AiFoodieMessage.assistant(
      text:
          '嗨！我是你的專屬 AI 覓食助手 🍽️\n不管是 4 人聚餐想找安靜包廂、深夜想來碗熱呼呼的拉麵，或是約會不想踩雷，告訴我你的情境與預算，我來幫你精挑細選！',
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
    List<RestaurantEntity>? candidateRestaurants,
  }) async {
    try {
      if (_promptExecutor != null) {
        final rawResponse = await _promptExecutor(
          prompt,
          history,
          candidateRestaurants: candidateRestaurants,
        );
        return _parseResponse(rawResponse);
      }

      final ai = _firebaseAI ?? FirebaseAI.googleAI();
      final model = ai.generativeModel(
        model: 'gemini-3.5-flash-lite',
        systemInstruction: Content.system(_systemInstruction),
        generationConfig: GenerationConfig(
          temperature: 0.2,
          responseMimeType: 'application/json',
          responseSchema: aiFoodieResponseSchema,
        ),
      );

      final candidateContext = formatCandidateRestaurants(
        candidateRestaurants ?? const [],
      );
      final finalPrompt = candidateContext.isNotEmpty
          ? '$candidateContext\n【使用者情境需求】: $prompt\n【指示】: 請依上述真實候選店家進行推薦與比對，嚴格使用其真實 ID。text 僅需 1 句簡短引言，嚴禁在 text 中條列店名與重複細節，全部交由 components 呈現。'
          : prompt;

      final contents = buildConversationContents(history, finalPrompt);

      final response = await model.generateContent(contents);

      final text = response.text;
      if (text != null && text.isNotEmpty) {
        return _parseResponse(text);
      }
    } catch (_) {
      // 網路中斷或 API 異常時優雅降級為本地智慧推薦引擎
    }

    return _generateSmartFallback(
      prompt,
      candidateRestaurants: candidateRestaurants,
    );
  }

  /// 將已載入的候選餐廳格式化為精簡接地上下文
  @visibleForTesting
  static String formatCandidateRestaurants(
    List<RestaurantEntity> restaurants, {
    int limit = 15,
  }) {
    if (restaurants.isEmpty) return '';

    final buffer = StringBuffer(
      '【目前已加載的周邊真實候選餐廳名單（嚴格要求：推薦與比對只能從以下名單挑選，必須使用真實對應的 ID，嚴禁捏造！）】:\n',
    );
    final selected = restaurants
        .where(
          (r) => (r.id?.isNotEmpty ?? false) && (r.name?.isNotEmpty ?? false),
        )
        .take(limit);

    for (final res in selected) {
      final rating = res.rating != null ? '${res.rating}★' : '無評分';
      final price = res.price ?? '';
      final category =
          res.categories
              ?.map((c) => c.title)
              .whereType<String>()
              .where((s) => s.isNotEmpty)
              .join('/') ??
          '';
      final address = res.location?.address1 ?? '';

      buffer.write('- [ID: ${res.id}] 名稱: ${res.name} | 評分: $rating');
      if (price.isNotEmpty) buffer.write(' | 價位: $price');
      if (category.isNotEmpty) buffer.write(' | 類型: $category');
      if (address.isNotEmpty) buffer.write(' | 地址: $address');
      buffer.writeln();
    }
    return buffer.toString();
  }

  /// 建構符合 Gemini 多輪對話規格之 Contents 列表
  ///
  /// 自動剔除開頭無前置使用者提問的助理問候訊息，確保對話首輪必為 user，且維持嚴格交替。
  @visibleForTesting
  static List<Content> buildConversationContents(
    List<AiFoodieMessage>? history,
    String finalPrompt,
  ) {
    final contents = <Content>[];
    if (history != null && history.isNotEmpty) {
      final sanitizedHistory = history
          .skipWhile((m) => m.isUser != true)
          .toList(growable: false);

      for (final msg in sanitizedHistory) {
        if (msg.isUser == true) {
          contents.add(Content.text(msg.text ?? ''));
        } else {
          contents.add(
            Content.model([TextPart(serializeAssistantHistory(msg))]),
          );
        }
      }
    }
    contents.add(Content.text(finalPrompt));
    return contents;
  }

  /// 將助理訊息及其攜帶的元件實體序列化為符合 Schema 之 JSON 格式，維護對話歷史語意與結構一致性
  @visibleForTesting
  String formatAssistantHistory(AiFoodieMessage msg) =>
      serializeAssistantHistory(msg);

  /// 序列化助理訊息為符合 Schema 之 JSON 字串
  @visibleForTesting
  static String serializeAssistantHistory(AiFoodieMessage msg) {
    final validComponents = (msg.components ?? const [])
        .where((c) => c is! FallbackMarkdownComponent)
        .map((c) => c.toJson())
        .toList(growable: false);

    final payload = <String, Object?>{
      'text': msg.text ?? '',
      'components': validComponents,
    };
    return jsonEncode(payload);
  }

  AiFoodieMessage _parseResponse(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson) as Map<String, Object?>;
      final text = decoded['text'] as String? ?? '為您整理出以下推薦：';
      final rawComponents = decoded['components'] as List<Object?>? ?? const [];
      final components = rawComponents
          .whereType<Map<String, Object?>>()
          .map(A2UIComponent.fromJson)
          .where((comp) => comp is! FallbackMarkdownComponent)
          .toList(growable: false);

      return AiFoodieMessage.assistant(text: text, components: components);
    } catch (_) {
      return AiFoodieMessage.assistant(
        text: rawJson,
        components: [FallbackMarkdownComponent(text: rawJson)],
      );
    }
  }

  /// 本地確定性智慧兜底推論引擎
  AiFoodieMessage _generateSmartFallback(
    String prompt, {
    List<RestaurantEntity>? candidateRestaurants,
  }) {
    if (candidateRestaurants != null && candidateRestaurants.isNotEmpty) {
      final valid = candidateRestaurants
          .where(
            (r) => (r.id?.isNotEmpty ?? false) && (r.name?.isNotEmpty ?? false),
          )
          .take(3)
          .toList(growable: false);

      if (valid.length >= 2) {
        final items = valid
            .map((r) {
              final cat =
                  r.categories
                      ?.map((c) => c.title)
                      .whereType<String>()
                      .join('/') ??
                  '';
              return RestaurantComparisonItem(
                id: r.id,
                name: r.name,
                rating: r.rating ?? 4.5,
                price: r.price,
                highlights: cat.isNotEmpty ? [cat, '精選推薦'] : const ['精選推薦'],
                category: cat.isNotEmpty ? cat : null,
                address: r.location?.address1,
                imageUrl: r.imageUrl,
              );
            })
            .toList(growable: false);

        return AiFoodieMessage.assistant(
          text: '已為您從目前加載的周邊店家精選推薦：',
          components: [
            ComparisonMatrixComponent(title: '周邊推薦餐廳對比', items: items),
            ActionChipGroupComponent(
              chips: [
                ActionChipItem(
                  label: '🎲 轉盤抽籤：今晚吃哪家？',
                  action: 'open_roulette',
                  payload: {
                    'title': '今晚吃什麼？命運大轉盤',
                    'options': items
                        .map((e) => e.name)
                        .nonNulls
                        .toList(growable: false),
                  },
                ),
              ],
            ),
          ],
        );
      }
    }

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
                label: '🍢 查看必點招牌下酒菜',
                action: 'query',
                payload: {'prompt': '推薦這幾家居酒屋最受歡迎的必點招牌下酒菜'},
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

    if (lower.contains('約會') ||
        lower.contains('浪漫') ||
        lower.contains('義') ||
        lower.contains('法')) {
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
                label: '🍷 詢問穿著與訂位注意事項',
                action: 'query',
                payload: {'prompt': '這兩家約會餐廳有服儀限制 (Dress Code) 或低消嗎？'},
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
              label: '🥢 推薦排隊小吃與熱門時段',
              action: 'query',
              payload: {'prompt': '這些人氣餐廳哪些時段比較不用排隊？'},
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
