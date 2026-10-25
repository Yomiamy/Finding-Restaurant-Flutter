import 'package:flutter_restaruant/api/dto/dto_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

class _Data {
  static const Map<String, dynamic> full = {
    'alias': 'bars',
    'title': 'Bars',
    'parent_aliases': ['nightlife'],
    'country_whitelist': ['TW', 'US'],
    'country_blacklist': ['JP'],
  };
}

void main() {
  group('YelpRestaurantCategoryDto', () {
    test('完整欄位逐欄解析', () {
      final dto = YelpRestaurantCategoryDto.fromJson(_Data.full);
      expect(dto.alias, 'bars');
      expect(dto.title, 'Bars');
      expect(dto.parentAliases, ['nightlife']);
      expect(dto.countryWhitelist, ['TW', 'US']);
      expect(dto.countryBlacklist, ['JP']);
    });

    test('只有 alias/title 時新欄位為 null', () {
      final dto = YelpRestaurantCategoryDto.fromJson(const {
        'alias': 'a',
        'title': 'A',
      });
      expect(dto.parentAliases, isNull);
      expect(dto.countryWhitelist, isNull);
      expect(dto.countryBlacklist, isNull);
    });

    test('值相等與 round-trip', () {
      final dto = YelpRestaurantCategoryDto.fromJson(_Data.full);
      expect(YelpRestaurantCategoryDto.fromJson(dto.toJson()), dto);
    });

    // 守住 Firestore 最愛 payload：新欄位為 null 時不得輸出 key。
    test('新欄位為 null 時 toJson 與修改前逐鍵相同', () {
      expect(const YelpRestaurantCategoryDto(alias: 'a', title: 'A').toJson(), {
        'alias': 'a',
        'title': 'A',
      });
    });
  });
}
