import 'package:flutter_restaruant/api/APIClz.dart';
import 'package:flutter_restaruant/model/YelpRestaurantDetailInfo.dart';
import 'package:flutter_restaruant/utils/Constants.dart';

class RestaurantDetailRepository {
  Future<YelpRestaurantDetailInfo> fetchYelpRestaurantDetailInfo(String id) => apiInstance.business(
      id,
      Constants.LOCALE
  );
}