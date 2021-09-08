import 'package:flutter_restaruant/api/APIClz.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/model/YelpSearchInfo.dart';
import 'package:flutter_restaruant/utils/Constants.dart';

class MainRepository {

  static const int _MAX_ITEMS_COUNT_IN_LIST = 50;

  late int _offset;
  late List<YelpRestaurantSummaryInfo> summaryInfos;

  MainRepository() {
    this.resetOffset();
  }

  void resetOffset() {
    this._offset = 0;
    this.summaryInfos = [];
  }

  Future<List<YelpRestaurantSummaryInfo>> fetchYelpSearchInfo(double lat, double lng, int? price, int? openAt, String? sortBy) async {
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

    return this.summaryInfos;
  }
}
