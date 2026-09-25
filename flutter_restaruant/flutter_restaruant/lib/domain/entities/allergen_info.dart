import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import '../../generated/l10n.dart';

part 'allergen_info.g.dart';

/// 過敏原風險等級
enum AllergenRiskLevel {
  contains,
  mayContain,
  none;

  static AllergenRiskLevel fromString(String value) {
    return switch (value.toLowerCase()) {
      'contains' => AllergenRiskLevel.contains,
      'may_contain' || 'maycontain' => AllergenRiskLevel.mayContain,
      _ => AllergenRiskLevel.none,
    };
  }

  String toDisplayString() {
    try {
      return switch (this) {
        AllergenRiskLevel.contains => S.current.allergen_risk_contains,
        AllergenRiskLevel.mayContain => S.current.allergen_risk_may_contain,
        AllergenRiskLevel.none => S.current.allergen_risk_none,
      };
    } catch (_) {
      return switch (this) {
        AllergenRiskLevel.contains => '含',
        AllergenRiskLevel.mayContain => '可能含有',
        AllergenRiskLevel.none => '無',
      };
    }
  }
}

/// 食品過敏原模型
@immutable
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
)
class AllergenInfo extends Equatable {
  const AllergenInfo({this.name, this.riskLevel, this.note});

  factory AllergenInfo.fromJson(Map<String, Object?> json) =>
      _$AllergenInfoFromJson(json);

  final String? name;
  @JsonKey(fromJson: _riskLevelFromJson)
  final AllergenRiskLevel? riskLevel;
  final String? note;

  Map<String, Object?> toJson() => _$AllergenInfoToJson(this);

  @override
  List<Object?> get props => [name, riskLevel, note];
}

AllergenRiskLevel? _riskLevelFromJson(String? value) =>
    value == null ? null : AllergenRiskLevel.fromString(value);
