import '../entities/restaurant_entity.dart';

abstract interface class FavorRepository {
  Future<List<RestaurantEntity>> fetchFavorInfos(
      bool isRefreshLocalOnly);

  Future<void> toggleFavor(RestaurantEntity summaryInfo);
}
