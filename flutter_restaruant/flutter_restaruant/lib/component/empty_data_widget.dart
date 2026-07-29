import 'package:flutter/material.dart';
import '../utils/ui_constants.dart';

class EmptyDataWidget extends StatelessWidget {
  const EmptyDataWidget({super.key});

  @override
  Widget build(BuildContext context) => const Center(
      child: Text('目前無任何資料',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: UIConstants.xxxhFontSize)));
}
