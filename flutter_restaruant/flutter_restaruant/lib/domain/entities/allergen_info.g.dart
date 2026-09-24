// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allergen_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllergenInfo _$AllergenInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AllergenInfo', json, ($checkedConvert) {
      final val = AllergenInfo(
        name: $checkedConvert('name', (v) => v as String?),
        riskLevel: $checkedConvert(
          'risk_level',
          (v) => _riskLevelFromJson(v as String?),
        ),
        note: $checkedConvert('note', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'riskLevel': 'risk_level'});

Map<String, dynamic> _$AllergenInfoToJson(AllergenInfo instance) =>
    <String, dynamic>{
      'name': ?instance.name,
      'risk_level': ?_$AllergenRiskLevelEnumMap[instance.riskLevel],
      'note': ?instance.note,
    };

const _$AllergenRiskLevelEnumMap = {
  AllergenRiskLevel.contains: 'contains',
  AllergenRiskLevel.mayContain: 'mayContain',
  AllergenRiskLevel.none: 'none',
};
