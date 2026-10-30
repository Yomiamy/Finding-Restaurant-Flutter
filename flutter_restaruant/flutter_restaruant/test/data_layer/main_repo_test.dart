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
  static const String price = '2';
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

  group('參數轉發與 location 回退', () {
    test('fetchYelpSearchInfo 帶入座標、篩選條件與注入的 locale（location 為 null）', () async {
      Future<YelpSearchDto> apiCall() => api.businessesSearch(
        term: 'Restaurants',
        latitude: _Data.lat,
        longitude: _Data.lng,
        location: null,
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
        lat: _Data.lat,
        lng: _Data.lng,
        price: _Data.price,
        openAt: _Data.openAt,
        sortByStr: _Data.sortBy,
      );

      verify(apiCall).called(1);
    });

    test('fetchYelpSearchInfo 座標為 null 時回退至預設地名 Taipei', () async {
      Future<YelpSearchDto> apiCall() => api.businessesSearch(
        term: 'Restaurants',
        latitude: null,
        longitude: null,
        location: 'Taipei',
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
        lat: null,
        lng: null,
        price: _Data.price,
        openAt: _Data.openAt,
        sortByStr: _Data.sortBy,
      );

      verify(apiCall).called(1);
    });

    test('fetchYelpSearchInfo 座標為 null 且指定 location 時使用傳入之 location', () async {
      Future<YelpSearchDto> apiCall() => api.businessesSearch(
        term: 'Restaurants',
        latitude: null,
        longitude: null,
        location: 'Tainan',
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
        lat: null,
        lng: null,
        location: 'Tainan',
        price: _Data.price,
        openAt: _Data.openAt,
        sortByStr: _Data.sortBy,
      );

      verify(apiCall).called(1);
    });
  });
}
