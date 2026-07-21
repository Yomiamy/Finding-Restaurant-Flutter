import 'package:flutter_restaruant/model/yelp_base_info.dart';
import 'package:json_annotation/json_annotation.dart';

part 'yelp_reviewer_info.g.dart';

@JsonSerializable()
class YelpReviewerInfo extends YelpBaseInfo {
  String? name;
  String? image_url;

  YelpReviewerInfo() : super();

  factory YelpReviewerInfo.fromJson(Map<String, dynamic> json) =>
      _$YelpReviewerInfoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpReviewerInfoToJson(this);
}
