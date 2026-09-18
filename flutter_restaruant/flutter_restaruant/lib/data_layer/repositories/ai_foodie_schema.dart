import 'package:firebase_ai/firebase_ai.dart';

/// Gemini 結構化輸出 JSON 綱要 (AI Foodie Assistant Structured Output Schema)
///
/// 保證 Gemini 輸出 100% 合法且符合 GenUI 契約規範的對話文字與元件列表，
/// 在 Token 採樣層物理杜絕未定義的 component_type。
///
/// 注意：因 OpenAPI 3.0 / Vertex AI 不支援針對 component_type 進行多態鑑別聯集 (discriminated unions)，
/// 共同承載欄位 (data, payload) 設為廣義容納，並由 Dart 實體層 (A2UIComponent.fromJson)
/// 實施嚴格的必要欄位檢查 (items/options/chips/prompt) 與 Fallback 防禦。
final aiFoodieResponseSchema = Schema.object(
  description: 'AI 覓食助理推薦與對話結果根物件',
  properties: {
    'text': Schema.string(
      description: '自然語言親切回覆、推薦理由與建議引言',
    ),
    'components': Schema.array(
      description: '結構化 GenUI 宣告式元件列表',
      items: Schema.object(
        description: '單一 GenUI 元件資料物件',
        properties: {
          'component_type': Schema.enumString(
            enumValues: [
              'comparison_matrix',
              'action_chip_group',
              'decision_roulette',
            ],
            description: '元件類型鑑別子，僅允許指定之三種合法元件',
          ),
          'data': Schema.object(
            description: '元件內部專屬承載資料',
            properties: {
              'title': Schema.string(
                description: '卡片或轉盤標題',
                nullable: true,
              ),
              'items': Schema.array(
                description:
                    '多店橫向比對餐廳項目列表 (comparison_matrix 必填，至少 2 項；'
                    '其他元件類型不使用此欄位)',
                nullable: true,
                items: Schema.object(
                  description: '餐廳比對卡片詳細資料',
                  properties: {
                    'id': Schema.string(description: '餐廳唯一識別碼'),
                    'name': Schema.string(description: '餐廳名稱'),
                    'rating': Schema.number(description: '評分 (0.0 - 5.0)'),
                    'price': Schema.string(
                      description: '人均價格 (例如: \$600/人)',
                      nullable: true,
                    ),
                    'highlights': Schema.array(
                      description: '特色亮點標籤列表',
                      items: Schema.string(),
                    ),
                    'address': Schema.string(
                      description: '餐廳地址',
                      nullable: true,
                    ),
                    'category': Schema.string(
                      description: '料理類別',
                      nullable: true,
                    ),
                    'image_url': Schema.string(
                      description: '餐廳圖片 URL',
                      nullable: true,
                    ),
                  },
                  optionalProperties: [
                    'price',
                    'address',
                    'category',
                    'image_url',
                  ],
                ),
              ),
              'chips': Schema.array(
                description:
                    '快捷行動標籤項目列表 (action_chip_group 必填，至少 1 項；'
                    '其他元件類型不使用此欄位)',
                nullable: true,
                items: Schema.object(
                  description: '單一行動標籤',
                  properties: {
                    'label': Schema.string(description: '標籤顯示文字 (含 Emoji)'),
                    'action': Schema.enumString(
                      enumValues: ['query', 'open_roulette'],
                      description: '動作類型代碼: "query" 或 "open_roulette"',
                    ),
                    'payload': Schema.object(
                      description: '動作對應承載資料 (必須包含對應 action 的必要欄位)',
                      properties: {
                        'prompt': Schema.string(
                          description:
                              '提問 Prompt (action 為 "query" 時必填且不可為空)',
                          nullable: true,
                        ),
                        'title': Schema.string(
                          description:
                              '轉盤標題 (action 為 "open_roulette" 時必填)',
                          nullable: true,
                        ),
                        'options': Schema.array(
                          description:
                              '轉盤候選餐廳名稱列表 (action 為 "open_roulette" 時必填，至少 2 項)',
                          nullable: true,
                          items: Schema.string(),
                        ),
                      },
                      optionalProperties: ['prompt', 'title', 'options'],
                    ),
                  },
                ),
              ),
              'options': Schema.array(
                description:
                    '命運轉盤候選餐廳名稱列表 (decision_roulette 必填，至少 2 項；'
                    '其他元件類型不使用此欄位)',
                nullable: true,
                items: Schema.string(),
              ),
            },
            optionalProperties: ['title', 'items', 'chips', 'options'],
          ),
        },
      ),
    ),
  },
  optionalProperties: ['components'],
);
