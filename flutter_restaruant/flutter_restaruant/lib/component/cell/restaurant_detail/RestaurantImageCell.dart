import 'package:flutter/material.dart';
import 'package:flutter_restaruant/flow/photoviewr/view/PhotoViewer.dart';
import 'package:flutter_restaruant/utils/Tuple.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';

class RestaurantImageCell extends StatelessWidget {
  static const int _IMAGE_H = 200;

  final List<String> _photos;

  const RestaurantImageCell({Key? key, required List<String> photos})
      : this._photos = photos,
        super(key: key);

  @override
  Widget build(BuildContext context) => Container(
      padding: EdgeInsets.only(top: 10),
      height: MediaQuery.of(context).size.width / 3,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: this._photos.length,
          itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: GestureDetector(
                onTap: () {
                  String photoUrl = this._photos[index];
                  Tuple2 arguments = Tuple2<String, dynamic>(photoUrl, null);

                  Navigator.of(context).pushNamed(
                      PhotoViewer.ROUTE_NAME,
                      arguments: arguments
                  );
                },
                child: FadeInImage.assetNetwork(
                    placeholder: UIConstants.NO_IMAGE,
                    image: this._photos[index],
                    imageCacheHeight: RestaurantImageCell._IMAGE_H,
                    imageCacheWidth: MediaQuery.of(context).size.width.toInt(),
                    placeholderCacheHeight: RestaurantImageCell._IMAGE_H,
                    placeholderCacheWidth:
                        MediaQuery.of(context).size.width.toInt(),
                    fit: BoxFit.fill,
                    width: MediaQuery.of(context).size.width / 3,
                    height: MediaQuery.of(context).size.width / 3),
              )
          )
      )
  );
}
