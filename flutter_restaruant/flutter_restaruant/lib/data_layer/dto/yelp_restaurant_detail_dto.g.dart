// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_restaurant_detail_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpRestaurantDetailDto _$YelpRestaurantDetailDtoFromJson(
        Map<String, dynamic> json) =>
    YelpRestaurantDetailDto(
      name: json['name'] as String?,
      imageUrl: json['image_url'] as String?,
      isClosed: json['is_closed'] as bool?,
      reviewCount: (json['review_count'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toDouble(),
      phone: json['phone'] as String?,
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) =>
              YelpRestaurantCategoryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      location: json['location'] == null
          ? null
          : YelpRestaurantLocationDto.fromJson(
              json['location'] as Map<String, dynamic>),
      coordinates: json['coordinates'] == null
          ? null
          : YelpRestaurantCoordinatesDto.fromJson(
              json['coordinates'] as Map<String, dynamic>),
      photos:
          (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList(),
      hours: (json['hours'] as List<dynamic>?)
          ?.map(
              (e) => YelpRestaurantHoursDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$YelpRestaurantDetailDtoToJson(
        YelpRestaurantDetailDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'image_url': instance.imageUrl,
      'is_closed': instance.isClosed,
      'review_count': instance.reviewCount,
      'rating': instance.rating,
      'phone': instance.phone,
      'categories': instance.categories,
      'location': instance.location,
      'coordinates': instance.coordinates,
      'photos': instance.photos,
      'hours': instance.hours,
    };
