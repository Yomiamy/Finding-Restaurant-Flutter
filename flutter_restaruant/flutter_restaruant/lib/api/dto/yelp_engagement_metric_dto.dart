import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'yelp_engagement_metric_dto.g.dart';

@JsonSerializable(checked: true, fieldRename: FieldRename.snake)
class YelpEngagementMetricDto extends Equatable {
  final String? startOfWeekDate;
  final int? engagementMetric;
  final int? intentMetric;
  final int? transactionMetric;

  const YelpEngagementMetricDto({
    this.startOfWeekDate,
    this.engagementMetric,
    this.intentMetric,
    this.transactionMetric,
  });

  factory YelpEngagementMetricDto.fromJson(Map<String, dynamic> json) =>
      _$YelpEngagementMetricDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpEngagementMetricDtoToJson(this);

  @override
  List<Object?> get props => [
    startOfWeekDate,
    engagementMetric,
    intentMetric,
    transactionMetric,
  ];
}
