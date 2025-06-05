import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';

class ViewUtils {
  static void showPromptDialog(
          {required BuildContext context,
          required String title,
          required Widget msgWidget,
          required List<Widget> actions}) =>
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        showPlatformDialog(
            context: context,
            builder: (context) => PlatformAlertDialog(
                  key: GlobalKey(debugLabel: "PromptDialog"),
                  title: PlatformText(
                    title,
                    style: TextStyle(
                        fontSize: UIConstants.xxhFontSize,
                        fontWeight: FontWeight.bold),
                  ),
                  content: msgWidget,
                  actions: actions,
                ));
      });
}
