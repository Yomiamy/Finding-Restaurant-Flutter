import 'package:dio/dio.dart' hide Headers;
import 'package:flutter/foundation.dart';
import 'package:flutter_inspector_kit/flutter_inspector_kit.dart';
import 'package:logger/logger.dart';
import 'package:retrofit/retrofit.dart';

import 'dto/dto_barrel.dart';
import '../app/di/di_barrel.dart';
import '../app/constants/constants_barrel.dart';
import 'dio/dio_barrel.dart';

part 'api_clz.g.dart';

@RestApi(baseUrl: Constants.baseUrl)
abstract class APIClz {
  factory APIClz(Dio dio, {String? baseUrl}) = _APIClz;

  @GET('/v3/businesses/search')
  Future<YelpSearchDto> businessesSearch({
    @Query('term') String? term,
    @Query('location') String? location,
    @Query('latitude') double? latitude,
    @Query('longitude') double? longitude,
    @Query('locale') String? locale,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('open_at') int? openAt,
    @Query('sort_by') String? sortBy,
    @Query('price') String? price,
  });

  @GET('/v3/businesses/{id}')
  Future<YelpRestaurantDetailDto> business(
    @Path() String? id,
    @Query('locale') String? locale,
  );

  @GET('/v3/businesses/{id}/reviews')
  Future<YelpReviewDto> review(
    @Path() String? id,
    @Query('locale') String? locale,
  );

  @GET('/v3/businesses/search/phone')
  Future<YelpSearchDto> businessesSearchByPhone(
    @Query('phone') String phone,
    @Query('locale') String? locale,
  );

  @GET('/v3/businesses/matches')
  Future<YelpSearchDto> businessesMatches({
    @Query('name') required String name,
    @Query('address1') required String address1,
    @Query('city') required String city,
    @Query('state') required String state,
    @Query('country') required String country,
    @Query('address2') String? address2,
    @Query('address3') String? address3,
    @Query('postal_code') String? postalCode,
    @Query('latitude') double? latitude,
    @Query('longitude') double? longitude,
    @Query('phone') String? phone,
    @Query('yelp_business_id') String? yelpBusinessId,
    @Query('limit') int? limit,
    @Query('match_threshold') String? matchThreshold,
  });

  @GET('/v3/transactions/{transaction_type}/search')
  Future<YelpSearchDto> transactionsSearch(
    @Path('transaction_type') String transactionType, {
    @Query('location') String? location,
    @Query('latitude') double? latitude,
    @Query('longitude') double? longitude,
    @Query('term') String? term,
    @Query('categories') String? categories,
    @Query('price') String? price,
  });

  @GET('/v3/businesses/engagement')
  Future<YelpEngagementDto> businessesEngagement(
    @Query('business_ids') String businessIds, {
    @Query('date_range_start') String? dateRangeStart,
    @Query('date_range_end') String? dateRangeEnd,
  });

  /// ⚠️ 僅供參照：Yelp 已標為 deprecated（改由 Business Details 的 Jobs offered 取代），
  /// 且需特別權限，一般 API Key 回 403。新功能不要使用。
  @GET('/v3/businesses/{business_id_or_alias}/service_offerings')
  Future<YelpServiceOfferingsDto> businessServiceOfferings(
    @Path('business_id_or_alias') String businessIdOrAlias,
    @Query('locale') String? locale,
  );

  @GET('/v3/businesses/{business_id_or_alias}/review_highlights')
  Future<YelpReviewHighlightsDto> businessReviewHighlights(
    @Path('business_id_or_alias') String businessIdOrAlias, {
    @Query('count') int? count,
    @Query('locale') String? locale,
  });

  @GET('/v3/events')
  Future<YelpEventSearchDto> eventsSearch({
    @Query('locale') String? locale,
    @Query('offset') int? offset,
    @Query('limit') int? limit,
    @Query('sort_by') String? sortBy,
    @Query('sort_on') String? sortOn,
    @Query('start_date') int? startDate,
    @Query('end_date') int? endDate,
    @Query('categories') String? categories,
    @Query('is_free') bool? isFree,
    @Query('excluded_events') String? excludedEvents,
    @Query('location') String? location,
    @Query('latitude') double? latitude,
    @Query('longitude') double? longitude,
    @Query('radius') int? radius,
  });

  @GET('/v3/events/featured')
  Future<YelpEventDto> featuredEvent({
    @Query('locale') String? locale,
    @Query('location') String? location,
    @Query('latitude') double? latitude,
    @Query('longitude') double? longitude,
  });

  @GET('/v3/events/{event_id}')
  Future<YelpEventDto> event(
    @Path('event_id') String eventId,
    @Query('locale') String? locale,
  );

  @GET('/v3/categories')
  Future<YelpCategoryListDto> categories(@Query('locale') String? locale);

  @GET('/v3/categories/{alias}')
  Future<YelpCategoryDetailDto> category(
    @Path('alias') String alias,
    @Query('locale') String? locale,
  );

  @GET('/v3/autocomplete')
  Future<YelpAutocompleteDto> autocomplete(
    @Query('text') String text, {
    @Query('locale') String? locale,
    @Query('latitude') double? latitude,
    @Query('longitude') double? longitude,
  });
}

final dioClient = () {
  final client = DioClient(
    connectionTimeout: Constants.connectionTimeout,
    receiveTimeout: Constants.receiveTimeout,
    // release 不記錄請求 URI 與回應內容（含座標、搜尋字、電話）。
    isLogEnabled: kDebugMode,
    interceptWraps: [
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          var customHeaders = {
            'Content-Type': 'application/json',
            'Authorization': AiModelConfig().yelpAuthToken,
          };
          options.headers.addAll(customHeaders);
          handler.next(options);
        },
      ),
    ],
  );
  final insp = inspector;
  if (kDebugMode && insp != null) {
    client.dio.interceptors.add(
      FlutterInspectorDioInterceptor(insp, sourceDio: client.dio),
    );
  }
  return client;
}();
final apiInstance = APIClz(dioClient.dio);
final logger = Logger();
