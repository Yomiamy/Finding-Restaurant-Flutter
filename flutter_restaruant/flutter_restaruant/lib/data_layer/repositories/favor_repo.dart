import 'dart:async';

import '../../domain/entities/entities_barrel.dart';
import '../../domain/repositories/repositories_barrel.dart';
import '../datasources/datasources_barrel.dart';

class FavorRepo implements FavorRepository {
  final FavorDataSource _dataSource;

  List<RestaurantEntity> _favorInfos = [];

  FavorRepo({FavorDataSource? favorDataSource})
    : _dataSource = favorDataSource ?? FavorDataSource();

  @override
  Future<List<RestaurantEntity>> fetchFavorInfos() async {
    _favorInfos = await _dataSource.fetchFavorEntities();

    return _favorInfos;
  }

  @override
  Future<RestaurantEntity> toggleFavor(RestaurantEntity summaryInfo) async {
    RestaurantEntity updatedEntity = await _dataSource.toggleFavor(summaryInfo);

    // 同步本地快取，否則 fetchFavorInfos(true) 濾不掉剛取消收藏的項目
    _favorInfos = [
      ..._favorInfos.where((element) => element.id != updatedEntity.id),
      if (updatedEntity.favor) updatedEntity,
    ];

    return updatedEntity;
  }
}
