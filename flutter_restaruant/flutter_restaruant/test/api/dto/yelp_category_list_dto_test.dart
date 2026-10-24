import 'package:flutter_restaruant/api/dto/yelp_category_list_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

class _Data {
  static const Map<String, dynamic> category = {
    'alias': 'bars',
    'title': 'Bars',
    'parent_aliases': ['nightlife'],
    'country_whitelist': ['TW', 'US'],
    'country_blacklist': ['JP'],
  };

  static const Map<String, dynamic> aliasTitleOnly = {
    'alias': 'cafes',
    'title': 'Cafes',
  };
}

void main() {
  group('YelpCategoryListDto', () {
    test('完整欄位逐欄解析', () {
      final dto = YelpCategoryListDto.fromJson(const {
        'categories': [_Data.category],
      });
      expect(dto.categories, hasLength(1));
      final c = dto.categories?.first;
      expect(c?.alias, 'bars');
      expect(c?.title, 'Bars');
      expect(c?.parentAliases, ['nightlife']);
      expect(c?.countryWhitelist, ['TW', 'US']);
      expect(c?.countryBlacklist, ['JP']);
    });

    test('空 map 時 categories 為 null', () {
      expect(YelpCategoryListDto.fromJson(const {}).categories, isNull);
    });

    test('只有 alias/title 時新欄位為 null', () {
      final dto = YelpCategoryListDto.fromJson(const {
        'categories': [_Data.aliasTitleOnly],
      });
      expect(dto.categories, hasLength(1));
      final c = dto.categories?.first;
      expect(c?.alias, 'cafes');
      expect(c?.title, 'Cafes');
      expect(c?.parentAliases, isNull);
      expect(c?.countryWhitelist, isNull);
      expect(c?.countryBlacklist, isNull);
    });

    // 直接傳 toJson() 的 map，不經 jsonEncode：沒有 explicitToJson 的話，
    // categories 仍是 DTO 物件，fromJson 會因元素不是 Map 而拋錯。
    test('值相等與 round-trip', () {
      final dto = YelpCategoryListDto.fromJson(const {
        'categories': [_Data.category, _Data.aliasTitleOnly],
      });
      expect(YelpCategoryListDto.fromJson(dto.toJson()), dto);
    });

    test('型別不符時拋出 CheckedFromJsonException', () {
      expect(
        () => YelpCategoryListDto.fromJson(const {'categories': 'x'}),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });
  });
}
