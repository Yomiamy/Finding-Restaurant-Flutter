import 'package:flutter_restaruant/api/APIClz.dart';
import 'package:flutter_restaruant/model/FilterConfigs.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/model/YelpSearchInfo.dart';
import 'package:flutter_restaruant/utils/Constants.dart';

class MainRepository {

  static const int _MAX_ITEMS_COUNT_IN_LIST = 50;

  Set<YelpRestaurantSummaryInfo> summaryInfoSet = Set();
  int _offset = 0;
  String _keyword = "";
  bool _isLoading = false;

  MainRepository() {
    this.reset();
  }

  void reset() {
    this._offset = 0;
    this._keyword = "";
    this._isLoading = false;

    this.summaryInfoSet.clear();
  }

  Future<List<YelpRestaurantSummaryInfo>> fetchYelpSearchInfo(double lat, double lng, int? price, int? openAt, String? sortByStr) async {
    if(this._isLoading) {
      // If new items is loading, then don't handle new fetching request until the old one completed.
      return await this.filterByKeyword(this._keyword, sortByStr);
    }

    this._isLoading = true;
    YelpSearchInfo searchInfo = await apiInstance.businessesSearch(
        term: "Restaurants",
        latitude: lat,
        longitude: lng,
        locale: Constants.LOCALE,
        price: price,
        openAt: openAt,
        sortBy: sortByStr,
        limit: MainRepository._MAX_ITEMS_COUNT_IN_LIST,
        offset: ++this._offset);
    this._isLoading = false;
    this.summaryInfoSet.addAll(searchInfo.businesses ?? []);

    return await this.filterByKeyword(this._keyword, sortByStr);
  }

  Future<List<YelpRestaurantSummaryInfo>> filterByKeyword(String keyword, String? sortByStr) async {
    this._keyword = keyword;

    if(keyword.isNotEmpty) {
      List<YelpRestaurantSummaryInfo> filteredList = this.summaryInfoSet.where((element) {
        return (element.name?.contains(keyword) ?? false)
            || (element.categoriesStr.contains(keyword))
            || (element.location?.displayAddressStr.contains(keyword) ?? false);
      }).toList();

      return this._getSortedInfoList(sortByStr, filteredList);
    } else {
      return this._getSortedInfoList(sortByStr, this.summaryInfoSet.toList());
    }
  }

  List<YelpRestaurantSummaryInfo> _getSortedInfoList(String? sortByStr, List<YelpRestaurantSummaryInfo> summaryInfos) {
    sortByStr = sortByStr ?? SortBy.best_match.toShortString();
    SortBy sortBy = SortBy.values.firstWhere((element) => element.toShortString() == sortByStr);

    summaryInfos.sort((info1, info2) {
      switch(sortBy) {
        case SortBy.distance:
          double dist1 = info1.distance ?? 0;
          double dist2 = info2.distance ?? 0;

          return dist1.compareTo(dist2);
        case SortBy.review_count:
          int reviewCount1 = info1.review_count ?? 0;
          int reviewCount2 = info2.review_count ?? 0;

          return reviewCount2.compareTo(reviewCount1);
        case SortBy.rating:
          double rating1 = info1.rating ?? 0;
          double rating2 = info2.rating ?? 0;

          return rating2.compareTo(rating1);
      }
      return 0;
    });

    return summaryInfos;
  }
}
