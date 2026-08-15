// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_restaurant_hours_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpRestaurantHoursDto _$YelpRestaurantHoursDtoFromJson(
  Map<String, dynamic> json,
) => YelpRestaurantHoursDto(
  isOpenNow: json['is_open_now'] as bool?,
  hoursType: json['hours_type'] as String?,
  open: (json['open'] as List<dynamic>?)
      ?.map(
        (e) =>
            YelpRestaurantBusinessTimeDto.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
);

Map<String, dynamic> _$YelpRestaurantHoursDtoToJson(
  YelpRestaurantHoursDto instance,
) => <String, dynamic>{
  'is_open_now': instance.isOpenNow,
  'hours_type': instance.hoursType,
  'open': instance.open,
};
