import 'package:flutter/material.dart';
import 'package:flutter_restaruant/utils/Dimens.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';

class RestaurantCommentCell extends StatelessWidget {

  static const int IMAGE_W = 100;
  static const int IMAGE_H = 100;
  static const double RATING_IMAGE_H = 20;

  const RestaurantCommentCell({Key? key = const Key("RestaurantCommentCell")}): super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.only(left: 5, right: 5, top: 10),
      child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        SizedBox(
            width: RestaurantCommentCell.IMAGE_H.toDouble(),
            height: RestaurantCommentCell.IMAGE_W.toDouble(),
            child: FadeInImage.assetNetwork(
                placeholder: UIConstants.NO_IMAGE,
                imageErrorBuilder: (context, error, trace) => Image.asset(UIConstants.NO_IMAGE),
                image: "https://staticmapmaker.com/img/google@2x.png",
                imageCacheHeight: RestaurantCommentCell.IMAGE_H,
                imageCacheWidth: RestaurantCommentCell.IMAGE_W,
                placeholderCacheHeight: RestaurantCommentCell.IMAGE_H,
                placeholderCacheWidth: RestaurantCommentCell.IMAGE_W,
                fit: BoxFit.fill)
        ),
        Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: RestaurantCommentCell.IMAGE_H.toDouble()),
              child: Container(
                  padding: EdgeInsets.only(left: 10),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text("User 1",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: Dimens.hFontSize),
                            overflow: TextOverflow.ellipsis),
                        Image.asset("images/Star_rating_2_of_5.png",
                            height: RestaurantCommentCell.RATING_IMAGE_H),
                        Text("食材新鮮好吃食材新鮮好吃食材新鮮好吃食材新鮮好吃食材新鮮好吃食材新鮮好吃",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis)
                      ]
                  )
              )
            )
        )
       ]
      )
  );
}
