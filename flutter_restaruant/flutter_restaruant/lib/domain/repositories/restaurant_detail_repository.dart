import '../entities/restaurant_detail_entity.dart';
import '../entities/restaurant_entity.dart';
import '../entities/review_entity.dart';

abstract interface class RestaurantDetailRepository {
  Future<RestaurantDetailEntity> fetchYelpRestaurantDetailInfo(String id);

  Future<ReviewEntity> fetchYelpRestaurantReviewInfo(String id);

  Future<void> toggleFavor(RestaurantEntity summaryInfo);
}
