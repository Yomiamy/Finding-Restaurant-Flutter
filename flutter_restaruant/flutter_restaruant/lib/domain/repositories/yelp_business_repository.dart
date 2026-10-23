import '../../api/dto/dto_barrel.dart';

/// Yelp Places API 中以 Business 為主資源的端點。
///
/// 所有方法失敗時原樣拋出 `DioException`，不做轉換。
abstract interface class YelpBusinessRepository {
  /// `GET /v3/businesses/search/phone`；[phone] 須以 `+` 開頭並含國碼。
  Future<YelpSearchDto> searchByPhone(String phone);

  /// `GET /v3/businesses/matches`；回應沒有 `total`，[YelpSearchDto.total] 恆為 null。
  ///
  /// [address1] 可為空字串，用於比對沒有街道地址的服務型商家。
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
  });

  /// `GET /v3/transactions/delivery/search`；[location] 與
  /// [latitude]+[longitude] 擇一（不在 client 端驗證）。
  Future<YelpSearchDto> searchDelivery({
    String? location,
    double? latitude,
    double? longitude,
    String? term,
    List<String>? categories,
    List<int>? price,
  });

  /// `GET /v3/businesses/engagement`（最多 20 個 id）。
  ///
  /// 需 Yelp 另行開通權限（Yelp Insights）；未開通時拋出 `DioException`，
  /// `response?.statusCode == 403`。
  Future<YelpEngagementDto> fetchEngagement(
    List<String> businessIds, {
    String? dateRangeStart,
    String? dateRangeEnd,
  });

  /// `GET /v3/businesses/{id}/service_offerings`。
  ///
  /// Yelp 已標為 deprecated，且需特別權限；未開通時拋出 `DioException`，
  /// `response?.statusCode == 403`。
  Future<YelpServiceOfferingsDto> fetchServiceOfferings(
    String businessIdOrAlias,
  );

  /// `GET /v3/businesses/{id}/review_highlights`。
  ///
  /// 需 Premium Plan；未開通時拋出 `DioException`，`response?.statusCode == 403`。
  Future<YelpReviewHighlightsDto> fetchReviewHighlights(
    String businessIdOrAlias, {
    int? count,
  });
}
