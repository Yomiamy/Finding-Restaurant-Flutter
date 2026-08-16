// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_restaurant_summary_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpRestaurantSummaryDto _$YelpRestaurantSummaryDtoFromJson(
  Map<String, dynamic> json,
) => YelpRestaurantSummaryDto(
  id: json['id'] as String?,
  name: json['name'] as String?,
  imageUrl: json['image_url'] as String?,
  reviewCount: (json['review_count'] as num?)?.toInt(),
  rating: (json['rating'] as num?)?.toDouble(),
  price: json['price'] as String?,
  phone: json['phone'] as String?,
  distance: (json['distance'] as num?)?.toDouble(),
  categories: (json['categories'] as List<dynamic>?)
      ?.map(
        (e) => YelpRestaurantCategoryDto.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  location: json['location'] == null
      ? null
      : YelpRestaurantLocationDto.fromJson(
          json['location'] as Map<String, dynamic>,
        ),
  coordinates: json['coordinates'] == null
      ? null
      : YelpRestaurantCoordinatesDto.fromJson(
          json['coordinates'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$YelpRestaurantSummaryDtoToJson(
  YelpRestaurantSummaryDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'image_url': instance.imageUrl,
  'review_count': instance.reviewCount,
  'rating': instance.rating,
  'price': instance.price,
  'phone': instance.phone,
  'distance': instance.distance,
  'categories': instance.categories,
  'location': instance.location,
  'coordinates': instance.coordinates,
};
