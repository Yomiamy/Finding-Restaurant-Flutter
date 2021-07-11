import 'package:flutter_restaruant/api/APIClz.dart';
import 'package:flutter_restaruant/model/YelpSearchInfo.dart';
import 'package:flutter_restaruant/utils/Constants.dart';

class MainRepository {
  // FIXME: Just for test
  Future<YelpSearchInfo> fetchYelpSearchInfo(double lat, double lng) => apiInstance.businessesSearch(
      term: "Restaurants",
      latitude: lat,
      longitude: lng,
      locale: Constants.LOCALE,
      limit: 50);
}
