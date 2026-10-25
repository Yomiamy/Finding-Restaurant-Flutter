// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_engagement_metric_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpEngagementMetricDto _$YelpEngagementMetricDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'YelpEngagementMetricDto',
  json,
  ($checkedConvert) {
    final val = YelpEngagementMetricDto(
      startOfWeekDate: $checkedConvert(
        'start_of_week_date',
        (v) => v as String?,
      ),
      engagementMetric: $checkedConvert(
        'engagement_metric',
        (v) => (v as num?)?.toInt(),
      ),
      intentMetric: $checkedConvert(
        'intent_metric',
        (v) => (v as num?)?.toInt(),
      ),
      transactionMetric: $checkedConvert(
        'transaction_metric',
        (v) => (v as num?)?.toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'startOfWeekDate': 'start_of_week_date',
    'engagementMetric': 'engagement_metric',
    'intentMetric': 'intent_metric',
    'transactionMetric': 'transaction_metric',
  },
);

Map<String, dynamic> _$YelpEngagementMetricDtoToJson(
  YelpEngagementMetricDto instance,
) => <String, dynamic>{
  'start_of_week_date': instance.startOfWeekDate,
  'engagement_metric': instance.engagementMetric,
  'intent_metric': instance.intentMetric,
  'transaction_metric': instance.transactionMetric,
};
