import 'package:flutter_restaruant/api/api_barrel.dart';
import 'package:flutter_restaruant/app/constants/constants_barrel.dart';
import 'package:flutter_restaruant/data_layer/repositories/yelp_event_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAPIClz extends Mock implements APIClz {}

class _Data {
  static const String eventId = 'oakland-saucy-restaurant-pop-up';

  // 內容各不相同，same() 才分辨得出是不是同一個物件。
  static const YelpEventSearchDto search = YelpEventSearchDto(total: 1);
  static const YelpEventDto event = YelpEventDto(id: 'event');
  static const YelpEventDto featured = YelpEventDto(id: 'featured');
}

void main() {
  late _MockAPIClz api;
  late YelpEventRepo repo;

  setUp(() {
    api = _MockAPIClz();
    repo = YelpEventRepo(api: api);
  });

  group('參數轉發與原樣回傳', () {
    test('searchEvents 帶入 Constants.locale，兩個 List 以逗號串接', () async {
      Future<YelpEventSearchDto> apiCall() => api.eventsSearch(
        locale: Constants.locale,
        offset: 20,
        limit: 10,
        sortBy: 'asc',
        sortOn: 'time_start',
        startDate: 1792800000,
        endDate: 1793404800,
        categories: 'music,food-and-drink',
        isFree: true,
        excludedEvents: 'e1,e2',
        location: 'San Francisco',
        latitude: 37.78,
        longitude: -122.41,
        radius: 5000,
      );
      when(apiCall).thenAnswer((_) async => _Data.search);

      final result = await repo.searchEvents(
        offset: 20,
        limit: 10,
        sortBy: 'asc',
        sortOn: 'time_start',
        startDate: 1792800000,
        endDate: 1793404800,
        categories: ['music', 'food-and-drink'],
        isFree: true,
        excludedEvents: ['e1', 'e2'],
        location: 'San Francisco',
        latitude: 37.78,
        longitude: -122.41,
        radius: 5000,
      );

      expect(result, same(_Data.search));
      verify(apiCall).called(1);
    });

    test('searchEvents 未傳的參數（含兩個 List）原樣傳成 null', () async {
      Future<YelpEventSearchDto> apiCall() => api.eventsSearch(
        locale: Constants.locale,
        offset: null,
        limit: null,
        sortBy: null,
        sortOn: null,
        startDate: null,
        endDate: null,
        categories: null,
        isFree: null,
        excludedEvents: null,
        location: null,
        latitude: null,
        longitude: null,
        radius: null,
      );
      when(apiCall).thenAnswer((_) async => _Data.search);

      final result = await repo.searchEvents();

      expect(result, same(_Data.search));
      verify(apiCall).called(1);
    });

    test('fetchEvent 帶入 Constants.locale', () async {
      Future<YelpEventDto> apiCall() =>
          api.event(_Data.eventId, Constants.locale);
      when(apiCall).thenAnswer((_) async => _Data.event);

      final result = await repo.fetchEvent(_Data.eventId);

      expect(result, same(_Data.event));
      verify(apiCall).called(1);
    });

    test('fetchFeaturedEvent 帶入 Constants.locale', () async {
      Future<YelpEventDto> apiCall() => api.featuredEvent(
        locale: Constants.locale,
        location: 'San Francisco',
        latitude: 37.78,
        longitude: -122.41,
      );
      when(apiCall).thenAnswer((_) async => _Data.featured);

      final result = await repo.fetchFeaturedEvent(
        location: 'San Francisco',
        latitude: 37.78,
        longitude: -122.41,
      );

      expect(result, same(_Data.featured));
      verify(apiCall).called(1);
    });
  });
}
