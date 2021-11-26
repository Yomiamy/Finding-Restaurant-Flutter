// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'YelpRestaurantSummaryInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpRestaurantSummaryInfo _$YelpRestaurantSummaryInfoFromJson(
    Map<String, dynamic> json) {
  return YelpRestaurantSummaryInfo()
    ..id = json['id'] as String?
    ..name = json['name'] as String?
    ..image_url = json['image_url'] as String?
    ..review_count = json['review_count'] as int?
    ..rating = (json['rating'] as num?)?.toDouble()
    ..price = json['price'] as String?
    ..phone = json['phone'] as String?
    ..distance = (json['distance'] as num?)?.toDouble()
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
            json['coordinates'] as Map<String, dynamic>);
}

Map<String, dynamic> _$YelpRestaurantSummaryInfoToJson(
        YelpRestaurantSummaryInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'image_url': instance.image_url,
      'review_count': instance.review_count,
      'rating': instance.rating,
      'price': instance.price,
      'phone': instance.phone,
      'distance': instance.distance,
      'categories': instance.categories,
      'location': instance.location,
      'coordinates': instance.coordinates,
    };
