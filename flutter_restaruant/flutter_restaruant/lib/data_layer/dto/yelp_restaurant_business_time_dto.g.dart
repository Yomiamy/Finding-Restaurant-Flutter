// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_restaurant_business_time_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpRestaurantBusinessTimeDto _$YelpRestaurantBusinessTimeDtoFromJson(
        Map<String, dynamic> json) =>
    YelpRestaurantBusinessTimeDto(
      isOvernight: json['is_overnight'] as bool?,
      start: json['start'] as String?,
      end: json['end'] as String?,
      day: (json['day'] as num?)?.toInt(),
    );

Map<String, dynamic> _$YelpRestaurantBusinessTimeDtoToJson(
        YelpRestaurantBusinessTimeDto instance) =>
    <String, dynamic>{
      'is_overnight': instance.isOvernight,
      'start': instance.start,
      'end': instance.end,
      'day': instance.day,
    };
