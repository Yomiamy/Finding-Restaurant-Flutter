import 'package:flutter_restaruant/api/APIClz.dart';
import 'package:flutter_restaruant/model/YelpSearchInfo.dart';
import 'package:flutter_restaruant/utils/Constants.dart';

class MainRepository {
  // FIXME: Just for test
  Future<YelpSearchInfo> fetchYelpSearchInfo() => apiInstance.businessesSearch(
      term: "Restaurants",
      latitude: 25.047908,
      longitude: 121.517315,
      locale: Constants.LOCALE,
      limit: 50);
}
