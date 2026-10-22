import 'package:flutter_restaruant/api/dto/yelp_event_search_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

class _Data {
  // cost、cost_max、latitude、longitude 刻意給 int，驗證轉成 double。
  static const Map<String, dynamic> event = {
    'id': 'oakland-street-food-fest',
    'name': 'Street Food Fest',
    'time_start': '2026-10-24T18:00:00-07:00',
    'cost': 10,
    'cost_max': 25,
    'latitude': 37,
    'longitude': -122,
    'location': {
      'zip_code': '94607',
      'cross_streets': 'Main St & 2nd Ave',
      'display_address': ['1 Main St', 'Oakland, CA 94607'],
    },
  };

  static const Map<String, dynamic> requiredOnlyEvent = {
    'id': 'oakland-night-market',
    'time_start': '2026-10-25T18:00:00-07:00',
  };

  // total 是分頁總數，刻意大於 events 的長度。
  static const Map<String, dynamic> full = {
    'events': [event, requiredOnlyEvent],
    'total': 42,
  };

  static const Map<String, dynamic> requiredOnly = {
    'events': [requiredOnlyEvent],
    'total': 1,
  };
}

void main() {
  group('YelpEventSearchDto', () {
    test('完整欄位逐欄解析', () {
      final dto = YelpEventSearchDto.fromJson(_Data.full);
      expect(dto.total, 42);
      expect(dto.events, hasLength(2));
      final e = dto.events?.first;
      expect(e?.id, 'oakland-street-food-fest');
      expect(e?.name, 'Street Food Fest');
      expect(e?.timeStart, '2026-10-24T18:00:00-07:00');
      expect(e?.cost, 10.0);
      expect(e?.costMax, 25.0);
      expect(e?.latitude, 37.0);
      expect(e?.longitude, -122.0);
      expect(e?.location?.zipCode, '94607');
      expect(e?.location?.crossStreets, 'Main St & 2nd Ave');
      expect(e?.location?.displayAddress, ['1 Main St', 'Oakland, CA 94607']);
      expect(dto.events?.last.id, 'oakland-night-market');
    });

    test('只有必有欄位時，其餘欄位為 null', () {
      final dto = YelpEventSearchDto.fromJson(_Data.requiredOnly);
      expect(dto.total, 1);
      expect(dto.events, hasLength(1));
      final e = dto.events?.first;
      expect(e?.id, 'oakland-night-market');
      expect(e?.timeStart, '2026-10-25T18:00:00-07:00');
      expect(e?.name, isNull);
      expect(e?.cost, isNull);
      expect(e?.isFree, isNull);
      expect(e?.location, isNull);
    });

    test('空 map 時 events 與 total 為 null', () {
      final dto = YelpEventSearchDto.fromJson(const {});
      expect(dto.events, isNull);
      expect(dto.total, isNull);
    });

    // 直接傳 toJson() 的 map，不經 jsonEncode：沒有 explicitToJson 的話，
    // events 仍是 DTO 物件，fromJson 會因元素不是 Map 而拋錯。
    test('值相等與 round-trip', () {
      final dto = YelpEventSearchDto.fromJson(_Data.full);
      expect(YelpEventSearchDto.fromJson(dto.toJson()), dto);
    });

    test('int 值轉成 double', () {
      final e = YelpEventSearchDto.fromJson(_Data.full).events?.first;
      expect(e?.cost, isA<double>());
      expect(e?.costMax, isA<double>());
      expect(e?.latitude, isA<double>());
      expect(e?.longitude, isA<double>());
    });

    test('型別不符時拋出 CheckedFromJsonException', () {
      expect(
        () => YelpEventSearchDto.fromJson(const {'events': 'x'}),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });
  });
}
