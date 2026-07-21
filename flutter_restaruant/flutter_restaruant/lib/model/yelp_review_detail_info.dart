import 'package:json_annotation/json_annotation.dart';
import 'yelp_base_info.dart';
import 'yelp_reviewer_info.dart';

part 'yelp_review_detail_info.g.dart';

@JsonSerializable()
class YelpReviewDetailInfo extends YelpBaseInfo {
  String? id;
  double? rating;
  YelpReviewerInfo? user;
  String? text;
  String? time_created;
  String? url;

  YelpReviewDetailInfo() : super();

  factory YelpReviewDetailInfo.fromJson(Map<String, dynamic> json) =>
      _$YelpReviewDetailInfoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpReviewDetailInfoToJson(this);
}
