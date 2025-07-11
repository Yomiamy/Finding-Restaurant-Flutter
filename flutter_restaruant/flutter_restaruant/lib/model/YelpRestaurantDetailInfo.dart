import 'package:flutter_restaruant/model/YelpBaseInfo.dart';
import 'package:json_annotation/json_annotation.dart';
import 'YelpRestaurantCategory.dart';
import 'YelpRestaurantCoordinates.dart';
import 'YelpRestaurantHoursInfo.dart';
import 'YelpRestaurantLocation.dart';

part 'YelpRestaurantDetailInfo.g.dart';

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
