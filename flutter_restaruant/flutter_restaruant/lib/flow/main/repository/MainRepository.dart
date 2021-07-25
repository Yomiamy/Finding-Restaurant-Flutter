import 'package:flutter_restaruant/api/APIClz.dart';
import 'package:flutter_restaruant/model/YelpSearchInfo.dart';
import 'package:flutter_restaruant/utils/Constants.dart';

class MainRepository {
  Future<YelpSearchInfo> fetchYelpSearchInfo(double lat, double lng, int? price, int? openAt, String? sortBy) async => apiInstance.businessesSearch(
      term: "Restaurants",
      latitude: lat,
      longitude: lng,
      locale: Constants.LOCALE,
      price: price,
      openAt: openAt,
      sortBy: sortBy,
      limit: 50);
}
