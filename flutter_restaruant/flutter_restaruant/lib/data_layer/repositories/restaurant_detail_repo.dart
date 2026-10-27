import 'dart:async';

import '../../api/api_barrel.dart';
import '../../domain/entities/entities_barrel.dart';
import '../../domain/repositories/repositories_barrel.dart';
import '../datasources/datasources_barrel.dart';

class RestaurantDetailRepo implements RestaurantDetailRepository {
  final APIClz _api;
  final String _locale;
  final FavorDataSource _favorDataSource;

  RestaurantDetailRepo({
    required APIClz api,
    required String locale,
    FavorDataSource? favorDataSource,
  }) : _api = api,
       _locale = locale,
       _favorDataSource = favorDataSource ?? FavorDataSource();

  @override
  Future<RestaurantDetailEntity> fetchYelpRestaurantDetailInfo(
    String id,
  ) async {
    YelpRestaurantDetailDto detailDto = await _api.business(id, _locale);
    return RestaurantDetailEntity.fromDto(detailDto);
  }

  @override
  Future<ReviewEntity> fetchYelpRestaurantReviewInfo(String id) async {
    YelpReviewDto reviewDto = await _api.review(id, _locale);
    return ReviewEntity.fromDto(reviewDto);
  }

  @override
  Future<RestaurantEntity> toggleFavor(RestaurantEntity summaryInfo) =>
      _favorDataSource.toggleFavor(summaryInfo);
}
