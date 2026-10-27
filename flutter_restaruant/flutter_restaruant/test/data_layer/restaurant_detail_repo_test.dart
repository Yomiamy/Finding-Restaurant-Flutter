import 'package:flutter_restaruant/api/api_barrel.dart';
import 'package:flutter_restaruant/data_layer/repositories/restaurant_detail_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAPIClz extends Mock implements APIClz {}

class _Data {
  // id 與 locale 值互不相同，且 locale 刻意不等於正式值 'zh_TW'，
  // 參數對調或寫死常數都會讓 mock 比對失敗。
  static const String id = 'north-india-restaurant-san-francisco';
  static const String locale = 'en_US';
  static const String name = 'North India Restaurant';
  static const int total = 3;

  // DTO 沒有 const 建構式，只能用 final。
  static final YelpRestaurantDetailDto detail = YelpRestaurantDetailDto(
    name: name,
  );
  static final YelpReviewDto review = YelpReviewDto(total: total);
}

void main() {
  late _MockAPIClz api;
  late RestaurantDetailRepo repo;

  setUp(() {
    api = _MockAPIClz();
    repo = RestaurantDetailRepo(api: api, locale: _Data.locale);
  });

  group('參數轉發與轉成 entity', () {
    test('fetchYelpRestaurantDetailInfo 帶入 id 與注入的 locale', () async {
      Future<YelpRestaurantDetailDto> apiCall() =>
          api.business(_Data.id, _Data.locale);
      when(apiCall).thenAnswer((_) async => _Data.detail);

      final result = await repo.fetchYelpRestaurantDetailInfo(_Data.id);

      expect(result.name, _Data.name);
      verify(apiCall).called(1);
    });

    test('fetchYelpRestaurantReviewInfo 帶入 id 與注入的 locale', () async {
      Future<YelpReviewDto> apiCall() => api.review(_Data.id, _Data.locale);
      when(apiCall).thenAnswer((_) async => _Data.review);

      final result = await repo.fetchYelpRestaurantReviewInfo(_Data.id);

      expect(result.total, _Data.total);
      verify(apiCall).called(1);
    });
  });
}
