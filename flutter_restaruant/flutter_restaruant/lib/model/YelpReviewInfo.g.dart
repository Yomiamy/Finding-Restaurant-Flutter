// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'YelpReviewInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpReviewInfo _$YelpReviewInfoFromJson(Map<String, dynamic> json) {
  return YelpReviewInfo()
    ..total = json['total'] as int?
    ..possible_languages = (json['possible_languages'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList()
    ..reviews = (json['reviews'] as List<dynamic>?)
        ?.map((e) => YelpReviewDetailInfo.fromJson(e as Map<String, dynamic>))
        .toList();
}

Map<String, dynamic> _$YelpReviewInfoToJson(YelpReviewInfo instance) =>
    <String, dynamic>{
      'total': instance.total,
      'possible_languages': instance.possible_languages,
      'reviews': instance.reviews,
    };
