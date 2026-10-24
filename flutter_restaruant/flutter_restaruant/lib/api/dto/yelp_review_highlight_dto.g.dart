// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_review_highlight_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpReviewHighlightDto _$YelpReviewHighlightDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('YelpReviewHighlightDto', json, ($checkedConvert) {
  final val = YelpReviewHighlightDto(
    photo: $checkedConvert('photo', (v) => v as String?),
    sentence: $checkedConvert('sentence', (v) => v as String?),
    reviewCount: $checkedConvert('review_count', (v) => (v as num?)?.toInt()),
  );
  return val;
}, fieldKeyMap: const {'reviewCount': 'review_count'});

Map<String, dynamic> _$YelpReviewHighlightDtoToJson(
  YelpReviewHighlightDto instance,
) => <String, dynamic>{
  'photo': instance.photo,
  'sentence': instance.sentence,
  'review_count': instance.reviewCount,
};
