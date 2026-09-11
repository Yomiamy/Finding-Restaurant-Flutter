import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

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
    return switch (this) {
      AllergenRiskLevel.contains => '含',
      AllergenRiskLevel.mayContain => '可能含有',
      AllergenRiskLevel.none => '無',
    };
  }
}

/// 食品過敏原模型
@immutable
class AllergenInfo extends Equatable {
  const AllergenInfo({
    required this.name,
    required this.riskLevel,
    this.note = '',
  });

  factory AllergenInfo.fromJson(Map<String, Object?> json) {
    final rawName = json['name'] as String? ?? '';
    final rawRisk = json['risk_level'] as String? ?? 'none';
    final rawNote = json['note'] as String? ?? '';

    return AllergenInfo(
      name: rawName,
      riskLevel: AllergenRiskLevel.fromString(rawRisk),
      note: rawNote,
    );
  }

  final String name;
  final AllergenRiskLevel riskLevel;
  final String note;

  Map<String, Object?> toJson() => {
    'name': name,
    'risk_level': riskLevel.name,
    'note': note,
  };

  @override
  List<Object?> get props => [name, riskLevel, note];
}
