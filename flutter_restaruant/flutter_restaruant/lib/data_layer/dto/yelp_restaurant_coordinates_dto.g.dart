// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_restaurant_coordinates_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpRestaurantCoordinatesDto _$YelpRestaurantCoordinatesDtoFromJson(
  Map<String, dynamic> json,
) => YelpRestaurantCoordinatesDto(
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$YelpRestaurantCoordinatesDtoToJson(
  YelpRestaurantCoordinatesDto instance,
) => <String, dynamic>{
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
