import 'package:flutter_restaruant/api/dto/yelp_service_offerings_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

class _Data {
  static const Map<String, dynamic> full = {
    'active': ['delivery'],
    'eligible': ['delivery', 'pickup'],
  };
}

void main() {
  group('YelpServiceOfferingsDto', () {
    test('完整欄位逐欄解析', () {
      final dto = YelpServiceOfferingsDto.fromJson(_Data.full);
      expect(dto.active, ['delivery']);
      expect(dto.eligible, ['delivery', 'pickup']);
    });

    test('空 map 時兩個欄位為 null', () {
      final dto = YelpServiceOfferingsDto.fromJson(const {});
      expect(dto.active, isNull);
      expect(dto.eligible, isNull);
    });

    test('值相等與 round-trip', () {
      final dto = YelpServiceOfferingsDto.fromJson(_Data.full);
      expect(YelpServiceOfferingsDto.fromJson(dto.toJson()), dto);
    });

    test('型別不符時拋出 CheckedFromJsonException', () {
      expect(
        () => YelpServiceOfferingsDto.fromJson(const {'active': 'x'}),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });
  });
}
