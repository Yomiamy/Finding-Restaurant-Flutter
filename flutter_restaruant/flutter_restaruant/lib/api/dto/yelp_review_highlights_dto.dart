import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'yelp_review_highlight_dto.dart';

part 'yelp_review_highlights_dto.g.dart';

@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  explicitToJson: true,
)
class YelpReviewHighlightsDto extends Equatable {
  final List<YelpReviewHighlightDto>? reviewHighlights;

  const YelpReviewHighlightsDto({this.reviewHighlights});

  factory YelpReviewHighlightsDto.fromJson(Map<String, dynamic> json) =>
      _$YelpReviewHighlightsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpReviewHighlightsDtoToJson(this);

  @override
  List<Object?> get props => [reviewHighlights];
}
