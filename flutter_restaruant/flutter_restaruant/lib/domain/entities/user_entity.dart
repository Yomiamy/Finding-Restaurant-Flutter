import 'package:json_annotation/json_annotation.dart';
import '../../data_layer/dto/account_dto.dart';

enum AccountType {
  @JsonValue('GOOGLE')
  google,
  @JsonValue('FACEBOOK')
  facebook,
  @JsonValue('APPLE')
  apple,
  @JsonValue('MAIL')
  mail,
  @JsonValue('BIOMETRIC')
  biometric,
  @JsonValue('AUTO')
  auto,
  @JsonValue('NONE')
  none,
}

class UserEntity {
  final String? uid;
  final String? account;
  final AccountType type;

  const UserEntity({
    required this.type,
    this.uid,
    this.account,
  });

  factory UserEntity.fromDto(AccountDto dto) {
    return UserEntity(
      type: dto.type,
      uid: dto.uid,
      account: dto.account,
    );
  }

  AccountDto get toDto => AccountDto(
        type: type,
        uid: uid,
        account: account,
      );
}
