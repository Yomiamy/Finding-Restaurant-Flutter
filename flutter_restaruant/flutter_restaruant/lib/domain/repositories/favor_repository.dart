import '../entities/entities_barrel.dart';

abstract interface class FavorRepository {
  Future<List<RestaurantEntity>> fetchFavorInfos(bool isRefreshLocalOnly);

  /// Returns the persisted entity so callers adopt the new favor value
  /// instead of deriving it a second time.
  Future<RestaurantEntity> toggleFavor(RestaurantEntity summaryInfo);
}
