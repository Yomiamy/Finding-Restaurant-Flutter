import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';

class ViewUtils {
  static void showPromptDialog({
    context:BuildContext,
    title:String,
    msg:String,
    confirmStr:String}) => WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    showPlatformDialog(
        context: context,
        builder: (context) => PlatformAlertDialog(
          key: GlobalKey(debugLabel: "PromptDialog"),
          title: PlatformText(
            title,
            style: TextStyle(
                fontSize: UIConstants.xxhFontSize,
                fontWeight: FontWeight.bold
            ),
          ),
          content: PlatformText(msg),
          actions: [
            PlatformTextButton(
                onPressed: () => Navigator.pop(context),
                child: PlatformText(confirmStr)
            )
          ],
        )
    );
  });



}