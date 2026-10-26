import 'package:flutter/material.dart';

import '../../../../generated/l10n.dart';
import '../../../foundation/style/style_barrel.dart';
import '../../../utils/utils_barrel.dart';

class RestaurantDetailTitle extends StatelessWidget {
  final String name;
  final String? url;

  const RestaurantDetailTitle(this.name, {super.key, this.url});

  @override
  Widget build(BuildContext context) {
    final String link = url ?? '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: Text(
            name,
            style: const TextStyle(
              color: ThemeColor.colorffffff,
              fontSize: ThemeFontSize.fontSize22,
            ),
          ),
        ),
        if (link.isNotEmpty)
          IconButton(
            tooltip: S.current.open_in_yelp,
            icon: const Icon(Icons.open_in_new, color: ThemeColor.colorffffff),
            onPressed: () => Utils.openUrl(rawUrl: link),
          ),
      ],
    );
  }
}
