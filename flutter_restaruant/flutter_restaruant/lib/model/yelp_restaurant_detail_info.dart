import 'package:flutter_restaruant/model/yelp_base_info.dart';
import 'package:json_annotation/json_annotation.dart';
import 'yelp_restaurant_category.dart';
import 'yelp_restaurant_coordinates.dart';
import 'yelp_restaurant_hours_info.dart';
import 'yelp_restaurant_location.dart';

part 'yelp_restaurant_detail_info.g.dart';

@JsonSerializable()
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

  YelpRestaurantDetailInfo();

  factory YelpRestaurantDetailInfo.fromJson(Map<String, dynamic> json) =>
      _$YelpRestaurantDetailInfoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpRestaurantDetailInfoToJson(this);
}
