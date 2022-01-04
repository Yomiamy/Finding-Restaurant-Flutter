import 'package:json_annotation/json_annotation.dart';

part 'AccountInfo.g.dart';

@JsonSerializable()
class AccountInfo {

  String? uid;
  String? account;

  AccountInfo({this.uid, this.account});

  factory AccountInfo.fromJson(Map<String, dynamic> json) =>
      _$AccountInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AccountInfoToJson(this);
}