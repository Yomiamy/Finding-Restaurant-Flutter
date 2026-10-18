// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_review_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpReviewDto _$YelpReviewDtoFromJson(Map<String, dynamic> json) =>
    YelpReviewDto(
      total: (json['total'] as num?)?.toInt(),
      possibleLanguages: (json['possible_languages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((e) => YelpReviewDetailDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$YelpReviewDtoToJson(YelpReviewDto instance) =>
    <String, dynamic>{
      'total': instance.total,
      'possible_languages': instance.possibleLanguages,
      'reviews': instance.reviews,
    };
