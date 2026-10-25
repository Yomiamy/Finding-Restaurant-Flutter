// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_engagement_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpEngagementDto _$YelpEngagementDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('YelpEngagementDto', json, ($checkedConvert) {
      final val = YelpEngagementDto(
        data: $checkedConvert(
          'data',
          (v) => (v as List<dynamic>?)
              ?.map(
                (e) => YelpBusinessEngagementDto.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$YelpEngagementDtoToJson(YelpEngagementDto instance) =>
    <String, dynamic>{'data': instance.data?.map((e) => e.toJson()).toList()};
