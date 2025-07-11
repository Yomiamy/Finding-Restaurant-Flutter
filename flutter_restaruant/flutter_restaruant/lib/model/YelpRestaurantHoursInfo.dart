import 'package:json_annotation/json_annotation.dart';
import 'YelpResaruantBusinessTime.dart';

part 'YelpRestaurantHoursInfo.g.dart';

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
