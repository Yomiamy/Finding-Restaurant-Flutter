import '../entities/restaurant_detail_entity.dart';
import '../entities/restaurant_entity.dart';
import '../entities/review_entity.dart';

abstract interface class RestaurantDetailRepository {
  Future<RestaurantDetailEntity> fetchYelpRestaurantDetailInfo(String id);

  Future<ReviewEntity> fetchYelpRestaurantReviewInfo(String id);

  /// Returns the persisted entity so callers adopt the new favor value
  /// instead of deriving it a second time.
  Future<RestaurantEntity> toggleFavor(RestaurantEntity summaryInfo);
}
