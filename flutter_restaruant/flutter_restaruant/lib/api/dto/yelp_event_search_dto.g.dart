// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_event_search_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpEventSearchDto _$YelpEventSearchDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('YelpEventSearchDto', json, ($checkedConvert) {
      final val = YelpEventSearchDto(
        events: $checkedConvert(
          'events',
          (v) => (v as List<dynamic>?)
              ?.map((e) => YelpEventDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        total: $checkedConvert('total', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$YelpEventSearchDtoToJson(YelpEventSearchDto instance) =>
    <String, dynamic>{
      'events': instance.events?.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };
