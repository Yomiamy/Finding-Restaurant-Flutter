import 'package:flutter_restaruant/api/dto/yelp_event_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

class _Data {
  // cost、cost_max、latitude、longitude 刻意給 int，驗證轉成 double。
  static const Map<String, dynamic> full = {
    'id': 'oakland-street-food-fest',
    'name': 'Street Food Fest',
    'description': 'Thirty food trucks.',
    'business_id': 'WavvLdfdP6g8aZTtbBQHTw',
    'category': 'food-and-drink',
    'cost': 10,
    'cost_max': 25,
    'event_site_url': 'https://www.yelp.com/events/oakland-street-food-fest',
    'image_url': 'https://s3-media.yelpcdn.com/ephoto/abc/o.jpg',
    'tickets_url': 'https://example.com/tickets',
    'time_start': '2026-10-24T18:00:00-07:00',
    'time_end': '2026-10-24T22:00:00-07:00',
    'attending_count': 120,
    'interested_count': 340,
    'is_canceled': false,
    'is_free': false,
    'is_official': true,
    'latitude': 37,
    'longitude': -122,
    'location': {
      'address1': '1 Main St',
      'address2': 'Suite 2',
      'address3': 'Floor 3',
      'city': 'Oakland',
      'state': 'CA',
      'zip_code': '94607',
      'country': 'US',
      'display_address': ['1 Main St', 'Oakland, CA 94607'],
      'cross_streets': 'Main St & 2nd Ave',
    },
  };

  static const Map<String, dynamic> requiredOnly = {
    'id': 'oakland-street-food-fest',
    'time_start': '2026-10-24T18:00:00-07:00',
  };
}

void main() {
  group('YelpEventDto', () {
    test('完整欄位逐欄解析', () {
      final dto = YelpEventDto.fromJson(_Data.full);
      expect(dto.id, 'oakland-street-food-fest');
      expect(dto.name, 'Street Food Fest');
      expect(dto.description, 'Thirty food trucks.');
      expect(dto.businessId, 'WavvLdfdP6g8aZTtbBQHTw');
      expect(dto.category, 'food-and-drink');
      expect(dto.cost, 10.0);
      expect(dto.costMax, 25.0);
      expect(
        dto.eventSiteUrl,
        'https://www.yelp.com/events/oakland-street-food-fest',
      );
      expect(dto.imageUrl, 'https://s3-media.yelpcdn.com/ephoto/abc/o.jpg');
      expect(dto.ticketsUrl, 'https://example.com/tickets');
      expect(dto.timeStart, '2026-10-24T18:00:00-07:00');
      expect(dto.timeEnd, '2026-10-24T22:00:00-07:00');
      expect(dto.attendingCount, 120);
      expect(dto.interestedCount, 340);
      expect(dto.isCanceled, isFalse);
      expect(dto.isFree, isFalse);
      expect(dto.isOfficial, isTrue);
      expect(dto.latitude, 37.0);
      expect(dto.longitude, -122.0);
      expect(dto.location?.address1, '1 Main St');
      expect(dto.location?.address2, 'Suite 2');
      expect(dto.location?.address3, 'Floor 3');
      expect(dto.location?.city, 'Oakland');
      expect(dto.location?.state, 'CA');
      expect(dto.location?.zipCode, '94607');
      expect(dto.location?.country, 'US');
      expect(dto.location?.displayAddress, ['1 Main St', 'Oakland, CA 94607']);
      expect(dto.location?.crossStreets, 'Main St & 2nd Ave');
    });

    test('只有 id 和 time_start 時，其餘欄位為 null', () {
      final dto = YelpEventDto.fromJson(_Data.requiredOnly);
      expect(dto.id, 'oakland-street-food-fest');
      expect(dto.timeStart, '2026-10-24T18:00:00-07:00');
      expect(dto.name, isNull);
      expect(dto.description, isNull);
      expect(dto.businessId, isNull);
      expect(dto.category, isNull);
      expect(dto.cost, isNull);
      expect(dto.costMax, isNull);
      expect(dto.eventSiteUrl, isNull);
      expect(dto.imageUrl, isNull);
      expect(dto.ticketsUrl, isNull);
      expect(dto.timeEnd, isNull);
      expect(dto.attendingCount, isNull);
      expect(dto.interestedCount, isNull);
      expect(dto.isCanceled, isNull);
      expect(dto.isFree, isNull);
      expect(dto.isOfficial, isNull);
      expect(dto.latitude, isNull);
      expect(dto.longitude, isNull);
      expect(dto.location, isNull);
    });

    // 直接傳 toJson() 的 map，不經 jsonEncode：沒有 explicitToJson 的話，
    // location 仍是 DTO 物件，fromJson 會因它不是 Map 而拋錯。
    test('值相等與 round-trip', () {
      final dto = YelpEventDto.fromJson(_Data.full);
      expect(YelpEventDto.fromJson(dto.toJson()), dto);
    });

    test('int 值轉成 double', () {
      final dto = YelpEventDto.fromJson(_Data.full);
      expect(dto.cost, isA<double>());
      expect(dto.costMax, isA<double>());
      expect(dto.latitude, isA<double>());
      expect(dto.longitude, isA<double>());
    });

    test('型別不符時拋出 CheckedFromJsonException', () {
      expect(
        () => YelpEventDto.fromJson(const {'id': 1}),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });
  });
}
