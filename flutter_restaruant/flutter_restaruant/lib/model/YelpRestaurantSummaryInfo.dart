import 'package:json_annotation/json_annotation.dart';

import 'YelpBaseInfo.dart';
import 'YelpRestaurantCategory.dart';
import 'YelpRestaurantCoordinates.dart';
import 'YelpRestaurantLocation.dart';

part 'YelpRestaurantSummaryInfo.g.dart';

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
  String? categoriesStr;
  YelpRestaurantLocation? location;
  YelpRestaurantCoordinates? coordinates;

  YelpRestaurantSummaryInfo():super();

  factory YelpRestaurantSummaryInfo.fromJson(Map<String, dynamic> json) =>
      _$YelpRestaurantSummaryInfoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpRestaurantSummaryInfoToJson(this);
}
