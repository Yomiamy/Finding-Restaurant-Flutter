import 'dart:async';

import 'package:get_it/get_it.dart';
import '../../api/api_barrel.dart';
import '../datasources/datasources_barrel.dart';
import '../dto/dto_barrel.dart';
import '../../domain/entities/entities_barrel.dart';
import '../../domain/repositories/repositories_barrel.dart';
import '../../features/foundation/constants/constants_barrel.dart';

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
