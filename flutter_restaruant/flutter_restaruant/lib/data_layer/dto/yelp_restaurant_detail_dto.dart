import 'package:json_annotation/json_annotation.dart';
import 'yelp_restaurant_category_dto.dart';
import 'yelp_restaurant_coordinates_dto.dart';
import 'yelp_restaurant_hours_dto.dart';
import 'yelp_restaurant_location_dto.dart';

part 'yelp_restaurant_detail_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class YelpRestaurantDetailDto {
  String? name;
  String? imageUrl;
  bool? isClosed;
  int? reviewCount;
  double? rating;
  String? phone;
  List<YelpRestaurantCategoryDto>? categories;
  YelpRestaurantLocationDto? location;
  YelpRestaurantCoordinatesDto? coordinates;
  List<String>? photos;
  List<YelpRestaurantHoursDto>? hours;

  YelpRestaurantDetailDto({
    this.name,
    this.imageUrl,
    this.isClosed,
    this.reviewCount,
    this.rating,
    this.phone,
    this.categories,
    this.location,
    this.coordinates,
    this.photos,
    this.hours,
  });

  factory YelpRestaurantDetailDto.fromJson(Map<String, dynamic> json) =>
      _$YelpRestaurantDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpRestaurantDetailDtoToJson(this);
}
