
// var location:YelpRestaurantLocation?
// var coordinates:YelpRestaurantCoordinates?

// var hours:[YelpRestaurantHoursInfo]?
// }

import 'package:flutter_restaruant/model/YelpBaseInfo.dart';

import 'YelpRestaurantCategory.dart';
import 'YelpRestaurantCoordinates.dart';
import 'YelpRestaurantHoursInfo.dart';
import 'YelpRestaurantLocation.dart';

class YelpRestaurantDetailInfo extends YelpBaseInfo {
  String? name;
  String? image_url;
  bool? is_closed;
  int? review_count;
  double? rating;
  String? phone;
  List<YelpRestaurantCategory>? categories;
  YelpRestaurantLocation? location;
  YelpRestaurantCoordinates? coordinates;
  List<String>? photos;
  List<YelpRestaurantHoursInfo>? hours;


}