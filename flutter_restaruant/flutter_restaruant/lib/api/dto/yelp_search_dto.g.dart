// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_search_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpSearchDto _$YelpSearchDtoFromJson(Map<String, dynamic> json) =>
    YelpSearchDto(
      businesses: (json['businesses'] as List<dynamic>?)
          ?.map(
            (e) => YelpRestaurantSummaryDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      total: (json['total'] as num?)?.toInt(),
    );

Map<String, dynamic> _$YelpSearchDtoToJson(YelpSearchDto instance) =>
    <String, dynamic>{
      'businesses': instance.businesses,
      'total': instance.total,
    };
