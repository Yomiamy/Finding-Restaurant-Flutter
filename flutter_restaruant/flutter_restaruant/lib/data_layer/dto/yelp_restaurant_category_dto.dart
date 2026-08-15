import 'package:json_annotation/json_annotation.dart';

part 'yelp_restaurant_category_dto.g.dart';

@JsonSerializable()
class YelpRestaurantCategoryDto {
  String? alias;
  String? title;

  YelpRestaurantCategoryDto({this.alias, this.title});

  factory YelpRestaurantCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$YelpRestaurantCategoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpRestaurantCategoryDtoToJson(this);
}
