import 'package:json_annotation/json_annotation.dart';

part 'ResultVo.g.dart';

@JsonSerializable()
class ResultVo {
  int code;
  String msg;
  dynamic obj;

  ResultVo({this.code = -1, this.msg = "N/A", this.obj});

  factory ResultVo.fromJson(Map<String, dynamic> json) =>
      _$ResultVoFromJson(json);

  Map<String, dynamic> toJson() => _$ResultVoToJson(this);
}
