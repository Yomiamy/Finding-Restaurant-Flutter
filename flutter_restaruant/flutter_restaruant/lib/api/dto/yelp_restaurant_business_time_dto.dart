import 'package:json_annotation/json_annotation.dart';

part 'yelp_restaurant_business_time_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class YelpRestaurantBusinessTimeDto {
  bool? isOvernight;
  String? start;
  String? end;
  int? day;

  YelpRestaurantBusinessTimeDto({
    this.isOvernight,
    this.start,
    this.end,
    this.day,
  });

  factory YelpRestaurantBusinessTimeDto.fromJson(Map<String, dynamic> json) =>
      _$YelpRestaurantBusinessTimeDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpRestaurantBusinessTimeDtoToJson(this);
}
