import 'package:json_annotation/json_annotation.dart';

part 'YelpRestaurantCategory.g.dart';

@JsonSerializable()
class YelpRestaurantCategory {
  String? alias;
  String? title;

  YelpRestaurantCategory() : super();

  factory YelpRestaurantCategory.fromJson(Map<String, dynamic> json) =>
      _$YelpRestaurantCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$YelpRestaurantCategoryToJson(this);
}
