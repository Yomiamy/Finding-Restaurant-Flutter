import '../../domain/entities/entities_barrel.dart';
import '../../domain/repositories/repositories_barrel.dart';
import '../datasources/datasources_barrel.dart';

class FoodMapRepo implements FoodMapRepository {
  final FoodMapDataSource _dataSource;

  FoodMapRepo({FoodMapDataSource? dataSource})
    : _dataSource = dataSource ?? FoodMapDataSource();

  @override
  String get currentUid => _dataSource.currentUid;

  @override
  Future<List<FoodMapEntity>> fetchMyFoodMaps() =>
      _dataSource.fetchMyFoodMaps();

  @override
  Future<({FoodMapEntity map, List<FoodMapItemEntity> items})>
  fetchFoodMapDetail(String mapId) => _dataSource.fetchFoodMapDetail(mapId);

  @override
  Future<FoodMapEntity> createFoodMap({
    required String title,
    String description = '',
  }) => _dataSource.createFoodMap(title: title, description: description);

  @override
  Future<({FoodMapEntity map, bool alreadyMember})> joinFoodMapByInviteCode(
    String rawCode,
  ) => _dataSource.joinFoodMapByInviteCode(rawCode);

  @override
  Future<void> deleteFoodMap(String mapId) => _dataSource.deleteFoodMap(mapId);

  @override
  Future<void> leaveFoodMap(String mapId) => _dataSource.leaveFoodMap(mapId);

  @override
  Future<({bool added, FoodMapItemEntity item})> addRestaurant({
    required String mapId,
    required RestaurantEntity restaurant,
    String note = '',
  }) => _dataSource.addRestaurant(
    mapId: mapId,
    restaurant: restaurant,
    note: note,
  );

  @override
  Future<({int addedCount, int skippedCount})> importRestaurants({
    required String mapId,
    required List<RestaurantEntity> restaurants,
  }) => _dataSource.importRestaurants(mapId: mapId, restaurants: restaurants);

  @override
  Future<void> removeRestaurant({
    required String mapId,
    required String restaurantId,
  }) => _dataSource.removeRestaurant(mapId: mapId, restaurantId: restaurantId);

  @override
  Future<FoodMapItemEntity> updateItemNote({
    required String mapId,
    required String restaurantId,
    required String note,
  }) => _dataSource.updateItemNote(
    mapId: mapId,
    restaurantId: restaurantId,
    note: note,
  );

  @override
  Future<void> setVote({
    required String mapId,
    required String restaurantId,
    required FoodMapVote vote,
  }) =>
      _dataSource.setVote(mapId: mapId, restaurantId: restaurantId, vote: vote);
}
