import 'package:flutter_restaruant/api/dto/yelp_review_highlights_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

class _Data {
  static const String photo =
      'https://s3-media0.fl.yelpcdn.com/bphoto/abc/o.jpg';
  static const String sentence =
      'The [[HIGHLIGHT]]good[[ENDHIGHLIGHT]] food and service.';

  static const Map<String, dynamic> full = {
    'review_highlights': [
      {'photo': photo, 'sentence': sentence, 'review_count': 3},
    ],
  };
}

void main() {
  group('YelpReviewHighlightsDto', () {
    test('完整欄位逐欄解析，sentence 的 HIGHLIGHT 標記保持原字串', () {
      final dto = YelpReviewHighlightsDto.fromJson(_Data.full);
      expect(dto.reviewHighlights, hasLength(1));
      final h = dto.reviewHighlights?.first;
      expect(h?.photo, _Data.photo);
      expect(h?.sentence, _Data.sentence);
      expect(h?.sentence, contains('[[HIGHLIGHT]]good[[ENDHIGHLIGHT]]'));
      expect(h?.reviewCount, 3);
    });

    test('空 map 時所有欄位為 null', () {
      expect(
        YelpReviewHighlightsDto.fromJson(const {}).reviewHighlights,
        isNull,
      );

      // 元素要寫成 <String, dynamic>{}：裸 {} 會被推斷成 Map<dynamic, dynamic>，
      // 過不了產生碼的 `as Map<String, dynamic>`（實測拋 CheckedFromJsonException）。
      final dto = YelpReviewHighlightsDto.fromJson(const {
        'review_highlights': [<String, dynamic>{}],
      });
      final h = dto.reviewHighlights?.first;
      expect(h?.photo, isNull);
      expect(h?.sentence, isNull);
      expect(h?.reviewCount, isNull);
    });

    // 直接傳 toJson() 的 map，不經 jsonEncode：沒有 explicitToJson 的話，
    // review_highlights 的 List 元素仍是 DTO 物件，fromJson 會因元素不是 Map 而拋錯。
    test('值相等與 round-trip', () {
      final dto = YelpReviewHighlightsDto.fromJson(_Data.full);
      expect(YelpReviewHighlightsDto.fromJson(dto.toJson()), dto);
    });

    test('型別不符時拋出 CheckedFromJsonException', () {
      expect(
        () =>
            YelpReviewHighlightsDto.fromJson(const {'review_highlights': 'x'}),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });
  });
}
