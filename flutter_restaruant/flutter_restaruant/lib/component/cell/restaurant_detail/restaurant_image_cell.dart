import 'package:flutter/material.dart';
import '../../../flow/photo_viewer/view/view_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../features/utils/utils_barrel.dart';
import '../../../features/foundation/constants/constants_barrel.dart';

class RestaurantImageCell extends StatelessWidget {
  static const int _imageH = 200;

  final List<String> _photos;

  const RestaurantImageCell({super.key, required List<String> photos})
    : _photos = photos;

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty) {
      return const SizedBox.shrink();
    }

    final double itemSize = MediaQuery.of(context).size.width / 3.2;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeSize.space12,
        vertical: ThemeSize.space8,
      ),
      child: SizedBox(
        height: itemSize,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _photos.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(right: ThemeSize.space8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ThemeSize.radius8),
              child: GestureDetector(
                onTap: () {
                  final String photoUrl = _photos[index];
                  final arguments = Tuple2<String, dynamic>(photoUrl, null);

                  Navigator.of(
                    context,
                  ).pushNamed(PhotoViewer.routeName, arguments: arguments);
                },
                child: FadeInImage.assetNetwork(
                  placeholder: UIConstants.noImage,
                  imageErrorBuilder: (context, error, trace) =>
                      Image.asset(UIConstants.noImage, fit: BoxFit.cover),
                  image: _photos[index],
                  imageCacheHeight: RestaurantImageCell._imageH,
                  imageCacheWidth: MediaQuery.of(context).size.width.toInt(),
                  placeholderCacheHeight: RestaurantImageCell._imageH,
                  placeholderCacheWidth: MediaQuery.of(
                    context,
                  ).size.width.toInt(),
                  fit: BoxFit.cover,
                  width: itemSize,
                  height: itemSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
