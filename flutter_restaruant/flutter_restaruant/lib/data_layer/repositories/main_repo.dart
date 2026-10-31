import 'dart:async';

import '../../api/api_barrel.dart';
import '../../domain/entities/entities_barrel.dart';
import '../../domain/repositories/repositories_barrel.dart';
import '../../models/model_barrel.dart';
import '../datasources/datasources_barrel.dart';

class MainRepo implements MainRepository {
  static const int _maxItemsCountInList = 50;

  final APIClz _api;
  final String _locale;
  final FavorDataSource _favorDataSource;

  @override
  Set<RestaurantEntity> summaryInfoSet = {};
  int _offset = 0;
  String _keyword = '';
  bool _isLoading = false;
  int _activeRequestId = 0;

  MainRepo({
    required APIClz api,
    required String locale,
    FavorDataSource? favorDataSource,
  }) : _api = api,
       _locale = locale,
       _favorDataSource = favorDataSource ?? FavorDataSource() {
    reset();
  }

  @override
  void reset() {
    _activeRequestId++;
    _offset = 0;
    _keyword = '';
    _isLoading = false;

    summaryInfoSet.clear();
  }

  @override
  Future<List<RestaurantEntity>> fetchYelpSearchInfo({
    double? lat,
    double? lng,
    String? location,
    String? price,
    int? openAt,
    String? sortByStr,
    String? term,
    String? categories,
    int? radius,
    bool? openNow,
  }) async {
    final bool isNewSearch = term != null;
    if (isNewSearch) {
      _offset = 0;
      _keyword = term.trim();
      summaryInfoSet.clear();
    } else if (_isLoading) {
      // If new items is loading, then don't handle new fetching request until the old one completed.
      return _getSortedInfoList(sortByStr, summaryInfoSet.toList());
    }

    // Yelp Fusion API: offset + limit <= 1000. 超出時 Yelp 回傳 400 Bad Request。
    // 當 offset 達到 1000 時主動停發，直接返回既有資料，消滅 400 崩潰邊界。
    if (_offset >= 1000) {
      return _getSortedInfoList(sortByStr, summaryInfoSet.toList());
    }

    final int currentRequestId = ++_activeRequestId;
    _isLoading = true;
    try {
      final String queryTerm = _keyword.isNotEmpty ? _keyword : 'Restaurants';

      final bool hasCoordinates = lat != null && lng != null;
      final String? resolvedLocation = hasCoordinates
          ? null
          : (location != null && location.isNotEmpty ? location : 'Taipei');

      YelpSearchDto searchDto = await _api.businessesSearch(
        term: queryTerm,
        latitude: hasCoordinates ? lat : null,
        longitude: hasCoordinates ? lng : null,
        location: resolvedLocation,
        locale: _locale,
        price: price,
        openAt: openAt,
        sortBy: sortByStr,
        categories: categories,
        radius: radius,
        openNow: openNow,
        limit: MainRepo._maxItemsCountInList,
        offset: _offset,
      );

      if (currentRequestId != _activeRequestId) {
        return _getSortedInfoList(sortByStr, summaryInfoSet.toList());
      }

      Set<String> favorIds = await _favorDataSource.fetchFavorIds();

      if (currentRequestId != _activeRequestId) {
        return _getSortedInfoList(sortByStr, summaryInfoSet.toList());
      }

      List<RestaurantEntity> fetchedEntities = (searchDto.businesses ?? []).map(
        (dto) {
          bool isFavor = favorIds.contains(dto.id);
          return RestaurantEntity.fromDto(dto).copyWith(favor: isFavor);
        },
      ).toList();

      summaryInfoSet.addAll(fetchedEntities);

      _offset += MainRepo._maxItemsCountInList;

      return _getSortedInfoList(sortByStr, summaryInfoSet.toList());
    } on Exception catch (e, st) {
      logger.e('fetchYelpSearchInfo 發生異常', error: e, stackTrace: st);
      rethrow;
    } finally {
      if (currentRequestId == _activeRequestId) {
        _isLoading = false;
      }
    }
  }

  List<RestaurantEntity> _getSortedInfoList(
    String? sortByStr,
    List<RestaurantEntity> summaryInfos,
  ) {
    sortByStr = sortByStr ?? SortBy.bestMatch.toShortString();
    SortBy sortBy = SortBy.values.firstWhere(
      (element) => element.toShortString() == sortByStr,
    );

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
    RestaurantEntity updatedEntity = await _favorDataSource.toggleFavor(
      summaryInfo,
    );

    // Update in summaryInfoSet
    summaryInfoSet.remove(summaryInfo);
    summaryInfoSet.add(updatedEntity);

    return updatedEntity;
  }
}
