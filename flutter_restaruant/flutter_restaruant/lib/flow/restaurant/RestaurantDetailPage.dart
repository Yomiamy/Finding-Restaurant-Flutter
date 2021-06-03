import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/model/YelpRestaurantDetailInfo.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';
import 'package:flutter_restaruant/utils/Constants.dart';

class RestaurantDetailPage extends StatefulWidget {
  static const int IMAGE_H = 200;

  final YelpRestaurantDetailInfo detailInfo;

  const RestaurantDetailPage({required this.detailInfo});

  @override
  State<StatefulWidget> createState() => RestaurantDetailState();
}

class RestaurantDetailState extends State<RestaurantDetailPage> {
  // FIXME: Fake Data
  @override
  Widget build(BuildContext context) => PlatformScaffold(
      appBar: PlatformAppBar(
          leading: PlatformIconButton(
              onPressed: () => Navigator.of(context).pop(),
              materialIcon: Icon(Icons.arrow_back, color: Color(UIConstants.BackBtnColor)),
              cupertinoIcon: Icon(CupertinoIcons.back, color: Color(UIConstants.BackBtnColor))),
          title: Text("詳細資訊", style: TextStyle(color: Colors.white)),
          backgroundColor: Color(UIConstants.AppBarColor)),
      body: ListView(children: [
        FadeInImage.assetNetwork(
            placeholder: UIConstants.NO_IMAGE,
            image: widget.detailInfo.image_url ?? "",
            imageCacheHeight: RestaurantDetailPage.IMAGE_H,
            imageCacheWidth: MediaQuery.of(context).size.width.toInt(),
            placeholderCacheHeight: RestaurantDetailPage.IMAGE_H,
            placeholderCacheWidth: MediaQuery.of(context).size.width.toInt(),
            fit: BoxFit.fill,
            width: double.infinity,
            height: RestaurantDetailPage.IMAGE_H.toDouble())
      ]));
}
