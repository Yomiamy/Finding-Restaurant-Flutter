// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'YelpResaruantBusinessTime.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpResaruantBusinessTime _$YelpResaruantBusinessTimeFromJson(
        Map<String, dynamic> json) =>
    YelpResaruantBusinessTime()
      ..is_overnight = json['is_overnight'] as bool?
      ..start = json['start'] as String?
      ..end = json['end'] as String?
      ..day = (json['day'] as num?)?.toInt();

Map<String, dynamic> _$YelpResaruantBusinessTimeToJson(
        YelpResaruantBusinessTime instance) =>
    <String, dynamic>{
      'is_overnight': instance.is_overnight,
      'start': instance.start,
      'end': instance.end,
      'day': instance.day,
    };
