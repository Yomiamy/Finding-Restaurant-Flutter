import 'package:get_it/get_it.dart';

import '../../api/api_barrel.dart';
import '../../app/constants/constants_barrel.dart';
import '../../domain/repositories/yelp_business_repository.dart';

class YelpBusinessRepo implements YelpBusinessRepository {
  // ponytail: Yelp 官方目前唯一合法的 transaction_type，出現新類型時改成參數
  static const String _transactionType = 'delivery';
  // Yelp 的陣列參數是逗號分隔字串；APIClz 維持 String?，由這裡負責串接。
  static const String _listSeparator = ',';

  final APIClz _api;

  YelpBusinessRepo({APIClz? api}) : _api = api ?? GetIt.I<APIClz>();

  @override
  Future<YelpSearchDto> searchByPhone(String phone) =>
      _api.businessesSearchByPhone(phone, Constants.locale);

  @override
  Future<YelpSearchDto> matchBusinesses({
    required String name,
    required String address1,
    required String city,
    required String state,
    required String country,
    String? address2,
    String? address3,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? phone,
    String? yelpBusinessId,
    int? limit,
    String? matchThreshold,
  }) => _api.businessesMatches(
    name: name,
    address1: address1,
    city: city,
    state: state,
    country: country,
    address2: address2,
    address3: address3,
    postalCode: postalCode,
    latitude: latitude,
    longitude: longitude,
    phone: phone,
    yelpBusinessId: yelpBusinessId,
    limit: limit,
    matchThreshold: matchThreshold,
  );

  @override
  Future<YelpSearchDto> searchDelivery({
    String? location,
    double? latitude,
    double? longitude,
    String? term,
    List<String>? categories,
    List<int>? price,
  }) => _api.transactionsSearch(
    _transactionType,
    location: location,
    latitude: latitude,
    longitude: longitude,
    term: term,
    categories: categories?.join(_listSeparator),
    price: price?.join(_listSeparator),
  );

  @override
  Future<YelpEngagementDto> fetchEngagement(
    List<String> businessIds, {
    String? dateRangeStart,
    String? dateRangeEnd,
  }) => _api.businessesEngagement(
    businessIds.join(_listSeparator),
    dateRangeStart: dateRangeStart,
    dateRangeEnd: dateRangeEnd,
  );

  @override
  Future<YelpServiceOfferingsDto> fetchServiceOfferings(
    String businessIdOrAlias,
  ) => _api.businessServiceOfferings(businessIdOrAlias, Constants.locale);

  @override
  Future<YelpReviewHighlightsDto> fetchReviewHighlights(
    String businessIdOrAlias, {
    int? count,
  }) => _api.businessReviewHighlights(
    businessIdOrAlias,
    count: count,
    locale: Constants.locale,
  );
}
