import '../../api/dto/dto_barrel.dart';

/// Yelp Places API 中以 Event 為主資源的端點。
///
/// 所有方法失敗時原樣拋出 `DioException`，不做轉換。
abstract interface class YelpEventRepository {
  /// `GET /v3/events`；[startDate]/[endDate] 為 Unix timestamp（秒）。
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

  /// `GET /v3/events/featured`；[location] 與 [latitude]+[longitude] 擇一。
  Future<YelpEventDto> fetchFeaturedEvent({
    String? location,
    double? latitude,
    double? longitude,
  });
}
