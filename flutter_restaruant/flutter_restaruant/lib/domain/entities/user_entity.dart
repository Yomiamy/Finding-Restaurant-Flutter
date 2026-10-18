import '../../data_layer/model/model_barrel.dart';
import 'account_type_model.dart';

class UserEntity {
  final String? uid;
  final String? account;
  final AccountTypeModel type;

  const UserEntity({required this.type, this.uid, this.account});

  factory UserEntity.fromDto(AccountModel dto) {
    return UserEntity(
      type: dto.type.toModel(),
      uid: dto.uid,
      account: dto.account,
    );
  }

  AccountModel get toDto =>
      AccountModel(type: type.toDto(), uid: uid, account: account);
}
