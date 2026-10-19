import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReviewSummaryEntity Tests', () {
    test('完整 JSON 能正確反序列化為實體', () {
      final json = {
        'pros': ['海鮮新鮮', '出餐快速'],
        'cons': ['座位稍顯狹窄'],
        'highlights': ['招牌握壽司', '炙燒鮭魚'],
        'summary': '食材極度新鮮，適合熱愛壽司的老饕，唯尖峰時段需提早排隊。',
      };

      final entity = ReviewSummaryEntity.fromJson(json);

      expect(entity.pros, ['海鮮新鮮', '出餐快速']);
      expect(entity.cons, ['座位稍顯狹窄']);
      expect(entity.highlights, ['招牌握壽司', '炙燒鮭魚']);
      expect(entity.summary, '食材極度新鮮，適合熱愛壽司的老饕，唯尖峰時段需提早排隊。');
    });

    test('空 JSON 或 null 欄位能優雅降級為預設空集合', () {
      final json = <String, Object?>{};

      final entity = ReviewSummaryEntity.fromJson(json);

      expect(entity.pros, isEmpty);
      expect(entity.cons, isEmpty);
      expect(entity.highlights, isEmpty);
      expect(entity.summary, isEmpty);
    });

    test('序列化 toJson 結構正確', () {
      const entity = ReviewSummaryEntity(
        pros: ['服務親切'],
        cons: ['難停車'],
        highlights: ['松露燉飯'],
        summary: '整體氛圍佳。',
      );

      final json = entity.toJson();

      expect(json['pros'], ['服務親切']);
      expect(json['cons'], ['難停車']);
      expect(json['highlights'], ['松露燉飯']);
      expect(json['summary'], '整體氛圍佳。');
    });

    test('Equatable 相等性驗證', () {
      const entity1 = ReviewSummaryEntity(
        pros: ['A'],
        cons: ['B'],
        highlights: ['C'],
        summary: 'D',
      );
      const entity2 = ReviewSummaryEntity(
        pros: ['A'],
        cons: ['B'],
        highlights: ['C'],
        summary: 'D',
      );
      const entity3 = ReviewSummaryEntity(
        pros: ['A'],
        cons: ['B'],
        highlights: ['C'],
        summary: 'Different',
      );

      expect(entity1, equals(entity2));
      expect(entity1, isNot(equals(entity3)));
    });
  });
}
