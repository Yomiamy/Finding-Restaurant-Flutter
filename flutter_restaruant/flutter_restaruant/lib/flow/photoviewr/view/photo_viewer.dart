import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/utils/tuple.dart';
import 'package:flutter_restaruant/utils/ui_constants.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_restaruant/gen/colors.gen.dart';

class PhotoViewer extends StatefulWidget {
  static const ROUTE_NAME = "/PhotoViewer";

  const PhotoViewer({Key? key}) : super(key: key);

  @override
  _PhotoViewerState createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late String _photoUrl;

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Tuple2<String, dynamic>;
    this._photoUrl = args.item1;

    return Scaffold(
        appBar: AppBar(
            leading: PlatformIconButton(
                padding: EdgeInsets.all(0),
                onPressed: () => Navigator.of(context).pop(),
                materialIcon: Icon(Icons.arrow_back,
                    color: ColorName.backBtnColor),
                cupertinoIcon: Icon(CupertinoIcons.back,
                    color: ColorName.backBtnColor)),
            title: Text(S.current.photo_viewer_title,
                style: TextStyle(
                    color: Colors.white, fontSize: UIConstants.xxxhFontSize)),
            backgroundColor: ColorName.appPrimaryColor),
        body: InteractiveViewer(
          // Set it to false
          boundaryMargin: EdgeInsets.all(100),
          minScale: 0.5,
          maxScale: 2,
          child: FadeInImage.assetNetwork(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              placeholder: UIConstants.NO_IMAGE,
              image: this._photoUrl,
              fit: BoxFit.contain),
        ));
  }
}
