import 'package:flutter_restaruant/model/yelp_base_info.dart';
import 'package:json_annotation/json_annotation.dart';
import 'yelp_restaurant_summary_info.dart';

part 'yelp_search_info.g.dart';

@JsonSerializable()
class YelpSearchInfo extends YelpBaseInfo {
  List<YelpRestaurantSummaryInfo>? businesses;
  int? total;

  YelpSearchInfo() : super();

  factory YelpSearchInfo.fromJson(Map<String, dynamic> json) =>
      _$YelpSearchInfoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpSearchInfoToJson(this);
}
