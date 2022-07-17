import 'package:flutter/material.dart';
import 'package:flutter_restaruant/model/YelpReviewDetailInfo.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class RestaurantCommentCell extends StatelessWidget {

  static const int _IMAGE_W = 100;
  static const int _IMAGE_H = 100;
  static const double _RATING_IMAGE_H = 20;

  final List<Widget> _commentWidgets = <Widget>[];
  final ChromeSafariBrowser _browser = ChromeSafariBrowser();

  RestaurantCommentCell({Key? key = const Key("RestaurantCommentCell"), required List<YelpReviewDetailInfo> reviewInfos}): super(key: key) {
    this._initBusinessTimeWidgets(reviewInfos);
  }

  void _initBusinessTimeWidgets(List<YelpReviewDetailInfo> reviewInfos) {
    reviewInfos.forEach((reviewInfo) {
      String headImgUrl = reviewInfo.user?.image_url ?? "";
      String name = reviewInfo.user?.name ?? "";
      Image rateAsset = reviewInfo.getRatingImage(reviewInfo.rating?.toString() ?? "");
      String comment = reviewInfo.text ?? "";
      String commentUrl = reviewInfo.url ?? "";

      Widget commentWidget = this.createComment(
          headImgUrl: headImgUrl,
          name: name,
          rateAsset: rateAsset,
          comment: comment,
          commentUrl: commentUrl);
      this._commentWidgets.add(commentWidget);
    });
  }

  Widget createComment(
          {required String headImgUrl,
          required String name,
          required Image rateAsset,
          required String comment,
          required String commentUrl}) =>
      GestureDetector(
          onTap: () {
            debugPrint("Comment Url = $commentUrl");
            this._browser.open(
                url: Uri.parse(commentUrl),
                options: ChromeSafariBrowserClassOptions(
                    android: AndroidChromeCustomTabsOptions(),
                    ios: IOSSafariOptions(barCollapsingEnabled: true)
                )
            );
          },
          child: Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                        width: RestaurantCommentCell._IMAGE_H.toDouble(),
                        height: RestaurantCommentCell._IMAGE_W.toDouble(),
                        child: FadeInImage.assetNetwork(
                            placeholder: UIConstants.NO_IMAGE,
                            imageErrorBuilder: (context, error, trace) =>
                                Image.asset(UIConstants.NO_IMAGE),
                            image: headImgUrl,
                            imageCacheHeight: RestaurantCommentCell._IMAGE_H,
                            imageCacheWidth: RestaurantCommentCell._IMAGE_W,
                            placeholderCacheHeight:
                                RestaurantCommentCell._IMAGE_H,
                            placeholderCacheWidth:
                                RestaurantCommentCell._IMAGE_W,
                            fit: BoxFit.fill)),
                    Expanded(
                        child: Container(
                            padding: EdgeInsets.only(left: 10),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: UIConstants.hFontSize),
                                      overflow: TextOverflow.ellipsis),
                                  SizedBox(
                                      height:
                                          RestaurantCommentCell._RATING_IMAGE_H,
                                      child: rateAsset),
                                  Text(comment,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis)
                                ])))
                  ])));

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.only(left: 5, right: 5, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: this._commentWidgets,
      )
  );
}
