import 'package:flutter_restaruant/api/APIClz.dart';
import 'package:flutter_restaruant/model/YelpSearchInfo.dart';
import 'package:flutter_restaruant/utils/Constants.dart';

class MainRepository {

  static const int _MAX_ITEMS_COUNT_IN_LIST = 50;

  late int _offset;

  MainRepository() {}

  void resetOffset() {
    this._offset = 0;
  }

  Future<YelpSearchInfo> fetchYelpSearchInfo(double lat, double lng, int? price,
      int? openAt, String? sortBy) async {
    this._offset++;

    return apiInstance.businessesSearch(
        term: "Restaurants",
        latitude: lat,
        longitude: lng,
        locale: Constants.LOCALE,
        price: price,
        openAt: openAt,
        sortBy: sortBy,
        limit: MainRepository._MAX_ITEMS_COUNT_IN_LIST,
        offset: this._offset);
  }
}
