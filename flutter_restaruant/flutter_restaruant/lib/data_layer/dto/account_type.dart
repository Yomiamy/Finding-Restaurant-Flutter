import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/account_type_model.dart';

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
  none;

  AccountTypeModel toModel() => AccountTypeModel.values.byName(name);

  static AccountType fromModel(AccountTypeModel model) =>
      AccountType.values.byName(model.name);
}

extension AccountTypeModelX on AccountTypeModel {
  AccountType toDto() => AccountType.fromModel(this);
}
