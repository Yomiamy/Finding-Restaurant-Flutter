import '../../data_layer/dto/dto_barrel.dart';
import '../../features/foundation/foundation_barrel.dart';

class UserEntity {
  final String? uid;
  final String? account;
  final AccountType type;

  const UserEntity({required this.type, this.uid, this.account});

  factory UserEntity.fromDto(AccountDto dto) {
    return UserEntity(type: dto.type, uid: dto.uid, account: dto.account);
  }

  AccountDto get toDto => AccountDto(type: type, uid: uid, account: account);
}
