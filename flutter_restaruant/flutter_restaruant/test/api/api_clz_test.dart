import 'package:dio/dio.dart';
import 'package:flutter_restaruant/api/api_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

class _Data {
  static const String locale = 'zh_TW';
}

void _expectGet(
  RequestOptions o, {
  required String path,
  required Map<String, dynamic> query,
}) {
  expect(o.method, 'GET');
  expect(o.path, path);
  expect(o.queryParameters, query);
}

void main() {
  late List<RequestOptions> requests;
  late APIClz api;

  setUp(() {
    requests = [];
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            // 所有 DTO 欄位皆 nullable，空物件足以讓 fromJson 成功。
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{},
              ),
            );
          },
        ),
      );
    api = APIClz(dio);
  });

  test('#1 businessesSearchByPhone', () async {
    await api.businessesSearchByPhone('+14157492060', _Data.locale);
    _expectGet(
      requests.single,
      path: '/v3/businesses/search/phone',
      query: {'phone': '+14157492060', 'locale': _Data.locale},
    );
  });

  test('#2 businessesMatches 保留空字串 address1', () async {
    await api.businessesMatches(
      name: 'N',
      address1: '',
      city: 'C',
      state: 'CA',
      country: 'US',
      address2: 'a2',
      address3: 'a3',
      postalCode: '94109',
      latitude: 1.0,
      longitude: 2.0,
      phone: '+1',
      yelpBusinessId: 'x' * 22,
      limit: 3,
      matchThreshold: 'strict',
    );
    _expectGet(
      requests.single,
      path: '/v3/businesses/matches',
      query: {
        'name': 'N',
        'address1': '',
        'city': 'C',
        'state': 'CA',
        'country': 'US',
        'address2': 'a2',
        'address3': 'a3',
        'postal_code': '94109',
        'latitude': 1.0,
        'longitude': 2.0,
        'phone': '+1',
        'yelp_business_id': 'x' * 22,
        'limit': 3,
        'match_threshold': 'strict',
      },
    );
  });

  test('#3 transactionsSearch', () async {
    await api.transactionsSearch(
      'delivery',
      location: 'SF',
      latitude: 1.0,
      longitude: 2.0,
      term: 't',
      categories: 'bars,french',
      price: '1,2',
    );
    _expectGet(
      requests.single,
      path: '/v3/transactions/delivery/search',
      query: {
        'location': 'SF',
        'latitude': 1.0,
        'longitude': 2.0,
        'term': 't',
        'categories': 'bars,french',
        'price': '1,2',
      },
    );
  });

  test('#4 businessesEngagement', () async {
    await api.businessesEngagement(
      'a,b',
      dateRangeStart: '2026-01-01',
      dateRangeEnd: '2026-02-01',
    );
    _expectGet(
      requests.single,
      path: '/v3/businesses/engagement',
      query: {
        'business_ids': 'a,b',
        'date_range_start': '2026-01-01',
        'date_range_end': '2026-02-01',
      },
    );
  });

  test('#5 businessServiceOfferings', () async {
    await api.businessServiceOfferings('biz', _Data.locale);
    _expectGet(
      requests.single,
      path: '/v3/businesses/biz/service_offerings',
      query: {'locale': _Data.locale},
    );
  });

  test('#6 businessReviewHighlights', () async {
    await api.businessReviewHighlights('biz', count: 5, locale: _Data.locale);
    _expectGet(
      requests.single,
      path: '/v3/businesses/biz/review_highlights',
      query: {'count': 5, 'locale': _Data.locale},
    );
  });

  test('#7 eventsSearch', () async {
    await api.eventsSearch(
      locale: _Data.locale,
      offset: 10,
      limit: 20,
      sortBy: 'asc',
      sortOn: 'time_start',
      startDate: 1700000000,
      endDate: 1700086400,
      categories: 'music,food',
      isFree: true,
      excludedEvents: 'e1,e2',
      location: 'SF',
      latitude: 1.0,
      longitude: 2.0,
      radius: 500,
    );
    _expectGet(
      requests.single,
      path: '/v3/events',
      query: {
        'locale': _Data.locale,
        'offset': 10,
        'limit': 20,
        'sort_by': 'asc',
        'sort_on': 'time_start',
        'start_date': 1700000000,
        'end_date': 1700086400,
        'categories': 'music,food',
        'is_free': true,
        'excluded_events': 'e1,e2',
        'location': 'SF',
        'latitude': 1.0,
        'longitude': 2.0,
        'radius': 500,
      },
    );
  });

  test('#8 event', () async {
    await api.event('evt', _Data.locale);
    _expectGet(
      requests.single,
      path: '/v3/events/evt',
      query: {'locale': _Data.locale},
    );
  });

  test('#9 featuredEvent', () async {
    await api.featuredEvent(
      locale: _Data.locale,
      location: 'SF',
      latitude: 1.0,
      longitude: 2.0,
    );
    _expectGet(
      requests.single,
      path: '/v3/events/featured',
      query: {
        'locale': _Data.locale,
        'location': 'SF',
        'latitude': 1.0,
        'longitude': 2.0,
      },
    );
  });

  test('#10 categories', () async {
    await api.categories(_Data.locale);
    _expectGet(
      requests.single,
      path: '/v3/categories',
      query: {'locale': _Data.locale},
    );
  });

  test('#11 category', () async {
    await api.category('bars', _Data.locale);
    _expectGet(
      requests.single,
      path: '/v3/categories/bars',
      query: {'locale': _Data.locale},
    );
  });

  test('#12 autocomplete', () async {
    await api.autocomplete(
      'pizza',
      locale: _Data.locale,
      latitude: 1.0,
      longitude: 2.0,
    );
    _expectGet(
      requests.single,
      path: '/v3/autocomplete',
      query: {
        'text': 'pizza',
        'locale': _Data.locale,
        'latitude': 1.0,
        'longitude': 2.0,
      },
    );
  });
}
