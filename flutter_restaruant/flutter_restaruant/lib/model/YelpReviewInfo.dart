import 'package:json_annotation/json_annotation.dart';
import 'YelpBaseInfo.dart';
import 'YelpReviewDetailInfo.dart';

part 'YelpReviewInfo.g.dart';

@JsonSerializable()
class YelpReviewInfo extends YelpBaseInfo {
  int? total;
  List<String>? possible_languages;
  List<YelpReviewDetailInfo>? reviews;

  YelpReviewInfo():super();

  factory YelpReviewInfo.fromJson(Map<String, dynamic> json) =>
      _$YelpReviewInfoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpReviewInfoToJson(this);
}