import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_restaruant/flow/main/bloc/MainBloc.dart';
import 'package:flutter_restaruant/manager/SignInManager.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';
import 'package:flutter_restaruant/utils/Dimens.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sprintf/sprintf.dart';

class RestaurantItemCell extends StatelessWidget {
  static const int IMAGE_H = 100;
  static const int IMAGE_W = 100;
  static const double ITEM_H = 100;

  final YelpRestaurantSummaryInfo _summaryInfo;
  final bool _isFavorPage;

  const RestaurantItemCell(
      { required YelpRestaurantSummaryInfo summaryInfo,
        required bool isFavorPage})
      : this._summaryInfo = summaryInfo,
        this._isFavorPage = isFavorPage;

  @override
  Widget build(BuildContext context) {
    String category = this._summaryInfo.categoriesStr;

    return SizedBox(
        height: 100,
        child: Container(
            padding: EdgeInsets.only(left: 10, right: 5, top: 10, bottom: 0),
            child: Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
              SizedBox(
                  width: RestaurantItemCell.IMAGE_W.toDouble(),
                  height: RestaurantItemCell.IMAGE_H.toDouble(),
                  child: FadeInImage.assetNetwork(
                      placeholder: UIConstants.NO_IMAGE,
                      imageErrorBuilder: (context, error, trace) =>
                          Image.asset(UIConstants.NO_IMAGE),
                      image: this._summaryInfo.image_url ?? "",
                      imageCacheHeight: RestaurantItemCell.IMAGE_H,
                      imageCacheWidth: RestaurantItemCell.IMAGE_W,
                      placeholderCacheHeight: RestaurantItemCell.IMAGE_H,
                      placeholderCacheWidth: RestaurantItemCell.IMAGE_W,
                      fit: BoxFit.fill)),
              Expanded(
                  child: Container(
                      padding: EdgeInsets.only(left: 10),
                      child: SizedBox(
                          height: RestaurantItemCell.ITEM_H,
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Flex(
                                    direction: Axis.horizontal,
                                    children: <Widget>[
                                      Expanded(
                                          child: Text(
                                              this._summaryInfo.name ?? "",
                                              overflow: TextOverflow.ellipsis)),
                                      Text(
                                          sprintf("%.2fm",
                                              [this._summaryInfo.distance]),
                                          style: TextStyle(
                                              fontSize: Dimens.mFontSize,
                                              color: Colors.grey))
                                    ]),
                                Flex(direction: Axis.horizontal, children: <
                                    Widget>[
                                  Expanded(
                                      child: this._summaryInfo.getRatingImage(
                                          this._summaryInfo.rating.toString()),
                                      flex: 1),
                                  Expanded(
                                      child: Align(
                                          child: Text(
                                              "${this._summaryInfo.review_count}則評論",
                                              style: TextStyle(
                                                  fontSize: Dimens.mFontSize,
                                                  color: Colors.grey)),
                                          alignment: Alignment.centerRight),
                                      flex: 1),
                                  Expanded(
                                      child: Align(
                                          child: Text(
                                              this._summaryInfo.price ?? "",
                                              style: TextStyle(
                                                  fontSize: Dimens.mFontSize,
                                                  color: Colors.grey)),
                                          alignment: Alignment.centerRight),
                                      flex: 1)
                                ]),
                                Text(
                                    this._summaryInfo.location?.display_address?.join("") ?? "",
                                    overflow: TextOverflow.ellipsis),
                                Row(
                                  children: <Widget>[
                                    Padding(padding: EdgeInsets.only(left: 5),
                                        child: Visibility(
                                          child: GestureDetector(
                                            child: Image.asset(
                                                (this._summaryInfo.favor)
                                                    ? "images/ic_favor_fill.png"
                                                    : "images/ic_favor_empty.png",
                                                width: UIConstants.FAVOR_IMAGE_W,
                                                height: UIConstants.FAVOR_IMAGE_H,
                                                fit: BoxFit.fill),
                                              onTap: () {
                                                MainBloc bloc = BlocProvider.of<MainBloc>(context);

                                                bloc.add(ToggleFavor(summaryInfo: this._summaryInfo));
                                            }),
                                          visible: !this._isFavorPage,
                                        )
                                    ),
                                    Padding(
                                        padding: EdgeInsets.only(left: 5, right: 5),
                                        child: Text(category,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: Dimens.mFontSize,
                                                color: Colors.grey))
                                    )
                                  ]
                                )
                              ])
                      )
                  )
              )
            ])
        )
    );
  }
}
