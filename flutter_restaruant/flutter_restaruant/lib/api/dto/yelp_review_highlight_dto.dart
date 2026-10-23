import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'yelp_review_highlight_dto.g.dart';

@JsonSerializable(checked: true, fieldRename: FieldRename.snake)
class YelpReviewHighlightDto extends Equatable {
  final String? photo;

  // 保留 [[HIGHLIGHT]]…[[ENDHIGHLIGHT]] 標記的原字串，不解析。
  final String? sentence;
  final int? reviewCount;

  const YelpReviewHighlightDto({this.photo, this.sentence, this.reviewCount});

  factory YelpReviewHighlightDto.fromJson(Map<String, dynamic> json) =>
      _$YelpReviewHighlightDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpReviewHighlightDtoToJson(this);

  @override
  List<Object?> get props => [photo, sentence, reviewCount];
}
