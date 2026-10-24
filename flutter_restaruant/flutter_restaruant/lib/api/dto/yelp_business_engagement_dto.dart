import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'yelp_engagement_metric_dto.dart';

part 'yelp_business_engagement_dto.g.dart';

@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  explicitToJson: true,
)
class YelpBusinessEngagementDto extends Equatable {
  final String? businessId;
  final List<YelpEngagementMetricDto>? metrics;

  const YelpBusinessEngagementDto({this.businessId, this.metrics});

  factory YelpBusinessEngagementDto.fromJson(Map<String, dynamic> json) =>
      _$YelpBusinessEngagementDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpBusinessEngagementDtoToJson(this);

  @override
  List<Object?> get props => [businessId, metrics];
}
