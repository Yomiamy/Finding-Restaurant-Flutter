import 'package:flutter/material.dart';
import '../features/foundation/constants/constants_barrel.dart';

class EmptyDataWidget extends StatelessWidget {
  const EmptyDataWidget({
    super.key,
    this.message = '目前無任何資料',
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64.0, color: Colors.grey),
          const SizedBox(height: 16.0),
          Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: UIConstants.xxxhFontSize,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
