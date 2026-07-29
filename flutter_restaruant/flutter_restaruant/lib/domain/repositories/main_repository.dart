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

  /// Returns the persisted entity so callers adopt the new favor value
  /// instead of deriving it a second time.
  Future<RestaurantEntity> toggleFavor(RestaurantEntity summaryInfo);
}
