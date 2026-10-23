import 'package:flutter_restaruant/api/dto/yelp_category_detail_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

class _Data {
  static const Map<String, dynamic> full = {
    'category': {
      'alias': 'bars',
      'title': 'Bars',
      'parent_aliases': ['nightlife'],
      'country_whitelist': ['TW', 'US'],
      'country_blacklist': ['JP'],
    },
  };

  static const Map<String, dynamic> aliasTitleOnly = {
    'category': {'alias': 'cafes', 'title': 'Cafes'},
  };
}

void main() {
  group('YelpCategoryDetailDto', () {
    test('完整欄位逐欄解析', () {
      final c = YelpCategoryDetailDto.fromJson(_Data.full).category;
      expect(c?.alias, 'bars');
      expect(c?.title, 'Bars');
      expect(c?.parentAliases, ['nightlife']);
      expect(c?.countryWhitelist, ['TW', 'US']);
      expect(c?.countryBlacklist, ['JP']);
    });

    test('空 map 時 category 為 null', () {
      expect(YelpCategoryDetailDto.fromJson(const {}).category, isNull);
    });

    test('只有 alias/title 時新欄位為 null', () {
      final c = YelpCategoryDetailDto.fromJson(_Data.aliasTitleOnly).category;
      expect(c?.alias, 'cafes');
      expect(c?.title, 'Cafes');
      expect(c?.parentAliases, isNull);
      expect(c?.countryWhitelist, isNull);
      expect(c?.countryBlacklist, isNull);
    });

    // 直接傳 toJson() 的 map，不經 jsonEncode：沒有 explicitToJson 的話，
    // category 仍是 DTO 物件，fromJson 會因值不是 Map 而拋錯。
    test('值相等與 round-trip', () {
      final dto = YelpCategoryDetailDto.fromJson(_Data.full);
      expect(YelpCategoryDetailDto.fromJson(dto.toJson()), dto);
    });

    test('型別不符時拋出 CheckedFromJsonException', () {
      expect(
        () => YelpCategoryDetailDto.fromJson(const {'category': 'x'}),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });
  });
}
