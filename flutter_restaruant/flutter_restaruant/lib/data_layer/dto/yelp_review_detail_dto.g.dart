// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_review_detail_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpReviewDetailDto _$YelpReviewDetailDtoFromJson(Map<String, dynamic> json) =>
    YelpReviewDetailDto(
      id: json['id'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      user: json['user'] == null
          ? null
          : YelpReviewerDto.fromJson(json['user'] as Map<String, dynamic>),
      text: json['text'] as String?,
      timeCreated: json['time_created'] as String?,
      url: json['url'] as String?,
    );

Map<String, dynamic> _$YelpReviewDetailDtoToJson(
        YelpReviewDetailDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rating': instance.rating,
      'user': instance.user,
      'text': instance.text,
      'time_created': instance.timeCreated,
      'url': instance.url,
    };
