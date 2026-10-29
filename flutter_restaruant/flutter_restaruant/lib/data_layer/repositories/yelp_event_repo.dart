import '../../api/api_barrel.dart';
import '../../domain/repositories/yelp_event_repository.dart';

class YelpEventRepo implements YelpEventRepository {
  // Yelp 的陣列參數是逗號分隔字串；APIClz 維持 String?，由這裡負責串接。
  static const String _listSeparator = ',';

  final APIClz _api;
  final String _locale;

  YelpEventRepo({required APIClz api, required String locale})
    : _api = api,
      _locale = locale;

  @override
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
  }) => _api.eventsSearch(
    locale: _locale,
    offset: offset,
    limit: limit,
    sortBy: sortBy,
    sortOn: sortOn,
    startDate: startDate,
    endDate: endDate,
    categories: categories?.join(_listSeparator),
    isFree: isFree,
    excludedEvents: excludedEvents?.join(_listSeparator),
    location: location,
    latitude: latitude,
    longitude: longitude,
    radius: radius,
  );

  @override
  Future<YelpEventDto> fetchEvent(String eventId) =>
      _api.event(eventId, _locale);

  @override
  Future<YelpEventDto> fetchFeaturedEvent({
    String? location,
    double? latitude,
    double? longitude,
  }) => _api.featuredEvent(
    locale: _locale,
    location: location,
    latitude: latitude,
    longitude: longitude,
  );
}
