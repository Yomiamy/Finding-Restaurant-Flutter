import 'package:flutter_restaruant/model/YelpBaseInfo.dart';
import 'package:json_annotation/json_annotation.dart';
import 'YelpRestaurantSummaryInfo.dart';

part 'YelpSearchInfo.g.dart';

@JsonSerializable()
class YelpSearchInfo extends YelpBaseInfo {
 List<YelpRestaurantSummaryInfo>? businesses;
 int? total;

 YelpSearchInfo():super();

 factory YelpSearchInfo.fromJson(Map<String, dynamic> json) =>
     _$YelpSearchInfoFromJson(json);

 Map<String, dynamic> toJson() => _$YelpSearchInfoToJson(this);
}