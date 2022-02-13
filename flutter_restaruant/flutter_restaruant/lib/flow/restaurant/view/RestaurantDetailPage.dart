import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/component/EmptyDataWidget.dart';
import 'package:flutter_restaruant/component/LoadingWidget.dart';
import 'package:flutter_restaruant/component/ad/InterstitialAD.dart';
import 'package:flutter_restaruant/component/ad/InterstitialADState.dart';
import 'package:flutter_restaruant/component/cell/restaurant_detail/RestaurantDetailCellCollection.dart';
import 'package:flutter_restaruant/model/YelpRestaurantDetailInfo.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/utils/Dimens.dart';
import 'package:flutter_restaruant/utils/Tuple.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';
import '../bloc/RestaurantDetailBloc.dart';

class RestaurantDetailPage extends StatefulWidget {

  static const ROUTE_NAME = "/RestaurantDetailPage";

  const RestaurantDetailPage();

  @override
  State<StatefulWidget> createState() => RestaurantDetailPageState();
}

class RestaurantDetailPageState extends State<RestaurantDetailPage> {

  late YelpRestaurantSummaryInfo _summaryInfo;
  late RestaurantDetailBloc _bloc;

  @override
  void initState() {
    super.initState();

    if(--UIConstants.InterstitialADCountDown <= 0) {
      UIConstants.InterstitialADCountDown = 3;

      // iOS DetailPage才有全屏AD
      IntersitialAD(adState: InterstitialADState()).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Tuple2<YelpRestaurantSummaryInfo, dynamic>;
    this._summaryInfo = args.item1;
    this._bloc = BlocProvider.of<RestaurantDetailBloc>(context);

    this._bloc.add(FetchDetailInfo(id: this._summaryInfo.id!));
    return PlatformScaffold(
        appBar: PlatformAppBar(
            leading: PlatformIconButton(
                padding: EdgeInsets.all(0),
                onPressed: () => Navigator.of(context).pop(),
                materialIcon: Icon(Icons.arrow_back,
                    color: Color(UIConstants.BACK_BTN_COLOR)),
                cupertinoIcon: Icon(CupertinoIcons.back,
                    color: Color(UIConstants.BACK_BTN_COLOR))),
            title: BlocBuilder<RestaurantDetailBloc, RestaurantDetailState> (
              bloc: this._bloc,
              builder: (context, state) {
                if(state is Success) {
                  return Text(state.detailInfo.name ?? "",
                          style: TextStyle(
                          color: Colors.white,
                          fontSize: Dimens.xxxhFontSize
                      ));
                } else {
                  return Text("");
                }
              }
            ),
            backgroundColor: Color(UIConstants.APP_PRIMARY_COLOR)
        ),
        body: Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: BlocBuilder<RestaurantDetailBloc, RestaurantDetailState> (
                bloc: this._bloc,
              builder: (context, state) {
                if (state is InProgress || state is ToggleFavorSuccess) {
                  if(state is ToggleFavorSuccess) {
                    // Re-fetch detail and build detail page
                    this._bloc.add(FetchDetailInfo(id: this._summaryInfo.id!));
                  }
                  return Center(child: LoadingWidget());
                } else if(state is Success) {
                  return ListView(children: [
                    Stack(
                      children: <Widget>[
                        RestaurantHeadCell(imageUrl: state.detailInfo.image_url ?? ""),
                        StatefulBuilder(builder: (context, setState) {
                          return GestureDetector(
                              onTap: () {
                                this._bloc.add(ToggleFavor(summaryInfo: this._summaryInfo));
                              },
                              child: Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                      padding: EdgeInsets.only(top:10, right: 10),
                                      child: CircleAvatar(
                                          backgroundColor: Colors.white,
                                          child: Image.asset(
                                              this._summaryInfo.favor
                                                  ? "images/ic_favor_fill.png"
                                                  : "images/ic_favor_empty.png",
                                              width: UIConstants.FAVOR_IMAGE_W,
                                              height: UIConstants.FAVOR_IMAGE_H,
                                              fit: BoxFit.fill)
                                      )
                                  )
                              )
                          );
                        })
                      ]
                    ),
                    RestaurantInfoCell(detailInfo: state.detailInfo, staticMapUrl: state.staticMapUrl),
                    RestaurantImageCell(photos: state.detailInfo.photos ?? []),
                    RestaurantBusinessHourCell(businessTimeInfos: state.detailInfo.hours?[0].open ?? []),
                    RestaurantCommentCell(reviewInfos: state.reviewInfo.reviews ?? [])
                  ]);
                } else {
                  return EmptyDataWidget();
                }
              }
            )
        ));
  }
}
