// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allergen_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllergenInfo _$AllergenInfoFromJson(Map<String, dynamic> json) => AllergenInfo(
  name: json['name'] as String?,
  riskLevel: _riskLevelFromJson(json['risk_level'] as String?),
  note: json['note'] as String?,
);

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
