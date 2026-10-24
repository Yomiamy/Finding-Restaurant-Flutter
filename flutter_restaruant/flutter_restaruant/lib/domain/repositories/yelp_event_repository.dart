import '../../api/dto/dto_barrel.dart';

/// Yelp Places API 中以 Event 為主資源的端點。
///
/// HTTP 失敗原樣拋出 `DioException`，不做轉換；回應格式不符時拋 `CheckedFromJsonException`。
abstract interface class YelpEventRepository {
  /// `GET /v3/events`；[startDate]/[endDate] 為 Unix timestamp（秒）。
  /// 不篩選時 [categories]／[excludedEvents] 傳 null，不要傳空 list（會送出空參數）。
  Future<YelpEventSearchDto> searchEvents({
    int? offset,
    int? limit,
    String? sortBy,
    String? sortOn,
    int? startDate,
    int? endDate,
    List<String>? categories,
    bool? isFree,
    List<String>? excludedEvents,
    String? location,
    double? latitude,
    double? longitude,
    int? radius,
  });

  /// `GET /v3/events/{event_id}`。
  Future<YelpEventDto> fetchEvent(String eventId);

  /// `GET /v3/events/featured`；[location] 與 [latitude]+[longitude] 擇一（不在 client 端驗證）。
  Future<YelpEventDto> fetchFeaturedEvent({
    String? location,
    double? latitude,
    double? longitude,
  });
}
