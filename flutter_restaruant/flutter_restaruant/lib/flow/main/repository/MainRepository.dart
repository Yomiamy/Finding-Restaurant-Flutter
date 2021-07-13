import 'package:flutter_restaruant/api/APIClz.dart';
import 'package:flutter_restaruant/model/YelpSearchInfo.dart';
import 'package:flutter_restaruant/utils/Constants.dart';

class MainRepository {
  Future<YelpSearchInfo> fetchYelpSearchInfo(double lat, double lng) async => apiInstance.businessesSearch(
      term: "Restaurants",
      latitude: lat,
      longitude: lng,
      locale: Constants.LOCALE,
      limit: 50);
}
