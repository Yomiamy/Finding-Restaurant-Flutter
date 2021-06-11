// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'YelpRestaurantDetailInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpRestaurantDetailInfo _$YelpRestaurantDetailInfoFromJson(
    Map<String, dynamic> json) {
  return YelpRestaurantDetailInfo()
    ..name = json['name'] as String?
    ..image_url = json['image_url'] as String?
    ..is_closed = json['is_closed'] as bool?
    ..review_count = json['review_count'] as int?
    ..rating = (json['rating'] as num?)?.toDouble()
    ..phone = json['phone'] as String?
    ..categories = (json['categories'] as List<dynamic>?)
        ?.map((e) => YelpRestaurantCategory.fromJson(e as Map<String, dynamic>))
        .toList()
    ..location = json['location'] == null
        ? null
        : YelpRestaurantLocation.fromJson(
            json['location'] as Map<String, dynamic>)
    ..coordinates = json['coordinates'] == null
        ? null
        : YelpRestaurantCoordinates.fromJson(
            json['coordinates'] as Map<String, dynamic>)
    ..photos =
        (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList()
    ..hours = (json['hours'] as List<dynamic>?)
        ?.map(
            (e) => YelpRestaurantHoursInfo.fromJson(e as Map<String, dynamic>))
        .toList();
}

Map<String, dynamic> _$YelpRestaurantDetailInfoToJson(
        YelpRestaurantDetailInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'image_url': instance.image_url,
      'is_closed': instance.is_closed,
      'review_count': instance.review_count,
      'rating': instance.rating,
      'phone': instance.phone,
      'categories': instance.categories,
      'location': instance.location,
      'coordinates': instance.coordinates,
      'photos': instance.photos,
      'hours': instance.hours,
    };
