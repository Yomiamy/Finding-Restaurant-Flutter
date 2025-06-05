import 'package:json_annotation/json_annotation.dart';

part 'YelpRestaurantCoordinates.g.dart';

@JsonSerializable()
class YelpRestaurantCoordinates {
  double? latitude;
  double? longitude;

  YelpRestaurantCoordinates();

  factory YelpRestaurantCoordinates.fromJson(Map<String, dynamic> json) =>
      _$YelpRestaurantCoordinatesFromJson(json);

  Map<String, dynamic> toJson() => _$YelpRestaurantCoordinatesToJson(this);
}
