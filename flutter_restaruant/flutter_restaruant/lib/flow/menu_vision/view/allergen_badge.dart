import 'package:flutter/material.dart';

import '../../../domain/entities/entities_barrel.dart';

/// 過敏原醒目標籤
class AllergenBadge extends StatelessWidget {
  final AllergenInfo allergen;

  const AllergenBadge({
    super.key,
    required this.allergen,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bgColor, Color borderColor, Color textColor, IconData icon) =
        switch (allergen.riskLevel) {
          AllergenRiskLevel.contains => (
            const Color(0xFFFFEBEE),
            const Color(0xFFEF5350),
            const Color(0xFFC62828),
            Icons.warning_amber_rounded,
          ),
          AllergenRiskLevel.mayContain => (
            const Color(0xFFFFF8E1),
            const Color(0xFFFFCA28),
            const Color(0xFFE65100),
            Icons.help_outline_rounded,
          ),
          AllergenRiskLevel.none => (
            const Color(0xFFE8F5E9),
            const Color(0xFF81C784),
            const Color(0xFF2E7D32),
            Icons.check_circle_outline_rounded,
          ),
        };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            '${allergen.name} (${allergen.riskLevel.toDisplayString()})',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
