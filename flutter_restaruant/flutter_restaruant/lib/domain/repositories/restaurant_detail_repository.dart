import '../entities/entities_barrel.dart';

abstract interface class RestaurantDetailRepository {
  Future<RestaurantDetailEntity> fetchYelpRestaurantDetailInfo(String id);

  Future<ReviewEntity> fetchYelpRestaurantReviewInfo(String id);

  /// Returns the persisted entity so callers adopt the new favor value
  /// instead of deriving it a second time.
  Future<RestaurantEntity> toggleFavor(RestaurantEntity summaryInfo);
}
