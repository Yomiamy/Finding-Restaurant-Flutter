import 'package:flutter/material.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../features/foundation/constants/constants_barrel.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../rating_stars.dart';

class RestaurantCommentCell extends StatelessWidget {
  static const int _imageW = 100;
  static const int _imageH = 100;

  final List<ReviewDetailEntity> reviewInfos;
  final ChromeSafariBrowser _browser = ChromeSafariBrowser();

  RestaurantCommentCell({
    super.key = const Key('RestaurantCommentCell'),
    required this.reviewInfos,
  });

  Widget _createComment(
    BuildContext context, {
    required String headImgUrl,
    required String name,
    required Widget rateAsset,
    required String comment,
    required String commentUrl,
  }) => GestureDetector(
    onTap: () {
      debugPrint('Comment Url = $commentUrl');
      _browser.open(
        url: WebUri(commentUrl),
        settings: ChromeSafariBrowserSettings(barCollapsingEnabled: true),
      );
    },
    child: Padding(
      padding: const EdgeInsets.only(bottom: ThemeSize.space10),
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
              placeholderCacheHeight: RestaurantCommentCell._imageH,
              placeholderCacheWidth: RestaurantCommentCell._imageW,
              fit: BoxFit.fill,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: ThemeSize.space10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ThemeSize.size20, child: rateAsset),
                  Text(
                    comment, 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    List<Widget> commentWidgets = reviewInfos.map((reviewInfo) {
      String headImgUrl = reviewInfo.user?.imageUrl ?? '';
      String name = reviewInfo.user?.name ?? '';
      Widget rateAsset = RatingStars(
        rating: (reviewInfo.rating ?? 0).toDouble(),
      );
      String comment = reviewInfo.text ?? '';
      String commentUrl = reviewInfo.url ?? '';

      return _createComment(
        context,
        headImgUrl: headImgUrl,
        name: name,
        rateAsset: rateAsset,
        comment: comment,
        commentUrl: commentUrl,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(
        left: ThemeSize.space5,
        right: ThemeSize.space5,
        top: ThemeSize.space10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: commentWidgets,
      ),
    );
  }
}
