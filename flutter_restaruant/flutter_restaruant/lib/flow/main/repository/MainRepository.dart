import 'package:flutter_restaruant/api/APIClz.dart';
import 'package:flutter_restaruant/model/FilterConfigs.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/model/YelpSearchInfo.dart';
import 'package:flutter_restaruant/utils/Constants.dart';

class MainRepository {

  static const int _MAX_ITEMS_COUNT_IN_LIST = 50;

  List<YelpRestaurantSummaryInfo> summaryInfos = [];
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

    this.summaryInfos.clear();
  }

  Future<List<YelpRestaurantSummaryInfo>> fetchYelpSearchInfo(double lat, double lng, int? price, int? openAt, String? sortByStr) async {
    if(this._isLoading) {
      // If new items is loading, then don't handle new fetching request until the old one completed.
      return (this._keyword.isEmpty) ? this.summaryInfos : await this.filterByKeyword(this._keyword);
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

    SortBy sortBy = SortBy.values.firstWhere((element) => element.toShortString() == sortByStr);
    this.summaryInfos.addAll(searchInfo.businesses ?? []);
    this.summaryInfos.sort((info1, info2) {
      switch(sortBy) {
        case SortBy.distance:
          double dist1 = info1.distance ?? 0;
          double dist2 = info2.distance ?? 0;

          return dist1.compareTo(dist2);
        case SortBy.review_count:
          int reviewCount1 = info1.review_count ?? 0;
          int reviewCount2 = info2.review_count ?? 0;

          return reviewCount1.compareTo(reviewCount2);
        case SortBy.rating:
          double rating1 = info1.rating ?? 0;
          double rating2 = info2.rating ?? 0;

          return rating1.compareTo(rating2);
      }
      return 0;
    });

    return (this._keyword.isEmpty) ? this.summaryInfos : await this.filterByKeyword(this._keyword);
  }

  Future<List<YelpRestaurantSummaryInfo>> filterByKeyword(String keyword) async {
    this._keyword = keyword;

    if(keyword.isNotEmpty) {
      return this.summaryInfos.where((element) {
        return (element.name?.contains(keyword) ?? false)
            || (element.categoriesStr.contains(keyword))
            || (element.location?.displayAddressStr.contains(keyword) ?? false);
      }).toList();
    } else {
      return this.summaryInfos;
    }
  }

}
