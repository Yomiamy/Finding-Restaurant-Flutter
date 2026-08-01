import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/entities_barrel.dart';

part 'account_dto.g.dart';

@JsonSerializable()
class AccountDto {
  String? uid;
  String? account;
  AccountType type;

  AccountDto({
    required this.type,
    this.uid,
    this.account,
  });

  factory AccountDto.fromJson(Map<String, dynamic> json) =>
      _$AccountDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AccountDtoToJson(this);
}
