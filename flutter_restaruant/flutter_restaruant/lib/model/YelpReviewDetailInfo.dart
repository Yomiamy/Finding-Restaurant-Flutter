import 'package:json_annotation/json_annotation.dart';
import 'YelpBaseInfo.dart';
import 'YelpReviewerInfo.dart';

part 'YelpReviewDetailInfo.g.dart';

@JsonSerializable()
class YelpReviewDetailInfo extends YelpBaseInfo {
  String? id;
  int? rating;
  YelpReviewerInfo? user;
  String? text;
  String? time_created;
  String? url;

  YelpReviewDetailInfo():super();

  factory YelpReviewDetailInfo.fromJson(Map<String, dynamic> json) =>
      _$YelpReviewDetailInfoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpReviewDetailInfoToJson(this);
}