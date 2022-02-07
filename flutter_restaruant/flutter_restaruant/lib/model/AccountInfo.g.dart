// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'AccountInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountInfo _$AccountInfoFromJson(Map<String, dynamic> json) {
  return AccountInfo(
    type: _$enumDecode(_$AccountTypeEnumMap, json['type']),
    uid: json['uid'] as String?,
    account: json['account'] as String?,
  );
}

Map<String, dynamic> _$AccountInfoToJson(AccountInfo instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'account': instance.account,
      'type': _$AccountTypeEnumMap[instance.type],
    };

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

const _$AccountTypeEnumMap = {
  AccountType.GOOGLE: 'GOOGLE',
  AccountType.FACEBOOK: 'FACEBOOK',
  AccountType.APPLE: 'APPLE',
  AccountType.NONE: 'NONE',
};
