import 'package:json_annotation/json_annotation.dart';

part 'yelp_restaurant_coordinates_dto.g.dart';

@JsonSerializable()
class YelpRestaurantCoordinatesDto {
  double? latitude;
  double? longitude;

  YelpRestaurantCoordinatesDto({this.latitude, this.longitude});

  factory YelpRestaurantCoordinatesDto.fromJson(Map<String, dynamic> json) =>
      _$YelpRestaurantCoordinatesDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpRestaurantCoordinatesDtoToJson(this);
}

