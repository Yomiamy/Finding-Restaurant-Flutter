import 'package:json_annotation/json_annotation.dart';
import 'yelp_restaurant_summary_dto.dart';

part 'yelp_search_dto.g.dart';

@JsonSerializable()
class YelpSearchDto {
  List<YelpRestaurantSummaryDto>? businesses;
  int? total;

  YelpSearchDto({this.businesses, this.total});

  factory YelpSearchDto.fromJson(Map<String, dynamic> json) =>
      _$YelpSearchDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpSearchDtoToJson(this);
}
