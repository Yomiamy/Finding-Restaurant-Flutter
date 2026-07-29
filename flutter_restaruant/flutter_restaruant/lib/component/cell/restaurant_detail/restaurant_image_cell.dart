import 'package:flutter/material.dart';
import '../../../flow/photoviewr/view/photo_viewer.dart';
import '../../../utils/tuple.dart';
import '../../../utils/ui_constants.dart';

class RestaurantImageCell extends StatelessWidget {
  static const int _imageH = 200;

  final List<String> _photos;

  const RestaurantImageCell({super.key, required List<String> photos})
      : _photos = photos;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.only(top: 10),
      height: MediaQuery.of(context).size.width / 3,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _photos.length,
          itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: GestureDetector(
                onTap: () {
                  String photoUrl = _photos[index];
                  Tuple2 arguments = Tuple2<String, dynamic>(photoUrl, null);

                  Navigator.of(context)
                      .pushNamed(PhotoViewer.routeName, arguments: arguments);
                },
                child: FadeInImage.assetNetwork(
                    placeholder: UIConstants.noImage,
                    image: _photos[index],
                    imageCacheHeight: RestaurantImageCell._imageH,
                    imageCacheWidth: MediaQuery.of(context).size.width.toInt(),
                    placeholderCacheHeight: RestaurantImageCell._imageH,
                    placeholderCacheWidth:
                        MediaQuery.of(context).size.width.toInt(),
                    fit: BoxFit.fill,
                    width: MediaQuery.of(context).size.width / 3,
                    height: MediaQuery.of(context).size.width / 3),
              ))));
}
