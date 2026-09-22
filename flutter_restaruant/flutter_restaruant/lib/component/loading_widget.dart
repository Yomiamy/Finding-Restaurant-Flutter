import 'package:flutter/material.dart';

import '../features/foundation/style/style_barrel.dart';
import '../generated/l10n.dart';

class LoadingWidget extends StatelessWidget {
  final String? text;

  const LoadingWidget({super.key, this.text});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const CircularProgressIndicator(),
      const SizedBox(height: ThemeSize.space20),
      Text(text ?? S.current.loading),
    ],
  );
}
