import 'package:json_annotation/json_annotation.dart';

part 'YelpRestaurantLocation.g.dart';

@JsonSerializable()
class YelpRestaurantLocation {
  String? address1;
  String? address2;
  String? address3;
  String? city;
  String? country;
  String? state;
  List<String>? display_address;

  YelpRestaurantLocation();

  factory YelpRestaurantLocation.fromJson(Map<String, dynamic> json) =>
      _$YelpRestaurantLocationFromJson(json);

  Map<String, dynamic> toJson() => _$YelpRestaurantLocationToJson(this);
}