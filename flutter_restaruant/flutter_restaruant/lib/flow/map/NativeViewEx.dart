import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class NativeViewExPage extends StatefulWidget {
  const NativeViewExPage({Key? key}) : super(key: key);

  @override
  State<NativeViewExPage> createState() => _NativeViewExPageState();
}

class _NativeViewExPageState extends State<NativeViewExPage> {

  int _viewId = 0;

  @override
  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    const String viewType = 'platform_text_view';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};
    creationParams["content"] = "${Theme.of(context).platform.name} TextView";


    return Scaffold(
        appBar: AppBar(
          title: Text('appbarTitle'),
        ),
        body: Container(
          child: Center(
            child: PlatformWidget(
                cupertino: (context, platform) => UiKitView(
                    viewType: viewType,
                    layoutDirection: TextDirection.ltr,
                    creationParams: creationParams,
                    creationParamsCodec: const StandardMessageCodec(),
                    onPlatformViewCreated: (id) {
                      this._viewId = id;
                    }
                ),
                material: (context, platform) =>  AndroidView(
                    viewType: viewType,
                    layoutDirection: TextDirection.ltr,
                    creationParams: creationParams,
                    creationParamsCodec: const StandardMessageCodec(),
                    onPlatformViewCreated: (id) {
                      this._viewId = id;
                    }
                ))
          )
        ));
  }
}
