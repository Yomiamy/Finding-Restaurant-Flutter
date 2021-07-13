import 'package:flutter_restaruant/api/APIClz.dart';
import 'package:flutter_restaruant/model/YelpRestaurantDetailInfo.dart';
import 'package:flutter_restaruant/model/YelpReviewInfo.dart';
import 'package:flutter_restaruant/utils/Constants.dart';

class RestaurantDetailRepository {
  Future<YelpRestaurantDetailInfo> fetchYelpRestaurantDetailInfo(String id) async => apiInstance.business(
      id,
      Constants.LOCALE
  );

  Future<YelpReviewInfo> fetchYelpRestaurantReviewInfo(String id) async => apiInstance.review(
      id,
      Constants.LOCALE
  );
}