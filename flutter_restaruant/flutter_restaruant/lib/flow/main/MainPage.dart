import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/component/RestaurantItemCell.dart';
import 'package:flutter_restaruant/flow/restaurant/RestaurantDetailPage.dart';
import 'package:flutter_restaruant/model/YelpRestaurantDetailInfo.dart';
import 'package:flutter_restaruant/utils/Dimens.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';

class MainPage extends StatefulWidget {
  final String title;

  // FIXME: Fake Data
  final List<String> storeInfos = [
    "餐廳1::https://image.cache.storm.mg/styles/smg-800x533-fp/s3/media/image/2018/10/19/20181019-122810_U9180_M464177_c0e4.jpg?itok=S8YLNR-e",
    "餐廳2::https://cc.tvbs.com.tw/img/upload/2017/09/25/20170925181718-1e31b17d.jpg",
    "餐廳3::https://maiimage.com/wp-content/uploads/pixnet/ee2eca4d39d2ed559661c32ba972b56f.jpg",
    "餐廳4::https://d1ralsognjng37.cloudfront.net/08d41588-3cae-400b-87d2-9cebbd8831f3.jpeg",
    "餐廳5::https://img.letsplay.tw/uploads/20190320221450_55.jpg",
    "餐廳6::https://www.beautimode.com/upload/media/acf26f51e2c55fe379c2e2790db0c029.jpg"
  ];

  MainPage({Key key = const Key("MainPage"),  this.title = ""}) : super(key: key);

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    Widget title = Text(this.widget.title,
        style: TextStyle(color: Colors.white, fontSize: Dimens.xxxxhFontSize));

    return PlatformScaffold(
        body: NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool isBoxIsScrolled) =>
          <Widget>[
        CupertinoSliverNavigationBar(
            largeTitle: title, backgroundColor: Color(UIConstants.AppBarColor))
      ],
      body: ListView.builder(
          padding: EdgeInsets.only(top: 0, bottom: 0),
          itemExtent: RestaurantItemCell.IMAGE_H.toDouble(),
          cacheExtent: RestaurantItemCell.IMAGE_H.toDouble(),
          itemCount: this.widget.storeInfos.length,
          itemBuilder: (context, index) {
            String storeInfo = this.widget.storeInfos[index];
            List<String> infos = storeInfo.split("::");

            return GestureDetector(
                child: RestaurantItemCell(storeName: infos[0], imgUrl: infos[1]),
                onTap: () {
                  Navigator.of(context).push(platformPageRoute(context: context, builder: (context) {
                    // FIXME: TBD
                    YelpRestaurantDetailInfo detailInfo = YelpRestaurantDetailInfo();
                    detailInfo.image_url = "https://image.cache.storm.mg/styles/smg-800x533-fp/s3/media/image/2018/10/19/20181019-122810_U9180_M464177_c0e4.jpg?itok=S8YLNR-e";
                    return RestaurantDetailPage(detailInfo: detailInfo);
                  }));
                });
          }),
    ));
  }
}
