// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountModel _$AccountModelFromJson(Map<String, dynamic> json) => AccountModel(
  type: $enumDecode(_$AccountTypeEnumMap, json['type']),
  uid: json['uid'] as String?,
  account: json['account'] as String?,
);

Map<String, dynamic> _$AccountModelToJson(AccountModel instance) =>
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
