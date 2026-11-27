import '../entities/entities_barrel.dart';

/// 共編美食地圖資料存取契約。
abstract interface class FoodMapRepository {
  String get currentUid;

  Future<List<FoodMapEntity>> fetchMyFoodMaps();

  Future<({FoodMapEntity map, List<FoodMapItemEntity> items})>
  fetchFoodMapDetail(String mapId);

  Future<FoodMapEntity> createFoodMap({
    required String title,
    String description = '',
  });

  Future<({FoodMapEntity map, bool alreadyMember})> joinFoodMapByInviteCode(
    String rawCode,
  );

  Future<void> deleteFoodMap(String mapId);

  Future<void> leaveFoodMap(String mapId);

  Future<({bool added, FoodMapItemEntity item})> addRestaurant({
    required String mapId,
    required RestaurantEntity restaurant,
    String note = '',
  });

  Future<({int addedCount, int skippedCount})> importRestaurants({
    required String mapId,
    required List<RestaurantEntity> restaurants,
  });

  Future<void> removeRestaurant({
    required String mapId,
    required String restaurantId,
  });

  Future<FoodMapItemEntity> updateItemNote({
    required String mapId,
    required String restaurantId,
    required String note,
  });

  Future<void> setVote({
    required String mapId,
    required String restaurantId,
    required FoodMapVote vote,
  });
}
