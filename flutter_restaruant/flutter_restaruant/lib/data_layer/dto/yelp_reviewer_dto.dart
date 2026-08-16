import 'package:json_annotation/json_annotation.dart';

part 'yelp_reviewer_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class YelpReviewerDto {
  String? name;
  String? imageUrl;

  YelpReviewerDto({this.name, this.imageUrl});

  factory YelpReviewerDto.fromJson(Map<String, dynamic> json) =>
      _$YelpReviewerDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpReviewerDtoToJson(this);
}
