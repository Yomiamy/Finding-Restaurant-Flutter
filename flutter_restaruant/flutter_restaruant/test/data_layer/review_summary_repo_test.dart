import 'dart:convert';

import 'package:flutter_restaruant/data_layer/models/model_barrel.dart';
import 'package:flutter_restaruant/data_layer/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReviewSummarySchema Tests', () {
    test('reviewSummarySchema 包含完整的 pros, cons, highlights 與 summary 屬性', () {
      expect(reviewSummarySchema.properties?['pros'], isNotNull);
      expect(reviewSummarySchema.properties?['cons'], isNotNull);
      expect(reviewSummarySchema.properties?['highlights'], isNotNull);
      expect(reviewSummarySchema.properties?['summary'], isNotNull);

      expect(reviewSummarySchema.optionalProperties, contains('cons'));
    });
  });

  group('ReviewSummaryRepo Unit Tests', () {
    const detail = RestaurantDetailEntity(
      name: '極味壽司割烹',
      rating: 4.8,
      reviewCount: 120,
      categories: [RestaurantCategoryEntity(title: '日本料理')],
      location: RestaurantLocationEntity(address1: '台北市中山區晴光街 1 號'),
    );

    const reviews = [
      ReviewDetailEntity(
        id: 'rev_1',
        rating: 5,
        text: '生魚片厚度十足且非常新鮮，特別推薦招牌海膽軍艦！',
        timeCreated: '2026-10-18 19:30:00',
        user: ReviewerEntity(name: 'Alice'),
      ),
      ReviewDetailEntity(
        id: 'rev_2',
        rating: 4,
        text: '座位只有 10 席，建議務必提早預約，師傅握壽司手藝極佳。',
        timeCreated: '2026-10-17 12:00:00',
        user: ReviewerEntity(name: 'Bob'),
      ),
    ];

    test('formatPrompt 能正確組裝餐廳資訊與評論內容', () {
      final prompt = ReviewSummaryRepo.formatPrompt(detail, reviews);

      expect(prompt, contains('極味壽司割烹'));
      expect(prompt, contains('4.8★'));
      expect(prompt, contains('台北市中山區晴光街 1 號'));
      expect(prompt, contains('日本料理'));
      expect(prompt, contains('Alice'));
      expect(prompt, contains('生魚片厚度十足'));
      expect(prompt, contains('Bob'));
      expect(prompt, contains('座位只有 10 席'));
      expect(prompt, contains('<customer_reviews>'));
      expect(prompt, contains('</customer_reviews>'));
      expect(prompt, contains('<review index="1"'));
      expect(prompt, contains('繁體中文 (zh-TW)'));
    });

    test('parseResponse 能正確解析合法的 JSON 字串', () {
      final rawJson = jsonEncode({
        'pros': ['食材極為新鮮', '師傅手藝純熟'],
        'cons': ['座位少需提早排隊'],
        'highlights': ['招牌海膽軍艦'],
        'summary': '頂級海味體驗，極致新鮮。',
      });

      final entity = ReviewSummaryRepo.parseResponse(rawJson);

      expect(entity.pros, ['食材極為新鮮', '師傅手藝純熟']);
      expect(entity.cons, ['座位少需提早排隊']);
      expect(entity.highlights, ['招牌海膽軍艦']);
      expect(entity.summary, '頂級海味體驗，極致新鮮。');
    });

    test('parseResponse 遇到非 Map 結構時拋出 FormatException', () {
      expect(
        () => ReviewSummaryRepo.parseResponse('["invalid", "array"]'),
        throwsA(isA<FormatException>()),
      );
    });

    test('generateReviewSummary 當短評為空時短路回傳空實體，不執行 promptExecutor', () async {
      var executed = false;
      final repo = ReviewSummaryRepo(
        promptExecutor: (d, r) async {
          executed = true;
          return '{}';
        },
      );

      final result = await repo.generateReviewSummary(
        detail: detail,
        reviews: const [],
      );

      expect(executed, isFalse);
      expect(result, equals(const ReviewSummaryEntity()));
    });

    test('generateReviewSummary 透過 promptExecutor 正常生成評論情報', () async {
      final repo = ReviewSummaryRepo(
        promptExecutor: (d, r) async {
          expect(d.name, '極味壽司割烹');
          expect(r.length, 2);
          return jsonEncode({
            'pros': ['海產直送'],
            'cons': ['尖峰候位長'],
            'highlights': ['干貝握壽司'],
            'summary': '值得一試的精緻料理。',
          });
        },
      );

      final result = await repo.generateReviewSummary(
        detail: detail,
        reviews: reviews,
      );

      expect(result.pros, ['海產直送']);
      expect(result.cons, ['尖峰候位長']);
      expect(result.highlights, ['干貝握壽司']);
      expect(result.summary, '值得一試的精緻料理。');
    });

    test('generateReviewSummary 當模型推論失敗時記錄並 rethrow', () async {
      final repo = ReviewSummaryRepo(
        promptExecutor: (d, r) async {
          throw Exception('Gemini 429 quota exceeded');
        },
      );

      expect(
        () => repo.generateReviewSummary(detail: detail, reviews: reviews),
        throwsA(isA<Exception>()),
      );
    });
  });
}
