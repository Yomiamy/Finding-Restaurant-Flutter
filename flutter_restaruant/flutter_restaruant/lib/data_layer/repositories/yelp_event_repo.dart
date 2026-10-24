import 'package:get_it/get_it.dart';

import '../../api/api_barrel.dart';
import '../../app/constants/constants_barrel.dart';
import '../../domain/repositories/yelp_event_repository.dart';

class YelpEventRepo implements YelpEventRepository {
  // Yelp 的陣列參數是逗號分隔字串；APIClz 維持 String?，由這裡負責串接。
  static const String _listSeparator = ',';

  final APIClz _api;

  YelpEventRepo({APIClz? api}) : _api = api ?? GetIt.I<APIClz>();

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
    locale: Constants.locale,
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
      _api.event(eventId, Constants.locale);

  @override
  Future<YelpEventDto> fetchFeaturedEvent({
    String? location,
    double? latitude,
    double? longitude,
  }) => _api.featuredEvent(
    locale: Constants.locale,
    location: location,
    latitude: latitude,
    longitude: longitude,
  );
}
