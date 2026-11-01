import 'dart:async';

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
        lat: _Data.lat,
        lng: _Data.lng,
        price: _Data.price,
        openAt: _Data.openAt,
        sortByStr: _Data.sortBy,
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
        lat: _Data.lat,
        lng: _Data.lng,
        term: 'Ramen',
      );
      expect(list1.map((e) => e.id), ['r1']);
      expect(repo.summaryInfoSet.map((e) => e.id), ['r1']);

      // 切換為 Sushi 查詢，應重置清單與 offset
      final list2 = await repo.fetchYelpSearchInfo(
        lat: _Data.lat,
        lng: _Data.lng,
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
        lat: _Data.lat,
        lng: _Data.lng,
        term: 'Ramen',
      );

      // 第二頁（分頁載入，term 為 null）
      await repo.fetchYelpSearchInfo(lat: _Data.lat, lng: _Data.lng);

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

    test('再次以相同 term 查詢時應重置 offset 為 0 並清空 summaryInfoSet 而非繼續翻頁', () async {
      final dto1 = YelpRestaurantSummaryDto(id: 'r1', name: 'Ramen 1');
      final dto2 = YelpRestaurantSummaryDto(id: 'r2', name: 'Ramen 2');
      final dto3 = YelpRestaurantSummaryDto(
        id: 'r1_fresh',
        name: 'Ramen Fresh',
      );

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

      // 載入第一頁
      await repo.fetchYelpSearchInfo(
        lat: _Data.lat,
        lng: _Data.lng,
        term: 'Ramen',
      );
      // 載入第二頁
      await repo.fetchYelpSearchInfo(lat: _Data.lat, lng: _Data.lng);
      expect(repo.summaryInfoSet.length, 2);

      // 當再次傳入相同 term 重新搜尋，模擬回傳新第一頁
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
      ).thenAnswer((_) async => YelpSearchDto(businesses: [dto3]));

      final res = await repo.fetchYelpSearchInfo(
        lat: _Data.lat,
        lng: _Data.lng,
        term: 'Ramen',
      );
      expect(res.map((e) => e.id), ['r1_fresh']);
      expect(repo.summaryInfoSet.map((e) => e.id), ['r1_fresh']);
    });

    test('新搜尋請求發起時應使在途中舊請求失效避免結果混雜', () async {
      final completerOld = Completer<YelpSearchDto>();
      final dtoOld = YelpRestaurantSummaryDto(id: 'old1', name: 'Old 1');
      final dtoNew = YelpRestaurantSummaryDto(id: 'new1', name: 'New 1');

      when(
        () => api.businessesSearch(
          term: 'Restaurants',
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          locale: any(named: 'locale'),
          price: any(named: 'price'),
          openAt: any(named: 'openAt'),
          sortBy: any(named: 'sortBy'),
          limit: any(named: 'limit'),
          offset: 0,
        ),
      ).thenAnswer((_) => completerOld.future);

      when(
        () => api.businessesSearch(
          term: 'Burger',
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          locale: any(named: 'locale'),
          price: any(named: 'price'),
          openAt: any(named: 'openAt'),
          sortBy: any(named: 'sortBy'),
          limit: any(named: 'limit'),
          offset: 0,
        ),
      ).thenAnswer((_) async => YelpSearchDto(businesses: [dtoNew]));

      when(
        () => favorDataSource.fetchFavorIds(),
      ).thenAnswer((_) async => <String>{});

      // 發起第一個請求（仍在途中）
      final future1 = repo.fetchYelpSearchInfo(
        lat: _Data.lat,
        lng: _Data.lng,
      );

      // 使用者立刻發起新關鍵字搜尋 Burger
      final future2 = repo.fetchYelpSearchInfo(
        lat: _Data.lat,
        lng: _Data.lng,
        term: 'Burger',
      );

      final res2 = await future2;
      expect(res2.map((e) => e.id), ['new1']);
      expect(repo.summaryInfoSet.map((e) => e.id), ['new1']);

      // 稍後舊請求才完成，不應污染當前結果
      completerOld.complete(YelpSearchDto(businesses: [dtoOld]));
      await future1;

      expect(repo.summaryInfoSet.map((e) => e.id), ['new1']);
    });

    test('fetchYelpSearchInfo 帶入進階篩選 categories、radius、openNow', () async {
      Future<YelpSearchDto> apiCall() => api.businessesSearch(
        term: 'Restaurants',
        latitude: _Data.lat,
        longitude: _Data.lng,
        locale: _Data.locale,
        price: _Data.price,
        openAt: null,
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
        lat: _Data.lat,
        lng: _Data.lng,
        price: _Data.price,
        openAt: _Data.openAt,
        sortByStr: _Data.sortBy,
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
          lat: _Data.lat,
          lng: _Data.lng,
          price: _Data.price,
          openAt: _Data.openAt,
          sortByStr: _Data.sortBy,
        );
      }

      await repo.fetchYelpSearchInfo(
        lat: _Data.lat,
        lng: _Data.lng,
        price: _Data.price,
        openAt: _Data.openAt,
        sortByStr: _Data.sortBy,
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

    test('openNow 與 openAt 同時提供時，優先使用 openNow 並將 openAt 置為 null', () async {
      when(
        () => api.businessesSearch(
          term: any(named: 'term'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          locale: any(named: 'locale'),
          price: any(named: 'price'),
          openAt: null,
          sortBy: any(named: 'sortBy'),
          categories: any(named: 'categories'),
          radius: any(named: 'radius'),
          openNow: true,
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => _Data.empty);
      when(
        () => favorDataSource.fetchFavorIds(),
      ).thenAnswer((_) async => <String>{});

      await repo.fetchYelpSearchInfo(
        lat: _Data.lat,
        lng: _Data.lng,
        price: _Data.price,
        openAt: 12345,
        sortByStr: _Data.sortBy,
        openNow: true,
      );

      verify(
        () => api.businessesSearch(
          term: 'Restaurants',
          latitude: _Data.lat,
          longitude: _Data.lng,
          locale: _Data.locale,
          price: _Data.price,
          openAt: null,
          sortBy: _Data.sortBy,
          categories: null,
          radius: null,
          openNow: true,
          limit: 50,
          offset: 0,
        ),
      ).called(1);
    });
  });
}
