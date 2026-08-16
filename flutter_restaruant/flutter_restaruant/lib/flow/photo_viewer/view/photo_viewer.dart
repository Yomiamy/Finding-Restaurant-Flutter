import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../features/utils/utils_barrel.dart';
import '../../../features/foundation/constants/constants_barrel.dart';
import '../../../generated/l10n.dart';

class PhotoViewer extends StatefulWidget {
  static const routeName = '/PhotoViewer';

  const PhotoViewer({super.key});

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late String _photoUrl;

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Tuple2<String, dynamic>;
    _photoUrl = args.item1;

    return Scaffold(
      appBar: AppBar(
        leading: PlatformIconButton(
          padding: const EdgeInsets.all(ThemeSize.zero),
          onPressed: () => Navigator.of(context).pop(),
          materialIcon: const Icon(Icons.arrow_back, color: ThemeColor.backBtn),
          cupertinoIcon: const Icon(
            CupertinoIcons.back,
            color: ThemeColor.backBtn,
          ),
        ),
        title: Text(
          S.current.photo_viewer_title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: UIConstants.xxxhFontSize,
          ),
        ),
        backgroundColor: ThemeColor.appPrimary,
      ),
      body: InteractiveViewer(
        // Set it to false
        boundaryMargin: const EdgeInsets.all(100),
        minScale: 0.5,
        maxScale: 2,
        child: FadeInImage.assetNetwork(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          placeholder: UIConstants.noImage,
          image: _photoUrl,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
