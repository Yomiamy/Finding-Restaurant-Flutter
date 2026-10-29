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
  String? id;
  String? alias;
  String? price;
  String? url;
  String? displayPhone;
  bool? isClaimed;
  List<String>? transactions;

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
    this.id,
    this.alias,
    this.price,
    this.url,
    this.displayPhone,
    this.isClaimed,
    this.transactions,
  });

  factory YelpRestaurantDetailDto.fromJson(Map<String, dynamic> json) =>
      _$YelpRestaurantDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpRestaurantDetailDtoToJson(this);
}
