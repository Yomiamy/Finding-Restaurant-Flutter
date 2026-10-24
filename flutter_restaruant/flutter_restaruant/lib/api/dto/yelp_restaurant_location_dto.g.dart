// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_restaurant_location_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpRestaurantLocationDto _$YelpRestaurantLocationDtoFromJson(
  Map<String, dynamic> json,
) => YelpRestaurantLocationDto(
  address1: json['address1'] as String?,
  address2: json['address2'] as String?,
  address3: json['address3'] as String?,
  city: json['city'] as String?,
  country: json['country'] as String?,
  state: json['state'] as String?,
  displayAddress: (json['display_address'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  zipCode: json['zip_code'] as String?,
  crossStreets: json['cross_streets'] as String?,
);

Map<String, dynamic> _$YelpRestaurantLocationDtoToJson(
  YelpRestaurantLocationDto instance,
) => <String, dynamic>{
  'address1': instance.address1,
  'address2': instance.address2,
  'address3': instance.address3,
  'city': instance.city,
  'country': instance.country,
  'state': instance.state,
  'display_address': instance.displayAddress,
  'zip_code': ?instance.zipCode,
  'cross_streets': ?instance.crossStreets,
};
