import 'package:json_annotation/json_annotation.dart';

part 'AccountInfo.g.dart';

enum AccountType {
  GOOGLE,
  FACEBOOK,
  APPLE,
  MAIL,
  // 以下為不存在於實際資料的Account Type
  BIOMETRIC,
  AUTO,
  NONE
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