import 'package:json_annotation/json_annotation.dart';

part 'YelpResaruantBusinessTime.g.dart';

@JsonSerializable()
class YelpResaruantBusinessTime {
  bool? is_overnight;
  String? start;
  String? end;
  int? day;

  YelpResaruantBusinessTime();

  factory YelpResaruantBusinessTime.fromJson(Map<String, dynamic> json) =>
      _$YelpResaruantBusinessTimeFromJson(json);

  Map<String, dynamic> toJson() => _$YelpResaruantBusinessTimeToJson(this);
}