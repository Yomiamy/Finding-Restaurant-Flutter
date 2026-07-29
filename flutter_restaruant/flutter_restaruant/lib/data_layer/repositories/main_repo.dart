import 'dart:async';

import 'package:get_it/get_it.dart';
import '../../api/api_clz.dart';
import '../datasources/favor_data_source.dart';
import '../dto/yelp_search_dto.dart';
import '../../domain/entities/restaurant_entity.dart';
import '../../domain/repositories/main_repository.dart';
import '../../model/filter_configs.dart';
import '../../utils/constants.dart';

class MainRepo implements MainRepository {
  static const int _maxItemsCountInList = 50;

  final FavorDataSource _favorDataSource;

  @override
  Set<RestaurantEntity> summaryInfoSet = {};
  int _offset = 0;
  String _keyword = '';
  bool _isLoading = false;

  MainRepo({FavorDataSource? favorDataSource})
      : _favorDataSource = favorDataSource ?? FavorDataSource() {
    reset();
  }

  @override
  void reset() {
    _offset = 0;
    _keyword = '';
    _isLoading = false;

    summaryInfoSet.clear();
  }

  @override
  Future<List<RestaurantEntity>> fetchYelpSearchInfo(double lat,
      double lng, int? price, int? openAt, String? sortByStr) async {
    if (_isLoading) {
      // If new items is loading, then don't handle new fetching request until the old one completed.
      return await filterByKeyword(_keyword, sortByStr);
    }

    _isLoading = true;
    try {
      YelpSearchDto searchDto = await GetIt.I<APIClz>().businessesSearch(
          term: 'Restaurants',
          latitude: lat,
          longitude: lng,
          locale: Constants.locale,
          price: price,
          openAt: openAt,
          sortBy: sortByStr,
          limit: MainRepo._maxItemsCountInList,
          offset: _offset);

      Map<String, dynamic> favorsMap = await _favorDataSource.fetchFavorsMap();

      List<RestaurantEntity> fetchedEntities = (searchDto.businesses ?? [])
          .map((dto) {
            bool isFavor = favorsMap.containsKey(dto.id);
            return RestaurantEntity.fromDto(dto).copyWith(favor: isFavor);
          })
          .toList();


      summaryInfoSet.addAll(fetchedEntities);

      _offset += MainRepo._maxItemsCountInList;

      return await filterByKeyword(_keyword, sortByStr);
    } on Exception catch (e, st) {
      logger.e('fetchYelpSearchInfo 發生異常', error: e, stackTrace: st);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  @override
  Future<List<RestaurantEntity>> filterByKeyword(
      String keyword, String? sortByStr) async {
    _keyword = keyword;

    if (keyword.isNotEmpty) {
      List<RestaurantEntity> filteredList =
          summaryInfoSet.where((element) {
        return (element.name?.contains(keyword) ?? false) ||
            (element.categoriesStr.contains(keyword)) ||
            (element.location?.displayAddressStr.contains(keyword) ?? false);
      }).toList();

      return _getSortedInfoList(sortByStr, filteredList);
    } else {
      return _getSortedInfoList(sortByStr, summaryInfoSet.toList());
    }
  }

  List<RestaurantEntity> _getSortedInfoList(
      String? sortByStr, List<RestaurantEntity> summaryInfos) {
    sortByStr = sortByStr ?? SortBy.bestMatch.toShortString();
    SortBy sortBy = SortBy.values
        .firstWhere((element) => element.toShortString() == sortByStr);

    summaryInfos.sort((info1, info2) {
      switch (sortBy) {
        case SortBy.distance:
          double dist1 = info1.distance ?? 0;
          double dist2 = info2.distance ?? 0;

          return dist1.compareTo(dist2);
        case SortBy.reviewCount:
          int reviewCount1 = info1.reviewCount ?? 0;
          int reviewCount2 = info2.reviewCount ?? 0;

          return reviewCount2.compareTo(reviewCount1);
        case SortBy.rating:
          double rating1 = info1.rating ?? 0;
          double rating2 = info2.rating ?? 0;

          return rating2.compareTo(rating1);
        default:
          return 0;
      }
    });

    return summaryInfos;
  }

  @override
  Future<RestaurantEntity> toggleFavor(RestaurantEntity summaryInfo) async {
    RestaurantEntity updatedEntity =
        await _favorDataSource.toggleFavor(summaryInfo);

    // Update in summaryInfoSet
    summaryInfoSet.remove(summaryInfo);
    summaryInfoSet.add(updatedEntity);

    return updatedEntity;
  }
}
