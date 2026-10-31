import 'package:flutter_restaruant/api/api_barrel.dart';
import 'package:flutter_restaruant/data_layer/datasources/datasources_barrel.dart';
import 'package:flutter_restaruant/data_layer/repositories/main_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAPIClz extends Mock implements APIClz {}

// 真實的 fetchFavorIds() 會經 SignInManager 觸發 local_auth platform channel，測試環境無法執行。
class _MockFavorDataSource extends Mock implements FavorDataSource {}

class _Data {
  // 刻意不等於正式值 'zh_TW'，才分辨得出轉發的是注入值。
  static const String locale = 'en_US';
  // lat/lng、price/openAt 型別相同，值刻意互不相同，對調才會被抓到。
  static const double lat = 25.033;
  static const double lng = 121.5654;
  static const int price = 2;
  static const int openAt = 1761600000;
  static const String sortBy = 'distance';

  static const YelpSearchDto empty = YelpSearchDto(businesses: []);
}

void main() {
  late _MockAPIClz api;
  late _MockFavorDataSource favorDataSource;
  late MainRepo repo;

  setUp(() {
    api = _MockAPIClz();
    favorDataSource = _MockFavorDataSource();
    repo = MainRepo(
      api: api,
      locale: _Data.locale,
      favorDataSource: favorDataSource,
    );
  });

  group('參數轉發', () {
    test('fetchYelpSearchInfo 帶入座標、篩選條件與注入的 locale', () async {
      Future<YelpSearchDto> apiCall() => api.businessesSearch(
        term: 'Restaurants',
        latitude: _Data.lat,
        longitude: _Data.lng,
        locale: _Data.locale,
        price: _Data.price,
        openAt: _Data.openAt,
        sortBy: _Data.sortBy,
        limit: 50,
        offset: 0,
      );
      when(apiCall).thenAnswer((_) async => _Data.empty);
      when(
        () => favorDataSource.fetchFavorIds(),
      ).thenAnswer((_) async => <String>{});

      await repo.fetchYelpSearchInfo(
        _Data.lat,
        _Data.lng,
        _Data.price,
        _Data.openAt,
        _Data.sortBy,
      );

      verify(apiCall).called(1);
    });

    test('fetchYelpSearchInfo 帶入進階篩選 categories、radius、openNow', () async {
      Future<YelpSearchDto> apiCall() => api.businessesSearch(
        term: 'Restaurants',
        latitude: _Data.lat,
        longitude: _Data.lng,
        locale: _Data.locale,
        price: _Data.price,
        openAt: _Data.openAt,
        sortBy: _Data.sortBy,
        categories: 'japanese,bars',
        radius: 5000,
        openNow: true,
        limit: 50,
        offset: 0,
      );
      when(apiCall).thenAnswer((_) async => _Data.empty);
      when(
        () => favorDataSource.fetchFavorIds(),
      ).thenAnswer((_) async => <String>{});

      await repo.fetchYelpSearchInfo(
        _Data.lat,
        _Data.lng,
        _Data.price,
        _Data.openAt,
        _Data.sortBy,
        categories: 'japanese,bars',
        radius: 5000,
        openNow: true,
      );

      verify(apiCall).called(1);
    });

    test('fetchYelpSearchInfo 在 _offset >= 1000 時主動攔截不再呼叫 API', () async {
      when(
        () => api.businessesSearch(
          term: any(named: 'term'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          locale: any(named: 'locale'),
          price: any(named: 'price'),
          openAt: any(named: 'openAt'),
          sortBy: any(named: 'sortBy'),
          categories: any(named: 'categories'),
          radius: any(named: 'radius'),
          openNow: any(named: 'openNow'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => _Data.empty);
      when(
        () => favorDataSource.fetchFavorIds(),
      ).thenAnswer((_) async => <String>{});

      for (int i = 0; i < 20; i++) {
        await repo.fetchYelpSearchInfo(
          _Data.lat,
          _Data.lng,
          _Data.price,
          _Data.openAt,
          _Data.sortBy,
        );
      }

      await repo.fetchYelpSearchInfo(
        _Data.lat,
        _Data.lng,
        _Data.price,
        _Data.openAt,
        _Data.sortBy,
      );

      verify(
        () => api.businessesSearch(
          term: any(named: 'term'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          locale: any(named: 'locale'),
          price: any(named: 'price'),
          openAt: any(named: 'openAt'),
          sortBy: any(named: 'sortBy'),
          categories: any(named: 'categories'),
          radius: any(named: 'radius'),
          openNow: any(named: 'openNow'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).called(20);
    });
  });
}
