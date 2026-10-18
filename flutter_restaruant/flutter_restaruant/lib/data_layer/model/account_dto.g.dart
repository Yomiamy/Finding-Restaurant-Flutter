// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountDto _$AccountDtoFromJson(Map<String, dynamic> json) => AccountDto(
  type: $enumDecode(_$AccountTypeEnumMap, json['type']),
  uid: json['uid'] as String?,
  account: json['account'] as String?,
);

Map<String, dynamic> _$AccountDtoToJson(AccountDto instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'account': instance.account,
      'type': _$AccountTypeEnumMap[instance.type]!,
    };

const _$AccountTypeEnumMap = {
  AccountType.google: 'GOOGLE',
  AccountType.facebook: 'FACEBOOK',
  AccountType.apple: 'APPLE',
  AccountType.mail: 'MAIL',
  AccountType.biometric: 'BIOMETRIC',
  AccountType.auto: 'AUTO',
  AccountType.none: 'NONE',
};
