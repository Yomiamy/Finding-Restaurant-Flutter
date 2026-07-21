import 'package:json_annotation/json_annotation.dart';

import 'yelp_base_info.dart';
import 'yelp_restaurant_category.dart';
import 'yelp_restaurant_coordinates.dart';
import 'yelp_restaurant_location.dart';

part 'yelp_restaurant_summary_info.g.dart';

@JsonSerializable()
class YelpRestaurantSummaryInfo extends YelpBaseInfo {
  String? id;
  String? name;
  String? image_url;
  int? review_count;
  double? rating;
  String? price;
  String? phone;
  double? distance;
  List<YelpRestaurantCategory>? categories;
  @JsonKey(ignore: true)
  String get categoriesStr =>
      categories?.map((category) => category.title ?? "").join(" ") ?? "";
  YelpRestaurantLocation? location;
  YelpRestaurantCoordinates? coordinates;
  @JsonKey(ignore: true)
  bool favor = false;

  YelpRestaurantSummaryInfo() : super();

  factory YelpRestaurantSummaryInfo.fromJson(Map<String, dynamic> json) =>
      _$YelpRestaurantSummaryInfoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpRestaurantSummaryInfoToJson(this);

  @override
  int get hashCode => this.id.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! YelpRestaurantSummaryInfo) return false;

    return this.id!.compareTo(other.id!) == 0;
  }
}
