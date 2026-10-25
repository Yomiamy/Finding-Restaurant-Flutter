import 'package:flutter_restaruant/api/dto/dto_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

class _Data {
  // rating、distance、coordinates.latitude 刻意給 int，驗證轉成 double。
  static const Map<String, dynamic> business = {
    'id': 'WavvLdfdP6g8aZTtbBQHTw',
    'alias': 'gary-danko-san-francisco',
    'name': 'Gary Danko',
    'image_url': 'https://s3-media.yelpcdn.com/bphoto/abc/o.jpg',
    'is_closed': false,
    'url': 'https://www.yelp.com/biz/gary-danko-san-francisco',
    'review_count': 5296,
    // 既有 /v3/businesses/search 一直是 array of object（規格 R-3）。
    'categories': [
      {'alias': 'newamerican', 'title': 'American (New)'},
    ],
    'rating': 4,
    'coordinates': {'latitude': 37, 'longitude': -122.42},
    'transactions': ['pickup', 'delivery'],
    'price': '\$\$\$\$',
    'location': {
      'address1': '800 N Point St',
      'city': 'San Francisco',
      'zip_code': '94109',
      'country': 'US',
      'state': 'CA',
      'display_address': ['800 N Point St', 'San Francisco, CA 94109'],
      'cross_streets': 'Hyde St & Larkin St',
    },
    'phone': '+14157492060',
    'display_phone': '(415) 749-2060',
    'distance': 1500,
    'attributes': {'menu_url': 'https://example.com/menu'},
  };

  static const Map<String, dynamic> full = {
    'businesses': [business],
    'total': 1,
  };

  static const Map<String, dynamic> requiredOnlyBusiness = {
    'id': 'WavvLdfdP6g8aZTtbBQHTw',
    'alias': 'gary-danko-san-francisco',
    'name': 'Gary Danko',
    'coordinates': {'latitude': 37.8, 'longitude': -122.42},
    'location': {
      'display_address': ['800 N Point St'],
    },
    'phone': '+14157492060',
    'display_phone': '(415) 749-2060',
  };

  static const Map<String, dynamic> requiredOnly = {
    'businesses': [requiredOnlyBusiness],
    'total': 1,
  };

  // #2 /businesses/matches：沒有 total。
  static const Map<String, dynamic> matches = {
    'businesses': [requiredOnlyBusiness],
  };
}

void main() {
  group('YelpSearchDto', () {
    test('完整欄位逐欄解析', () {
      final dto = YelpSearchDto.fromJson(_Data.full);
      expect(dto.total, 1);
      expect(dto.businesses, hasLength(1));
      final b = dto.businesses!.first;
      expect(b.id, 'WavvLdfdP6g8aZTtbBQHTw');
      expect(b.alias, 'gary-danko-san-francisco');
      expect(b.name, 'Gary Danko');
      expect(b.imageUrl, 'https://s3-media.yelpcdn.com/bphoto/abc/o.jpg');
      expect(b.isClosed, isFalse);
      expect(b.url, 'https://www.yelp.com/biz/gary-danko-san-francisco');
      expect(b.reviewCount, 5296);
      expect(b.categories?.first.alias, 'newamerican');
      expect(b.rating, 4.0);
      expect(b.coordinates?.latitude, 37.0);
      expect(b.coordinates?.longitude, -122.42);
      expect(b.transactions, ['pickup', 'delivery']);
      expect(b.price, '\$\$\$\$');
      expect(b.location?.displayAddress, [
        '800 N Point St',
        'San Francisco, CA 94109',
      ]);
      expect(b.location?.zipCode, '94109');
      expect(b.location?.crossStreets, 'Hyde St & Larkin St');
      expect(b.phone, '+14157492060');
      expect(b.displayPhone, '(415) 749-2060');
      expect(b.distance, 1500.0);
      expect(b.attributes, {'menu_url': 'https://example.com/menu'});
    });

    test('只有必有欄位時，其餘欄位為 null', () {
      final dto = YelpSearchDto.fromJson(_Data.requiredOnly);
      expect(dto.total, 1);
      expect(dto.businesses, hasLength(1));
      final b = dto.businesses!.first;
      expect(b.id, 'WavvLdfdP6g8aZTtbBQHTw');
      expect(b.alias, 'gary-danko-san-francisco');
      expect(b.name, 'Gary Danko');
      expect(b.coordinates?.latitude, 37.8);
      expect(b.location?.displayAddress, ['800 N Point St']);
      expect(b.phone, '+14157492060');
      expect(b.displayPhone, '(415) 749-2060');
      expect(b.imageUrl, isNull);
      expect(b.isClosed, isNull);
      expect(b.url, isNull);
      expect(b.reviewCount, isNull);
      expect(b.categories, isNull);
      expect(b.rating, isNull);
      expect(b.transactions, isNull);
      expect(b.price, isNull);
      expect(b.distance, isNull);
      expect(b.attributes, isNull);
    });

    test('#2 matches 沒有 total，解析為 null', () {
      final dto = YelpSearchDto.fromJson(_Data.matches);
      expect(dto.businesses, hasLength(1));
      expect(dto.total, isNull);
    });

    // 直接傳 toJson() 的 map，不經 jsonEncode：沒有 explicitToJson 的話，
    // businesses 仍是 DTO 物件，fromJson 會在 `e as Map<String, dynamic>` 拋錯。
    test('值相等與 round-trip', () {
      final dto = YelpSearchDto.fromJson(_Data.full);
      expect(YelpSearchDto.fromJson(dto.toJson()), dto);
    });

    test('int 值轉成 double', () {
      final b = YelpSearchDto.fromJson(_Data.full).businesses?.first;
      expect(b?.rating, isA<double>());
      expect(b?.distance, isA<double>());
      expect(b?.coordinates?.latitude, isA<double>());
    });
  });
}
