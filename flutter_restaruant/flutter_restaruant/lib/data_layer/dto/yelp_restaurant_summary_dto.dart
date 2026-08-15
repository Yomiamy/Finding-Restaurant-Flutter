import 'package:json_annotation/json_annotation.dart';
import 'yelp_restaurant_category_dto.dart';
import 'yelp_restaurant_coordinates_dto.dart';
import 'yelp_restaurant_location_dto.dart';

part 'yelp_restaurant_summary_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class YelpRestaurantSummaryDto {
  String? id;
  String? name;
  String? imageUrl;
  int? reviewCount;
  double? rating;
  String? price;
  String? phone;
  double? distance;
  List<YelpRestaurantCategoryDto>? categories;
  YelpRestaurantLocationDto? location;
  YelpRestaurantCoordinatesDto? coordinates;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool favor = false;

  YelpRestaurantSummaryDto({
    this.id,
    this.name,
    this.imageUrl,
    this.reviewCount,
    this.rating,
    this.price,
    this.phone,
    this.distance,
    this.categories,
    this.location,
    this.coordinates,
    this.favor = false,
  });

  factory YelpRestaurantSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$YelpRestaurantSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpRestaurantSummaryDtoToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! YelpRestaurantSummaryDto) return false;
    return id != null && id == other.id;
  }

  @override
  int get hashCode => id?.hashCode ?? 0;
}
