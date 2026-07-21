// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountInfo _$AccountInfoFromJson(Map<String, dynamic> json) => AccountInfo(
      type: $enumDecode(_$AccountTypeEnumMap, json['type']),
      uid: json['uid'] as String?,
      account: json['account'] as String?,
    );

Map<String, dynamic> _$AccountInfoToJson(AccountInfo instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'account': instance.account,
      'type': _$AccountTypeEnumMap[instance.type]!,
    };

const _$AccountTypeEnumMap = {
  AccountType.GOOGLE: 'GOOGLE',
  AccountType.FACEBOOK: 'FACEBOOK',
  AccountType.APPLE: 'APPLE',
  AccountType.MAIL: 'MAIL',
  AccountType.BIOMETRIC: 'BIOMETRIC',
  AccountType.AUTO: 'AUTO',
  AccountType.NONE: 'NONE',
};
