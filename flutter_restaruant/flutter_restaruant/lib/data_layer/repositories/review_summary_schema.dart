import 'package:firebase_ai/firebase_ai.dart';

/// Gemini 評論情報結構化輸出 JSON 綱要 (Structured Output Schema)
///
/// 保證 Gemini 3.5 Flash Lite 輸出格式 100% 吻合的 pros, cons, highlights 與 summary。
final reviewSummarySchema = Schema.object(
  description: '餐廳評論智慧摘要與關鍵亮點分析結果',
  properties: {
    'pros': Schema.array(
      description: '值得一試（1~3 項核心優勢短評，如食材新鮮、服務周到）',
      items: Schema.string(),
    ),
    'cons': Schema.array(
      description: '注意事項或避雷點（1~2 項需留意之處，如尖峰排隊長、空間狹窄）',
      items: Schema.string(),
    ),
    'highlights': Schema.array(
      description: '招牌必點或特色菜品（1~3 項顧客最推薦的餐點）',
      items: Schema.string(),
    ),
    'summary': Schema.string(description: '一句話短評總結（40 字以內之精練客觀總結）'),
  },
  optionalProperties: ['cons'],
);
