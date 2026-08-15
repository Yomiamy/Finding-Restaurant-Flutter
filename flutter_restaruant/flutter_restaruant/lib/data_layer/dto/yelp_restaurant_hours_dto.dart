import 'package:json_annotation/json_annotation.dart';
import 'yelp_restaurant_business_time_dto.dart';

part 'yelp_restaurant_hours_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class YelpRestaurantHoursDto {
  bool? isOpenNow;
  String? hoursType;
  List<YelpRestaurantBusinessTimeDto>? open;

  YelpRestaurantHoursDto({this.isOpenNow, this.hoursType, this.open});

  factory YelpRestaurantHoursDto.fromJson(Map<String, dynamic> json) =>
      _$YelpRestaurantHoursDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpRestaurantHoursDtoToJson(this);
}
