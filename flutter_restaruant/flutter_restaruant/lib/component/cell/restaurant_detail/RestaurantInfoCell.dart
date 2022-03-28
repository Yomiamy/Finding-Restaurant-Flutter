import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaruant/model/YelpRestaurantDetailInfo.dart';
import 'package:flutter_restaruant/utils/Constants.dart';
import 'package:flutter_restaruant/utils/Dimens.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';
import 'package:flutter_restaruant/utils/Utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RestaurantInfoCell extends StatelessWidget {

  static const int _MAP_IMAGE_W = 140;
  static const int _MAP_IMAGE_H = 140;

  final YelpRestaurantDetailInfo _detailInfo;
  final String staticMapUrl;

  const RestaurantInfoCell(
      {Key? key = const Key("RestaurantImageCell"),
      required YelpRestaurantDetailInfo detailInfo,
      required this.staticMapUrl})
      : this._detailInfo = detailInfo,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    String category = this
            ._detailInfo
            .categories
            ?.map((category) => category.title ?? "")
            .join(" ") ?? "";
    String openStatus = (this._detailInfo.hours?[0].is_open_now ?? false) ? "OPEN" : "CLOSE";

    return Padding(
        padding: EdgeInsets.only(left: 5, right: 5, top: 10),
        child: Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
          SizedBox(
              width: RestaurantInfoCell._MAP_IMAGE_H.toDouble(),
              height: RestaurantInfoCell._MAP_IMAGE_W.toDouble(),
              child: GestureDetector(
                  onTap: () {
                    showCupertinoModalPopup(
                        context: context, builder: buildNavigationActionSheet);
                  },
                  child: FadeInImage.assetNetwork(
                      placeholder: UIConstants.NO_IMAGE,
                      imageErrorBuilder: (context, error, trace) =>
                          Image.asset(UIConstants.NO_IMAGE),
                      image: this.staticMapUrl,
                      imageCacheHeight: RestaurantInfoCell._MAP_IMAGE_H,
                      imageCacheWidth: RestaurantInfoCell._MAP_IMAGE_W,
                      placeholderCacheHeight: RestaurantInfoCell._MAP_IMAGE_H,
                      placeholderCacheWidth: RestaurantInfoCell._MAP_IMAGE_W,
                      fit: BoxFit.fill))),
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
                          Text(AppLocalizations?.of(context)?.store_phone ?? "",
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
                        Text("${this._detailInfo.review_count}${AppLocalizations?.of(context)?.review_count_suffix ?? ""}",
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
                                child: Text(openStatus,
                                    style: TextStyle(
                                        fontSize: Dimens.lFontSize,
                                        color: Colors.white
                                    ))))
                      ])))
        ]));
  }

  CupertinoActionSheet buildNavigationActionSheet(BuildContext context) =>
      CupertinoActionSheet(
          title: Text(AppLocalizations?.of(context)?.navigation_choice ?? ""),
          cancelButton: CupertinoActionSheetAction(
              isDestructiveAction: true,
              child: Text(AppLocalizations?.of(context)?.cancel ?? ""),
              onPressed: () {
                Navigator.pop(context);
              }),
          actions: [
            CupertinoActionSheetAction(
                child: Text(AppLocalizations?.of(context)?.route_navigation ?? ""),
                onPressed: () {
                  double lat = this._detailInfo.coordinates?.latitude ?? 0;
                  double lng = this._detailInfo.coordinates?.longitude ?? 0;

                  Utils.openUrl(
                      scheme: Constants.HTTPS_SCHEME,
                      host: Constants.GOOGLE_MAP_HOST,
                      path: Constants.GOOGLE_MAP_NAVIGATION_PATH, parameters: <String, String> {
                        Constants.GOOGLE_MAP_NAVIGATION_LATLNG : sprintf("%f,%f", [lat, lng]),
                  });
                  Navigator.pop(context);
                }),
            CupertinoActionSheetAction(
                isDefaultAction: false,
                child: Text(AppLocalizations?.of(context)?.street_view ?? ""),
                onPressed: () {
                  double lat = this._detailInfo.coordinates?.latitude ?? 0;
                  double lng = this._detailInfo.coordinates?.longitude ?? 0;

                  Utils.openUrl(
                      scheme: Constants.HTTPS_SCHEME,
                      host: Constants.GOOGLE_MAP_HOST,
                      path: Constants.GOOGLE_MAP_NAVIGATION_PATH, parameters: <String, String> {
                        Constants.GOOGLE_MAP_NAVIGATION_LATLNG : "",
                        Constants.GOOGLE_MAP_STREETVIEW_LAYER : "c",
                        Constants.GOOGLE_MAP_STREETVIEW_LATLNG : sprintf("%f,%f", [lat, lng])
                  });
                  Navigator.pop(context);
                })
          ]);
}
