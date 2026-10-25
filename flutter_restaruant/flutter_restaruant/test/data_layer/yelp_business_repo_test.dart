import 'package:dio/dio.dart';
import 'package:flutter_restaruant/api/api_barrel.dart';
import 'package:flutter_restaruant/app/constants/constants_barrel.dart';
import 'package:flutter_restaruant/data_layer/repositories/yelp_business_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAPIClz extends Mock implements APIClz {}

class _Data {
  static const String phone = '+14157492060';
  static const String businessId = 'north-india-restaurant-san-francisco';

  // 內容各不相同，same() 才分辨得出是不是同一個物件。
  static const YelpSearchDto byPhone = YelpSearchDto(total: 1);
  static const YelpSearchDto matches = YelpSearchDto(businesses: []);
  static const YelpSearchDto delivery = YelpSearchDto(total: 3);
  static const YelpEngagementDto engagement = YelpEngagementDto(data: []);
  static const YelpServiceOfferingsDto offerings = YelpServiceOfferingsDto(
    active: ['delivery'],
  );
  static const YelpReviewHighlightsDto highlights = YelpReviewHighlightsDto(
    reviewHighlights: [],
  );

  static DioException forbidden() => DioException(
    requestOptions: RequestOptions(),
    response: Response(requestOptions: RequestOptions(), statusCode: 403),
    type: DioExceptionType.badResponse,
  );
}

final Matcher _throwsForbidden = throwsA(
  isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 403),
);

void main() {
  late _MockAPIClz api;
  late YelpBusinessRepo repo;

  setUp(() {
    api = _MockAPIClz();
    repo = YelpBusinessRepo(api: api);
  });

  group('參數轉發與原樣回傳', () {
    test('searchByPhone 帶入 Constants.locale', () async {
      Future<YelpSearchDto> apiCall() =>
          api.businessesSearchByPhone(_Data.phone, Constants.locale);
      when(apiCall).thenAnswer((_) async => _Data.byPhone);

      final result = await repo.searchByPhone(_Data.phone);

      expect(result, same(_Data.byPhone));
      verify(apiCall).called(1);
    });

    test('matchBusinesses 逐一透傳 14 個參數，空字串 address1 不變', () async {
      Future<YelpSearchDto> apiCall() => api.businessesMatches(
        name: 'N',
        address1: '',
        city: 'C',
        state: 'CA',
        country: 'US',
        address2: 'a2',
        address3: 'a3',
        postalCode: '94105',
        latitude: 37.78,
        longitude: -122.41,
        phone: '+14155550100',
        yelpBusinessId: 'yid',
        limit: 3,
        matchThreshold: 'default',
      );
      when(apiCall).thenAnswer((_) async => _Data.matches);

      final result = await repo.matchBusinesses(
        name: 'N',
        address1: '',
        city: 'C',
        state: 'CA',
        country: 'US',
        address2: 'a2',
        address3: 'a3',
        postalCode: '94105',
        latitude: 37.78,
        longitude: -122.41,
        phone: '+14155550100',
        yelpBusinessId: 'yid',
        limit: 3,
        matchThreshold: 'default',
      );

      expect(result, same(_Data.matches));
      verify(apiCall).called(1);
    });

    test('searchDelivery 固定 delivery，categories 與 price 以逗號串接', () async {
      Future<YelpSearchDto> apiCall() => api.transactionsSearch(
        'delivery',
        location: 'San Francisco',
        latitude: 37.78,
        longitude: -122.41,
        term: 'pizza',
        categories: 'bars,french',
        price: '1,2',
      );
      when(apiCall).thenAnswer((_) async => _Data.delivery);

      final result = await repo.searchDelivery(
        location: 'San Francisco',
        latitude: 37.78,
        longitude: -122.41,
        term: 'pizza',
        categories: ['bars', 'french'],
        price: [1, 2],
      );

      expect(result, same(_Data.delivery));
      verify(apiCall).called(1);
    });

    test('fetchEngagement 以逗號串接 business ids', () async {
      Future<YelpEngagementDto> apiCall() => api.businessesEngagement(
        'a,b',
        dateRangeStart: '2026-10-01',
        dateRangeEnd: '2026-10-07',
      );
      when(apiCall).thenAnswer((_) async => _Data.engagement);

      final result = await repo.fetchEngagement(
        ['a', 'b'],
        dateRangeStart: '2026-10-01',
        dateRangeEnd: '2026-10-07',
      );

      expect(result, same(_Data.engagement));
      verify(apiCall).called(1);
    });

    test('fetchServiceOfferings 帶入 Constants.locale', () async {
      Future<YelpServiceOfferingsDto> apiCall() =>
          api.businessServiceOfferings(_Data.businessId, Constants.locale);
      when(apiCall).thenAnswer((_) async => _Data.offerings);

      final result = await repo.fetchServiceOfferings(_Data.businessId);

      expect(result, same(_Data.offerings));
      verify(apiCall).called(1);
    });

    test('fetchReviewHighlights 帶入 count 與 Constants.locale', () async {
      Future<YelpReviewHighlightsDto> apiCall() => api.businessReviewHighlights(
        _Data.businessId,
        count: 3,
        locale: Constants.locale,
      );
      when(apiCall).thenAnswer((_) async => _Data.highlights);

      final result = await repo.fetchReviewHighlights(
        _Data.businessId,
        count: 3,
      );

      expect(result, same(_Data.highlights));
      verify(apiCall).called(1);
    });
  });

  group('403 原樣拋出 DioException', () {
    test('searchByPhone', () async {
      when(
        () => api.businessesSearchByPhone(_Data.phone, Constants.locale),
      ).thenAnswer((_) async => throw _Data.forbidden());

      await expectLater(repo.searchByPhone(_Data.phone), _throwsForbidden);
    });

    test('fetchEngagement', () async {
      when(
        () => api.businessesEngagement(
          'a',
          dateRangeStart: null,
          dateRangeEnd: null,
        ),
      ).thenAnswer((_) async => throw _Data.forbidden());

      await expectLater(repo.fetchEngagement(['a']), _throwsForbidden);
    });

    test('fetchServiceOfferings', () async {
      when(
        () => api.businessServiceOfferings(_Data.businessId, Constants.locale),
      ).thenAnswer((_) async => throw _Data.forbidden());

      await expectLater(
        repo.fetchServiceOfferings(_Data.businessId),
        _throwsForbidden,
      );
    });

    test('fetchReviewHighlights', () async {
      when(
        () => api.businessReviewHighlights(
          _Data.businessId,
          count: null,
          locale: Constants.locale,
        ),
      ).thenAnswer((_) async => throw _Data.forbidden());

      await expectLater(
        repo.fetchReviewHighlights(_Data.businessId),
        _throwsForbidden,
      );
    });
  });
}
