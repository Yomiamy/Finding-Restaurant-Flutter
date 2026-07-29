import 'package:flutter/material.dart';
import '../../../domain/entities/review_detail_entity.dart';
import '../../../utils/rating_helper.dart';
import '../../../utils/ui_constants.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class RestaurantCommentCell extends StatelessWidget {
  static const int _imageW = 100;
  static const int _imageH = 100;
  static const double _ratingImageH = 20;

  final List<Widget> _commentWidgets = <Widget>[];
  final ChromeSafariBrowser _browser = ChromeSafariBrowser();

  RestaurantCommentCell(
      {super.key = const Key('RestaurantCommentCell'),
      required List<ReviewDetailEntity> reviewInfos}) {
    _initBusinessTimeWidgets(reviewInfos);
  }

  void _initBusinessTimeWidgets(List<ReviewDetailEntity> reviewInfos) {
    for (var reviewInfo in reviewInfos) {
      String headImgUrl = reviewInfo.user?.imageUrl ?? '';
      String name = reviewInfo.user?.name ?? '';
      Widget rateAsset =
          RatingHelper.getRatingImage(reviewInfo.rating?.toString());
      String comment = reviewInfo.text ?? '';
      String commentUrl = reviewInfo.url ?? '';

      Widget commentWidget = createComment(
          headImgUrl: headImgUrl,
          name: name,
          rateAsset: rateAsset,
          comment: comment,
          commentUrl: commentUrl);
      _commentWidgets.add(commentWidget);
    }
  }

  Widget createComment(
          {required String headImgUrl,
          required String name,
          required Widget rateAsset,
          required String comment,
          required String commentUrl}) =>
      GestureDetector(
          onTap: () {
            debugPrint('Comment Url = $commentUrl');
            _browser.open(
                url: WebUri(commentUrl),
                settings: ChromeSafariBrowserSettings(barCollapsingEnabled: true));
          },
          child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                        width: RestaurantCommentCell._imageH.toDouble(),
                        height: RestaurantCommentCell._imageW.toDouble(),
                        child: FadeInImage.assetNetwork(
                            placeholder: UIConstants.noImage,
                            imageErrorBuilder: (context, error, trace) =>
                                Image.asset(UIConstants.noImage),
                            image: headImgUrl,
                            imageCacheHeight: RestaurantCommentCell._imageH,
                            imageCacheWidth: RestaurantCommentCell._imageW,
                            placeholderCacheHeight:
                                RestaurantCommentCell._imageH,
                            placeholderCacheWidth:
                                RestaurantCommentCell._imageW,
                            fit: BoxFit.fill)),
                    Expanded(
                        child: Container(
                            padding: const EdgeInsets.only(left: 10),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: UIConstants.hFontSize),
                                      overflow: TextOverflow.ellipsis),
                                  SizedBox(
                                      height:
                                          RestaurantCommentCell._ratingImageH,
                                      child: rateAsset),
                                  Text(comment,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis)
                                ])))
                  ])));

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(left: 5, right: 5, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _commentWidgets,
      ));
}
