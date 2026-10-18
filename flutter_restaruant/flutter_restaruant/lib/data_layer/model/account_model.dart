import 'package:json_annotation/json_annotation.dart';
import 'account_type.dart';

part 'account_model.g.dart';

@JsonSerializable()
class AccountModel {
  String? uid;
  String? account;
  AccountType type;

  AccountModel({required this.type, this.uid, this.account});

  factory AccountModel.fromJson(Map<String, dynamic> json) =>
      _$AccountModelFromJson(json);

  Map<String, dynamic> toJson() => _$AccountModelToJson(this);
}
