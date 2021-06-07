import 'package:flutter/cupertino.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';

class RestaurantHeadCell extends StatelessWidget {

  static const int HEAD_IMAGE_H = 200;

  final String _imageUrl;

  const RestaurantHeadCell({Key? key = const Key("RestaurantHeadCell"), required String imageUrl}) : this._imageUrl = imageUrl, super(key: key);

  @override
  Widget build(BuildContext context) => FadeInImage.assetNetwork(
      placeholder: UIConstants.NO_IMAGE,
      image: this._imageUrl,
      imageCacheHeight: RestaurantHeadCell.HEAD_IMAGE_H,
      imageCacheWidth: MediaQuery.of(context).size.width.toInt(),
      placeholderCacheHeight: RestaurantHeadCell.HEAD_IMAGE_H,
      placeholderCacheWidth: MediaQuery.of(context).size.width.toInt(),
      fit: BoxFit.fill,
      width: MediaQuery.of(context).size.width,
      height: RestaurantHeadCell.HEAD_IMAGE_H.toDouble()
  );
}
