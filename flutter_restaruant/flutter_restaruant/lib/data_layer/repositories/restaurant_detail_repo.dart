import 'dart:async';

import 'package:get_it/get_it.dart';
import '../../api/api_clz.dart';
import '../datasources/favor_data_source.dart';
import '../dto/yelp_restaurant_detail_dto.dart';
import '../dto/yelp_review_dto.dart';
import '../../domain/entities/restaurant_detail_entity.dart';
import '../../domain/entities/restaurant_entity.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/restaurant_detail_repository.dart';
import '../../features/foundation/constants/app_constants.dart';

class RestaurantDetailRepo implements RestaurantDetailRepository {
  final FavorDataSource _favorDataSource;

  RestaurantDetailRepo({FavorDataSource? favorDataSource})
      : _favorDataSource = favorDataSource ?? FavorDataSource();

  @override
  Future<RestaurantDetailEntity> fetchYelpRestaurantDetailInfo(
      String id) async {
    YelpRestaurantDetailDto detailDto =
        await GetIt.I<APIClz>().business(id, Constants.locale);
    return RestaurantDetailEntity.fromDto(detailDto);
  }

  @override
  Future<ReviewEntity> fetchYelpRestaurantReviewInfo(String id) async {
    YelpReviewDto reviewDto =
        await GetIt.I<APIClz>().review(id, Constants.locale);
    return ReviewEntity.fromDto(reviewDto);
  }

  @override
  Future<RestaurantEntity> toggleFavor(RestaurantEntity summaryInfo) =>
      _favorDataSource.toggleFavor(summaryInfo);
}
