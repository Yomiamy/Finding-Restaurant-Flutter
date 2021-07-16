import 'package:flutter/material.dart';
import 'package:flutter_restaruant/model/YelpRestaurantDetailInfo.dart';
import 'package:flutter_restaruant/utils/Dimens.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';

class RestaurantInfoCell extends StatelessWidget {

  static const int MAP_IMAGE_W = 140;
  static const int MAP_IMAGE_H = 140;

  final YelpRestaurantDetailInfo _detailInfo;
  final String staticMapUrl;

  const RestaurantInfoCell({Key? key = const Key("RestaurantImageCell"),
    required YelpRestaurantDetailInfo detailInfo,
    required this.staticMapUrl}) : this._detailInfo = detailInfo,  super(key: key);

  @override
  Widget build(BuildContext context) {
    String category = this._detailInfo.categories?.map((category) => category.title ?? "").join(" ") ?? "";

    return Padding(
        padding: EdgeInsets.only(left: 5, right: 5, top: 10),
        child: Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
          SizedBox(
              width: RestaurantInfoCell.MAP_IMAGE_H.toDouble(),
              height: RestaurantInfoCell.MAP_IMAGE_W.toDouble(),
              child: FadeInImage.assetNetwork(
                  placeholder: UIConstants.NO_IMAGE,
                  imageErrorBuilder: (context, error, trace) =>
                      Image.asset(UIConstants.NO_IMAGE),
                  image: this.staticMapUrl,
                  imageCacheHeight: RestaurantInfoCell.MAP_IMAGE_H,
                  imageCacheWidth: RestaurantInfoCell.MAP_IMAGE_W,
                  placeholderCacheHeight: RestaurantInfoCell.MAP_IMAGE_H,
                  placeholderCacheWidth: RestaurantInfoCell.MAP_IMAGE_W,
                  fit: BoxFit.fill)),
          Expanded(
              child: Container(
                  padding: EdgeInsets.only(left: 10),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                            this._detailInfo.location?.display_address?.join("") ?? "",
                            style: TextStyle(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                        Row(children: <Widget>[
                          Text("電話:",
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(width: 10),
                          Text(this._detailInfo.phone ?? "",
                              style: TextStyle(color: Colors.blue))
                        ]),
                        Text(category,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey)),
                        this
                            ._detailInfo
                            .getRatingImage(this._detailInfo.rating.toString()),
                        Text("${this._detailInfo.review_count}則評論",
                            style: TextStyle(
                                fontSize: Dimens.mFontSize,
                                color: Colors.grey)),
                        DecoratedBox(
                            decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15.0))),
                            child: Padding(
                                padding: EdgeInsets.all(3),
                                child: Text("close",
                                    style: TextStyle(color: Colors.white))))
                      ])))
        ]));
  }
}
