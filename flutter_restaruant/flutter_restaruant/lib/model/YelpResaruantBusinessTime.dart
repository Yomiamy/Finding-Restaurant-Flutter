import 'package:flutter_restaruant/model/YelpBaseInfo.dart';
import 'package:json_annotation/json_annotation.dart';

part 'YelpResaruantBusinessTime.g.dart';

@JsonSerializable()
class YelpResaruantBusinessTime extends YelpBaseInfo {
  bool? is_overnight;
  String? start;
  String? end;
  int? day;
  String get dayStr => this.getWeekDayStrByIndex(this.day ?? 0);

  YelpResaruantBusinessTime();

  factory YelpResaruantBusinessTime.fromJson(Map<String, dynamic> json) =>
      _$YelpResaruantBusinessTimeFromJson(json);

  Map<String, dynamic> toJson() => _$YelpResaruantBusinessTimeToJson(this);
}
