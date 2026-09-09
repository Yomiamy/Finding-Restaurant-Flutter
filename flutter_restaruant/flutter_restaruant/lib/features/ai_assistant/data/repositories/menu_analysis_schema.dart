import 'package:firebase_ai/firebase_ai.dart';

/// Gemini 結構化輸出 JSON 綱要 (Structured Output Schema)
///
/// 保證 Gemini 2.5 Flash 輸出 100% 格式合法且型別一致的菜單與過敏原資料。
final menuAnalysisSchema = Schema.object(
  description: '菜單與過敏原分析結果根物件',
  properties: {
    'restaurant_title': Schema.string(
      description: '辨識出的餐廳或菜單標題名稱',
      nullable: true,
    ),
    'currency': Schema.string(
      description: '貨幣符號或代碼 (如 TWD, JPY, USD)',
      nullable: true,
    ),
    'dishes': Schema.array(
      description: '辨識與翻譯出的所有菜色列表',
      items: Schema.object(
        description: '單道菜色詳細資料',
        properties: {
          'id': Schema.string(description: '菜色唯一識別碼 (kebab-case)'),
          'name': Schema.string(description: '繁體中文菜名翻譯'),
          'original_name': Schema.string(description: '菜單上的原文菜名'),
          'category': Schema.enumString(
            enumValues: [
              'appetizer',
              'main',
              'soup',
              'dessert',
              'beverage',
              'other',
            ],
            description: '菜色分類',
          ),
          'price': Schema.number(description: '價格數字，若無價格則填 0'),
          'ingredients': Schema.array(
            description: '推論之主要食材列表',
            items: Schema.string(),
          ),
          'allergens': Schema.array(
            description: '潛在過敏原列表',
            items: Schema.object(
              description: '單一過敏原資訊',
              properties: {
                'name': Schema.string(
                  description:
                      '過敏原名稱 (如 堅果, 甲殼類, 蛋, 牛奶, 麩質, 花生, 大豆)',
                ),
                'risk_level': Schema.enumString(
                  enumValues: ['contains', 'may_contain', 'none'],
                  description: '過敏原風險等級',
                ),
                'note': Schema.string(
                  description: '過敏原備註說明',
                  nullable: true,
                ),
              },
              optionalProperties: ['note'],
            ),
          ),
          'spice_level': Schema.integer(
            description: '辣度等級 (0: 不辣, 1: 微辣, 2: 中辣, 3: 大辣)',
          ),
          'dietary_tags': Schema.array(
            description:
                '飲食偏好標籤 (如 vegan, vegetarian, gluten-free, halal)',
            items: Schema.string(),
          ),
          'chef_recommendation_score': Schema.number(
            description: '推薦指數 (0.0 - 1.0)',
            nullable: true,
          ),
        },
        optionalProperties: [
          'ingredients',
          'dietary_tags',
          'chef_recommendation_score',
        ],
      ),
    ),
  },
  optionalProperties: ['restaurant_title', 'currency'],
);
