import 'package:flutter/material.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';
import 'package:flutter_restaruant/utils/Constants.dart';
import 'package:flutter_restaruant/utils/Dimens.dart';

class RestaurantItemCell extends StatelessWidget {
  static const int IMAGE_H = 100;
  static const int IMAGE_W = 100;

  final String storeName;
  final String imgUrl;

  RestaurantItemCell({this.storeName = "", this.imgUrl = ""});

  @override
  Widget build(BuildContext context) => Container(
      padding: EdgeInsets.only(left: 10, right: 5, top: 10, bottom: 0),
      child: Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
        FadeInImage.assetNetwork(
            placeholder: UIConstants.NO_IMAGE,
            image: this.imgUrl,
            imageCacheHeight: RestaurantItemCell.IMAGE_H,
            imageCacheWidth: RestaurantItemCell.IMAGE_W,
            placeholderCacheHeight: RestaurantItemCell.IMAGE_H,
            placeholderCacheWidth: RestaurantItemCell.IMAGE_W,
            fit: BoxFit.fill,
            width: RestaurantItemCell.IMAGE_W.toDouble(),
            height: RestaurantItemCell.IMAGE_H.toDouble()),
        Expanded(
            child: Container(
                padding: EdgeInsets.only(left: 10),
                child: SizedBox(
                    height: 100,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Flex(direction: Axis.horizontal, children: <Widget>[
                            Expanded(
                                child: Text(this.storeName,
                                    overflow: TextOverflow.ellipsis)),
                            Text("250.1m",
                                style: TextStyle(
                                    fontSize: Dimens.mFontSize,
                                    color: Colors.grey))
                          ]),
                          Flex(direction: Axis.horizontal, children: <Widget>[
                            Expanded(
                                child: Image(
                                    image: AssetImage(
                                        "images/Star_rating_2_of_5.png"),
                                    height: 20),
                                flex: 1),
                            Expanded(
                                child: Align(
                                    child: Text("1則評論",
                                        style: TextStyle(
                                            fontSize: Dimens.mFontSize,
                                            color: Colors.grey)),
                                    alignment: Alignment.centerRight),
                                flex: 1),
                            Expanded(
                                child: Align(
                                    child: Text("\$\$",
                                        style: TextStyle(
                                            fontSize: Dimens.mFontSize,
                                            color: Colors.grey)),
                                    alignment: Alignment.centerRight),
                                flex: 1)
                          ]),
                          Text("235 新北市中和區中和路248號",
                              overflow: TextOverflow.ellipsis),
                          Text("餐廳",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: Dimens.mFontSize,
                                  color: Colors.grey))
                        ]))))
      ]));
}
