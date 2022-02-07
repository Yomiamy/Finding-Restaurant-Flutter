import 'package:json_annotation/json_annotation.dart';

part 'AccountInfo.g.dart';

enum AccountType {
  GOOGLE, FACEBOOK, APPLE, NONE
}

@JsonSerializable()
class AccountInfo {

  String? uid;
  String? account;
  AccountType type;


  AccountInfo({required this.type, this.uid, this.account});

  factory AccountInfo.fromJson(Map<String, dynamic> json) =>
      _$AccountInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AccountInfoToJson(this);
}