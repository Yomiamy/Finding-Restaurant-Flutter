import 'dart:async';

import '../datasources/favor_data_source.dart';
import '../../domain/entities/restaurant_entity.dart';
import '../../domain/repositories/favor_repository.dart';

class FavorRepo implements FavorRepository {
  final FavorDataSource _dataSource;

  List<RestaurantEntity> _favorInfos = [];

  FavorRepo({FavorDataSource? favorDataSource})
      : _dataSource = favorDataSource ?? FavorDataSource();

  @override
  Future<List<RestaurantEntity>> fetchFavorInfos(
      bool isRefreshLocalOnly) async {
    if (isRefreshLocalOnly) {
      _favorInfos = _favorInfos.where((element) => element.favor).toList();
    } else {
      _favorInfos = await _dataSource.fetchFavorEntities();
    }

    return _favorInfos;
  }

  @override
  Future<RestaurantEntity> toggleFavor(RestaurantEntity summaryInfo) async {
    RestaurantEntity updatedEntity =
        await _dataSource.toggleFavor(summaryInfo);

    // 同步本地快取，否則 fetchFavorInfos(true) 濾不掉剛取消收藏的項目
    _favorInfos = [
      ..._favorInfos.where((element) => element.id != updatedEntity.id),
      if (updatedEntity.favor) updatedEntity,
    ];

    return updatedEntity;
  }
}
