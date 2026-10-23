// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_business_engagement_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpBusinessEngagementDto _$YelpBusinessEngagementDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('YelpBusinessEngagementDto', json, ($checkedConvert) {
  final val = YelpBusinessEngagementDto(
    businessId: $checkedConvert('business_id', (v) => v as String?),
    metrics: $checkedConvert(
      'metrics',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => YelpEngagementMetricDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'businessId': 'business_id'});

Map<String, dynamic> _$YelpBusinessEngagementDtoToJson(
  YelpBusinessEngagementDto instance,
) => <String, dynamic>{
  'business_id': instance.businessId,
  'metrics': instance.metrics?.map((e) => e.toJson()).toList(),
};
