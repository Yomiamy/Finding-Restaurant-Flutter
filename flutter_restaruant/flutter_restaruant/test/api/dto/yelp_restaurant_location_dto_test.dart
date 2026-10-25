import 'package:flutter_restaruant/api/dto/dto_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

class _Data {
  static const Map<String, dynamic> full = {
    'address1': '1 Main St',
    'address2': 'Suite 2',
    'address3': 'Floor 3',
    'city': 'Taipei',
    'country': 'TW',
    'state': 'TPE',
    'display_address': ['1 Main St', 'Taipei, TPE'],
    'zip_code': '100',
    'cross_streets': 'Main St & 2nd Ave',
  };
}

void main() {
  group('YelpRestaurantLocationDto', () {
    test('完整欄位逐欄解析', () {
      final dto = YelpRestaurantLocationDto.fromJson(_Data.full);
      expect(dto.address1, '1 Main St');
      expect(dto.address2, 'Suite 2');
      expect(dto.address3, 'Floor 3');
      expect(dto.city, 'Taipei');
      expect(dto.country, 'TW');
      expect(dto.state, 'TPE');
      expect(dto.displayAddress, ['1 Main St', 'Taipei, TPE']);
      expect(dto.zipCode, '100');
      expect(dto.crossStreets, 'Main St & 2nd Ave');
    });

    test('只有 display_address 時其餘欄位為 null', () {
      final dto = YelpRestaurantLocationDto.fromJson(const {
        'display_address': ['Taipei'],
      });
      expect(dto.displayAddress, ['Taipei']);
      expect(dto.address1, isNull);
      expect(dto.address2, isNull);
      expect(dto.address3, isNull);
      expect(dto.city, isNull);
      expect(dto.country, isNull);
      expect(dto.state, isNull);
      expect(dto.zipCode, isNull);
      expect(dto.crossStreets, isNull);
    });

    test('值相等與 round-trip', () {
      final dto = YelpRestaurantLocationDto.fromJson(_Data.full);
      expect(YelpRestaurantLocationDto.fromJson(dto.toJson()), dto);
    });

    // 守住 Firestore 最愛 payload：既有 7 個 key 照舊輸出，新欄位為 null 時不得輸出 key。
    test('新欄位為 null 時 toJson 鍵集合與修改前相同', () {
      expect(
        const YelpRestaurantLocationDto(city: 'Taipei').toJson().keys,
        unorderedEquals([
          'address1',
          'address2',
          'address3',
          'city',
          'country',
          'state',
          'display_address',
        ]),
      );
    });
  });
}
