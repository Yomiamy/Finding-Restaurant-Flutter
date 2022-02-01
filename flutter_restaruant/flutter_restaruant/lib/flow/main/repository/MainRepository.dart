import 'package:flutter_restaruant/api/APIClz.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/model/YelpSearchInfo.dart';
import 'package:flutter_restaruant/utils/Constants.dart';

class MainRepository {

  static const int _MAX_ITEMS_COUNT_IN_LIST = 50;

  late int _offset;
  late List<YelpRestaurantSummaryInfo> summaryInfos;
  String _keyword = "";
  bool _isLoading = false;

  MainRepository() {
    this.resetOffset();
  }

  void resetOffset() {
    this._offset = 0;
    this.summaryInfos = [];
    this._keyword = "";
  }

  Future<List<YelpRestaurantSummaryInfo>> fetchYelpSearchInfo(double lat, double lng, int? price, int? openAt, String? sortBy) async {
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
        sortBy: sortBy,
        limit: MainRepository._MAX_ITEMS_COUNT_IN_LIST,
        offset: ++this._offset);

    this.summaryInfos.addAll(searchInfo.businesses ?? []);
    this._isLoading = false;

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
