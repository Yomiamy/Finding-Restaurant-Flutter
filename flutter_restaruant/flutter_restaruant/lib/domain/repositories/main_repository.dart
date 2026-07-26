import '../entities/restaurant_entity.dart';

abstract interface class MainRepository {
  Set<RestaurantEntity> get summaryInfoSet;

  void reset();

  Future<List<RestaurantEntity>> fetchYelpSearchInfo(
    double lat,
    double lng,
    int? price,
    int? openAt,
    String? sortByStr,
  );

  Future<List<RestaurantEntity>> filterByKeyword(
    String keyword,
    String? sortByStr,
  );

  Future<void> toggleFavor(RestaurantEntity summaryInfo);
}
