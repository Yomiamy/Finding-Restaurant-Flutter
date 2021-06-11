import 'YelpBaseInfo.dart';
import 'YelpReviewerInfo.dart';

class YelpReviewDetailInfo extends YelpBaseInfo {
  String? id;
  int? rating;
  YelpReviewerInfo? user;
  String? text;
  String? time_created;
  String? url;
}