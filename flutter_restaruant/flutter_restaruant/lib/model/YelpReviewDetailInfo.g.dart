// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'YelpReviewDetailInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpReviewDetailInfo _$YelpReviewDetailInfoFromJson(Map<String, dynamic> json) {
  return YelpReviewDetailInfo()
    ..id = json['id'] as String?
    ..rating = (json['rating'] as num?)?.toDouble()
    ..user = json['user'] == null
        ? null
        : YelpReviewerInfo.fromJson(json['user'] as Map<String, dynamic>)
    ..text = json['text'] as String?
    ..time_created = json['time_created'] as String?
    ..url = json['url'] as String?;
}

Map<String, dynamic> _$YelpReviewDetailInfoToJson(
        YelpReviewDetailInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rating': instance.rating,
      'user': instance.user,
      'text': instance.text,
      'time_created': instance.time_created,
      'url': instance.url,
    };
