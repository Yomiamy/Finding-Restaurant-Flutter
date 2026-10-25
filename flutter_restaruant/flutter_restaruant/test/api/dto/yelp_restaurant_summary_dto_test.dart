import 'package:flutter_restaruant/api/dto/dto_barrel.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

class _Data {
  static const Map<String, dynamic> business = {
    'id': 'WavvLdfdP6g8aZTtbBQHTw',
    'alias': 'gary-danko-san-francisco',
    'name': 'Gary Danko',
    'is_closed': false,
    'url': 'https://www.yelp.com/biz/gary-danko-san-francisco',
    'transactions': ['pickup', 'delivery'],
    'phone': '+14157492060',
    'display_phone': '(415) 749-2060',
    'attributes': {'menu_url': 'https://example.com/menu'},
    'coordinates': {'latitude': 37.8, 'longitude': -122.42},
    'location': {
      'display_address': ['800 N Point St'],
    },
  };
}

void main() {
  group('YelpRestaurantSummaryDto 新增欄位', () {
    test('解析 #1–#3 Business 的新欄位', () {
      final dto = YelpRestaurantSummaryDto.fromJson(_Data.business);
      expect(dto.alias, 'gary-danko-san-francisco');
      expect(dto.isClosed, isFalse);
      expect(dto.url, 'https://www.yelp.com/biz/gary-danko-san-francisco');
      expect(dto.transactions, ['pickup', 'delivery']);
      expect(dto.displayPhone, '(415) 749-2060');
      expect(dto.attributes, {'menu_url': 'https://example.com/menu'});
    });

    test('缺欄位時新欄位為 null', () {
      final dto = YelpRestaurantSummaryDto.fromJson(const {'id': 'x'});
      expect(dto.alias, isNull);
      expect(dto.isClosed, isNull);
      expect(dto.url, isNull);
      expect(dto.transactions, isNull);
      expect(dto.displayPhone, isNull);
      expect(dto.attributes, isNull);
    });

    // 與 FavorDataSource.toggleFavor（favor_data_source.dart:122）同一個運算式。
    test('最愛寫入 Firestore 的 payload 鍵集合不變', () {
      final payload = RestaurantEntity.fromDto(
        YelpRestaurantSummaryDto.fromJson(_Data.business),
      ).toDto.toJson();
      expect(
        payload.keys,
        unorderedEquals(<String>[
          'id',
          'name',
          'image_url',
          'review_count',
          'rating',
          'price',
          'phone',
          'distance',
          'categories',
          'location',
          'coordinates',
        ]),
      );
    });
  });
}
