import 'package:json_annotation/json_annotation.dart';
import 'yelp_reviewer_dto.dart';

part 'yelp_review_detail_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class YelpReviewDetailDto {
  String? id;
  double? rating;
  YelpReviewerDto? user;
  String? text;
  String? timeCreated;
  String? url;

  YelpReviewDetailDto({
    this.id,
    this.rating,
    this.user,
    this.text,
    this.timeCreated,
    this.url,
  });

  factory YelpReviewDetailDto.fromJson(Map<String, dynamic> json) =>
      _$YelpReviewDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpReviewDetailDtoToJson(this);
}

