import 'package:flutter_restaruant/api/dto/yelp_autocomplete_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

class _Data {
  // businesses 只比 id（見 YelpRestaurantSummaryDto），所以 business 必須帶 id。
  static const Map<String, dynamic> full = {
    'categories': [
      {'alias': 'pizza', 'title': 'Pizza'},
    ],
    'businesses': [
      {'id': 'WavvLdfdP6g8aZTtbBQHTw', 'name': 'Gary Danko'},
    ],
    'terms': [
      {'text': 'pizza'},
    ],
  };
}

void main() {
  group('YelpAutocompleteDto', () {
    test('完整欄位逐欄解析', () {
      final dto = YelpAutocompleteDto.fromJson(_Data.full);
      expect(dto.categories, hasLength(1));
      expect(dto.categories?.first.alias, 'pizza');
      expect(dto.categories?.first.title, 'Pizza');
      expect(dto.businesses, hasLength(1));
      final b = dto.businesses?.first;
      expect(b?.id, 'WavvLdfdP6g8aZTtbBQHTw');
      expect(b?.name, 'Gary Danko');
      // autocomplete 的 business 只有 id、name，search 才有的欄位必須是 null。
      expect(b?.alias, isNull);
      expect(b?.isClosed, isNull);
      expect(b?.url, isNull);
      expect(b?.transactions, isNull);
      expect(b?.displayPhone, isNull);
      expect(b?.attributes, isNull);
      expect(dto.terms, hasLength(1));
      expect(dto.terms?.first.text, 'pizza');
    });

    test('空 map 時三個欄位都是 null', () {
      final dto = YelpAutocompleteDto.fromJson(const {});
      expect(dto.categories, isNull);
      expect(dto.businesses, isNull);
      expect(dto.terms, isNull);
    });

    // 直接傳 toJson() 的 map，不經 jsonEncode：沒有 explicitToJson 的話，
    // 三個 List 的元素仍是 DTO 物件，fromJson 會因元素不是 Map 而拋錯。
    test('值相等與 round-trip', () {
      final dto = YelpAutocompleteDto.fromJson(_Data.full);
      expect(YelpAutocompleteDto.fromJson(dto.toJson()), dto);
    });

    test('型別不符時拋出 CheckedFromJsonException', () {
      expect(
        () => YelpAutocompleteDto.fromJson(const {'terms': 'x'}),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });
  });
}
