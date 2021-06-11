// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'YelpRestaurantCoordinates.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpRestaurantCoordinates _$YelpRestaurantCoordinatesFromJson(
    Map<String, dynamic> json) {
  return YelpRestaurantCoordinates()
    ..latitude = (json['latitude'] as num?)?.toDouble()
    ..longitude = (json['longitude'] as num?)?.toDouble();
}

Map<String, dynamic> _$YelpRestaurantCoordinatesToJson(
        YelpRestaurantCoordinates instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
