import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/model/YelpRestaurantDetailInfo.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';
import 'package:flutter_restaruant/utils/Constants.dart';

class RestaurantDetailPage extends StatefulWidget {
  static const int HEAD_IMAGE_H = 200;
  static const int MAP_IMAGE_W = 140;
  static const int MAP_IMAGE_H = 140;

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
              padding: EdgeInsets.all(0),
              onPressed: () => Navigator.of(context).pop(),
              materialIcon: Icon(Icons.arrow_back,
                  color: Color(UIConstants.BackBtnColor)),
              cupertinoIcon: Icon(CupertinoIcons.back,
                  color: Color(UIConstants.BackBtnColor))),
          title: Text(widget.detailInfo.name ?? "",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Color(UIConstants.AppBarColor)),
      body: ListView(children: [
        FadeInImage.assetNetwork(
            placeholder: UIConstants.NO_IMAGE,
            image: widget.detailInfo.image_url ?? "",
            imageCacheHeight: RestaurantDetailPage.HEAD_IMAGE_H,
            imageCacheWidth: MediaQuery.of(context).size.width.toInt(),
            placeholderCacheHeight: RestaurantDetailPage.HEAD_IMAGE_H,
            placeholderCacheWidth: MediaQuery.of(context).size.width.toInt(),
            fit: BoxFit.fill,
            width: double.infinity,
            height: RestaurantDetailPage.HEAD_IMAGE_H.toDouble()),
        Container(
            padding: EdgeInsets.only(left: 10, right: 5, top: 10, bottom: 0),
            child: Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
              SizedBox(
                  width: RestaurantDetailPage.MAP_IMAGE_H.toDouble(),
                  height: RestaurantDetailPage.MAP_IMAGE_W.toDouble(),
                  child: FadeInImage.assetNetwork(
                      placeholder: UIConstants.NO_IMAGE,
                      imageErrorBuilder: (context, error, trace) =>
                          Image.asset(UIConstants.NO_IMAGE),
                      image: "https://staticmapmaker.com/img/google@2x.png",
                      imageCacheHeight: RestaurantDetailPage.MAP_IMAGE_H,
                      imageCacheWidth: RestaurantDetailPage.MAP_IMAGE_W,
                      placeholderCacheHeight: RestaurantDetailPage.MAP_IMAGE_H,
                      placeholderCacheWidth: RestaurantDetailPage.MAP_IMAGE_W,
                      fit: BoxFit.fill)),
              Expanded(
                  child: Container(
                      padding: EdgeInsets.only(left: 10),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text("235 新北市中和區中和路238號1111111",
                                style: TextStyle(fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis),
                            Row(
                              children: <Widget>[
                                Text("電話:",
                                    style: TextStyle(fontWeight: FontWeight.w700)),
                                SizedBox(width: 10),
                                Text("+8860982736457", style: TextStyle(color: Colors.blue))
                              ]
                            ),
                            Text("餐廳", style: TextStyle(color: Colors.grey)),
                            Image.asset("images/Star_rating_2_of_5.png", height: 20),
                            Text("1則評論", style: TextStyle(color: Colors.grey)),
                            DecoratedBox(
                                decoration: BoxDecoration(color: Colors.red, shape: BoxShape.rectangle, borderRadius: BorderRadius.all(Radius.circular(15.0))),

                                child: Padding(padding: EdgeInsets.all(3), child: Text("close", style: TextStyle(color: Colors.white)))
                            )
                          ]
                      )
                  )
               )
              ]
            )
        Container(
          padding: EdgeInsets.only(left: 5, right: 5, top: 10, bottom: 0),
          height: MediaQuery.of(context).size.width / 3,
          child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: FadeInImage.assetNetwork(
                    placeholder: UIConstants.NO_IMAGE,
                    image: widget.detailInfo.image_url ?? "",
                    imageCacheHeight: RestaurantDetailPage.HEAD_IMAGE_H,
                    imageCacheWidth: MediaQuery.of(context).size.width.toInt(),
                    placeholderCacheHeight: RestaurantDetailPage.HEAD_IMAGE_H,
                    placeholderCacheWidth: MediaQuery.of(context).size.width.toInt(),
                    fit: BoxFit.fill,
                    width: MediaQuery.of(context).size.width / 3,
                    height: MediaQuery.of(context).size.width / 3),
              )
          )
        )
        ]
      )
  );
}


