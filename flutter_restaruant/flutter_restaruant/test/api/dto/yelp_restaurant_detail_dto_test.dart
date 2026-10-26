import 'package:flutter_restaruant/api/dto/dto_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

class _Data {
  static const Map<String, dynamic> business = {
    'id': 'WavvLdfdP6g8aZTtbBQHTw',
    'alias': 'gary-danko-san-francisco',
    'name': 'Gary Danko',
    'price': '\$\$\$\$',
    'url': 'https://www.yelp.com/biz/gary-danko-san-francisco',
    'phone': '+14157492060',
    'display_phone': '(415) 749-2060',
    'is_claimed': true,
    'transactions': ['pickup', 'delivery'],
  };
}

void main() {
  group('YelpRestaurantDetailDto 新增欄位', () {
    test('完整測資逐欄解析，既有欄位不受影響', () {
      final dto = YelpRestaurantDetailDto.fromJson(_Data.business);
      expect(dto.id, 'WavvLdfdP6g8aZTtbBQHTw');
      expect(dto.alias, 'gary-danko-san-francisco');
      expect(dto.price, '\$\$\$\$');
      expect(dto.url, 'https://www.yelp.com/biz/gary-danko-san-francisco');
      expect(dto.displayPhone, '(415) 749-2060');
      expect(dto.isClaimed, isTrue);
      expect(dto.transactions, ['pickup', 'delivery']);
      expect(dto.name, 'Gary Danko');
      expect(dto.phone, '+14157492060');
    });

    test('缺欄位時 7 個新欄位皆為 null', () {
      final dto = YelpRestaurantDetailDto.fromJson(const {'name': 'x'});
      expect(dto.id, isNull);
      expect(dto.alias, isNull);
      expect(dto.price, isNull);
      expect(dto.url, isNull);
      expect(dto.displayPhone, isNull);
      expect(dto.isClaimed, isNull);
      expect(dto.transactions, isNull);
    });
  });
}
