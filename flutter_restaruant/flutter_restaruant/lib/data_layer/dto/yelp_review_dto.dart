import 'package:json_annotation/json_annotation.dart';
import 'yelp_review_detail_dto.dart';

part 'yelp_review_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class YelpReviewDto {
  int? total;
  List<String>? possibleLanguages;
  List<YelpReviewDetailDto>? reviews;

  YelpReviewDto({
    this.total,
    this.possibleLanguages,
    this.reviews,
  });

  factory YelpReviewDto.fromJson(Map<String, dynamic> json) =>
      _$YelpReviewDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpReviewDtoToJson(this);
}

