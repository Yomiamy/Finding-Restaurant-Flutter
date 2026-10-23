// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_review_highlights_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpReviewHighlightsDto _$YelpReviewHighlightsDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('YelpReviewHighlightsDto', json, ($checkedConvert) {
  final val = YelpReviewHighlightsDto(
    reviewHighlights: $checkedConvert(
      'review_highlights',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => YelpReviewHighlightDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'reviewHighlights': 'review_highlights'});

Map<String, dynamic> _$YelpReviewHighlightsDtoToJson(
  YelpReviewHighlightsDto instance,
) => <String, dynamic>{
  'review_highlights': instance.reviewHighlights
      ?.map((e) => e.toJson())
      .toList(),
};
