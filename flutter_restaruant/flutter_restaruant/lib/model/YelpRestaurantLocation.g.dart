// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'YelpRestaurantLocation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpRestaurantLocation _$YelpRestaurantLocationFromJson(
    Map<String, dynamic> json) {
  return YelpRestaurantLocation()
    ..address1 = json['address1'] as String?
    ..address2 = json['address2'] as String?
    ..address3 = json['address3'] as String?
    ..city = json['city'] as String?
    ..country = json['country'] as String?
    ..state = json['state'] as String?
    ..display_address = (json['display_address'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList();
}

Map<String, dynamic> _$YelpRestaurantLocationToJson(
        YelpRestaurantLocation instance) =>
    <String, dynamic>{
      'address1': instance.address1,
      'address2': instance.address2,
      'address3': instance.address3,
      'city': instance.city,
      'country': instance.country,
      'state': instance.state,
      'display_address': instance.display_address,
    };
