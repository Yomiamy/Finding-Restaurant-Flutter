import 'package:json_annotation/json_annotation.dart';
import 'yelp_resaruant_business_time.dart';

part 'yelp_restaurant_hours_info.g.dart';

@JsonSerializable()
class YelpRestaurantHoursInfo {
  bool? is_open_now;
  String? hours_type;
  List<YelpResaruantBusinessTime>? open;

  YelpRestaurantHoursInfo();

  factory YelpRestaurantHoursInfo.fromJson(Map<String, dynamic> json) =>
      _$YelpRestaurantHoursInfoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpRestaurantHoursInfoToJson(this);
}
