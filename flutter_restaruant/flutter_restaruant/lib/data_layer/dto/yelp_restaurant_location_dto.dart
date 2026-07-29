import 'package:json_annotation/json_annotation.dart';

part 'yelp_restaurant_location_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class YelpRestaurantLocationDto {
  String? address1;
  String? address2;
  String? address3;
  String? city;
  String? country;
  String? state;
  List<String>? displayAddress;

  YelpRestaurantLocationDto({
    this.address1,
    this.address2,
    this.address3,
    this.city,
    this.country,
    this.state,
    this.displayAddress,
  });

  factory YelpRestaurantLocationDto.fromJson(Map<String, dynamic> json) =>
      _$YelpRestaurantLocationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpRestaurantLocationDtoToJson(this);
}

