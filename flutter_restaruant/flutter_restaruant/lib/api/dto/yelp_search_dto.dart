import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'yelp_restaurant_summary_dto.dart';

part 'yelp_search_dto.g.dart';

/// `/v3/businesses/search`、`/search/phone`、`/matches`、
/// `/transactions/{type}/search` 共用的回應；`/matches` 沒有 `total`，此時為 null。
///
/// [businesses] 的元素以 id 判斷相等（見 [YelpRestaurantSummaryDto]），
/// 同 id 但其他欄位不同的兩份結果會被視為相等。
@JsonSerializable(explicitToJson: true)
class YelpSearchDto extends Equatable {
  final List<YelpRestaurantSummaryDto>? businesses;
  final int? total;

  const YelpSearchDto({this.businesses, this.total});

  factory YelpSearchDto.fromJson(Map<String, dynamic> json) =>
      _$YelpSearchDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpSearchDtoToJson(this);

  @override
  List<Object?> get props => [businesses, total];
}
