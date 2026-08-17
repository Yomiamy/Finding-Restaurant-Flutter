import 'package:flutter/material.dart';
import '../features/foundation/style/style_barrel.dart';

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
          Icon(
            icon,
            size: ThemeSize.space64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: ThemeSize.space16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
