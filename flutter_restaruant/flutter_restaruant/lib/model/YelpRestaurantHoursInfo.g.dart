// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'YelpRestaurantHoursInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpRestaurantHoursInfo _$YelpRestaurantHoursInfoFromJson(
    Map<String, dynamic> json) {
  return YelpRestaurantHoursInfo()
    ..is_open_now = json['is_open_now'] as bool?
    ..hours_type = json['hours_type'] as String?
    ..open = (json['open'] as List<dynamic>?)
        ?.map((e) =>
            YelpResaruantBusinessTime.fromJson(e as Map<String, dynamic>))
        .toList();
}

Map<String, dynamic> _$YelpRestaurantHoursInfoToJson(
        YelpRestaurantHoursInfo instance) =>
    <String, dynamic>{
      'is_open_now': instance.is_open_now,
      'hours_type': instance.hours_type,
      'open': instance.open,
    };
