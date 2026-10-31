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

  group('參數轉發與 Yelp 遠端查詢', () {
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

    test('指定 term 時直通遠端以該關鍵字查詢 Yelp', () async {
      when(
        () => api.businessesSearch(
          term: 'Ramen',
          latitude: _Data.lat,
          longitude: _Data.lng,
          locale: _Data.locale,
          price: _Data.price,
          openAt: _Data.openAt,
          sortBy: _Data.sortBy,
          limit: 50,
          offset: 0,
        ),
      ).thenAnswer((_) async => _Data.empty);
      when(
        () => favorDataSource.fetchFavorIds(),
      ).thenAnswer((_) async => <String>{});

      await repo.fetchYelpSearchInfo(
        _Data.lat,
        _Data.lng,
        _Data.price,
        _Data.openAt,
        _Data.sortBy,
        term: 'Ramen',
      );

      verify(
        () => api.businessesSearch(
          term: 'Ramen',
          latitude: _Data.lat,
          longitude: _Data.lng,
          locale: _Data.locale,
          price: _Data.price,
          openAt: _Data.openAt,
          sortBy: _Data.sortBy,
          limit: 50,
          offset: 0,
        ),
      ).called(1);
    });

    test('切換不同 term 時重置 offset 為 0 並清空 summaryInfoSet', () async {
      final dto1 = YelpRestaurantSummaryDto(id: 'r1', name: 'Ramen 1');
      final dto2 = YelpRestaurantSummaryDto(id: 's1', name: 'Sushi 1');

      when(
        () => api.businessesSearch(
          term: 'Ramen',
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          locale: any(named: 'locale'),
          price: any(named: 'price'),
          openAt: any(named: 'openAt'),
          sortBy: any(named: 'sortBy'),
          limit: any(named: 'limit'),
          offset: 0,
        ),
      ).thenAnswer((_) async => YelpSearchDto(businesses: [dto1]));

      when(
        () => api.businessesSearch(
          term: 'Sushi',
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          locale: any(named: 'locale'),
          price: any(named: 'price'),
          openAt: any(named: 'openAt'),
          sortBy: any(named: 'sortBy'),
          limit: any(named: 'limit'),
          offset: 0,
        ),
      ).thenAnswer((_) async => YelpSearchDto(businesses: [dto2]));

      when(
        () => favorDataSource.fetchFavorIds(),
      ).thenAnswer((_) async => <String>{});

      // 首次以 Ramen 查詢
      final list1 = await repo.fetchYelpSearchInfo(
        _Data.lat,
        _Data.lng,
        null,
        null,
        null,
        term: 'Ramen',
      );
      expect(list1.map((e) => e.id), ['r1']);
      expect(repo.summaryInfoSet.map((e) => e.id), ['r1']);

      // 切換為 Sushi 查詢，應重置清單與 offset
      final list2 = await repo.fetchYelpSearchInfo(
        _Data.lat,
        _Data.lng,
        null,
        null,
        null,
        term: 'Sushi',
      );
      expect(list2.map((e) => e.id), ['s1']);
      expect(repo.summaryInfoSet.map((e) => e.id), ['s1']);
    });

    test('分頁載入時（未傳入 term）沿用當前生效關鍵字並累加 offset', () async {
      final dto1 = YelpRestaurantSummaryDto(id: 'r1', name: 'Ramen 1');
      final dto2 = YelpRestaurantSummaryDto(id: 'r2', name: 'Ramen 2');

      when(
        () => api.businessesSearch(
          term: 'Ramen',
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          locale: any(named: 'locale'),
          price: any(named: 'price'),
          openAt: any(named: 'openAt'),
          sortBy: any(named: 'sortBy'),
          limit: any(named: 'limit'),
          offset: 0,
        ),
      ).thenAnswer((_) async => YelpSearchDto(businesses: [dto1]));

      when(
        () => api.businessesSearch(
          term: 'Ramen',
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          locale: any(named: 'locale'),
          price: any(named: 'price'),
          openAt: any(named: 'openAt'),
          sortBy: any(named: 'sortBy'),
          limit: any(named: 'limit'),
          offset: 50,
        ),
      ).thenAnswer((_) async => YelpSearchDto(businesses: [dto2]));

      when(
        () => favorDataSource.fetchFavorIds(),
      ).thenAnswer((_) async => <String>{});

      // 第一頁
      await repo.fetchYelpSearchInfo(
        _Data.lat,
        _Data.lng,
        null,
        null,
        null,
        term: 'Ramen',
      );

      // 第二頁（分頁載入，term 為 null）
      await repo.fetchYelpSearchInfo(_Data.lat, _Data.lng, null, null, null);

      verify(
        () => api.businessesSearch(
          term: 'Ramen',
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          locale: any(named: 'locale'),
          price: any(named: 'price'),
          openAt: any(named: 'openAt'),
          sortBy: any(named: 'sortBy'),
          limit: any(named: 'limit'),
          offset: 50,
        ),
      ).called(1);

      expect(repo.summaryInfoSet.map((e) => e.id), ['r1', 'r2']);
    });
  });
}
