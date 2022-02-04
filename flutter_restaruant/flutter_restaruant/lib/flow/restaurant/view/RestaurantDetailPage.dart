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
    final args = ModalRoute.of(context)!.settings.arguments as Tuple2<String, dynamic>;
    final id = args.item1;

    RestaurantDetailBloc bloc = BlocProvider.of<RestaurantDetailBloc>(context);
    bloc.add(FetchDetailInfo(id: id));
    return PlatformScaffold(
        appBar: PlatformAppBar(
            leading: PlatformIconButton(
                padding: EdgeInsets.all(0),
                onPressed: () => Navigator.of(context).pop(),
                materialIcon: Icon(Icons.arrow_back,
                    color: Color(UIConstants.BackBtnColor)),
                cupertinoIcon: Icon(CupertinoIcons.back,
                    color: Color(UIConstants.BackBtnColor))),
            title: BlocBuilder<RestaurantDetailBloc, RestaurantDetailState> (
              bloc: bloc,
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
            backgroundColor: Color(UIConstants.AppBarColor)
        ),
        body: Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: BlocBuilder<RestaurantDetailBloc, RestaurantDetailState> (
                bloc: bloc,
              builder: (context, state) {
                if (state is InProgress) {
                  return Center(child: LoadingWidget());
                } else if(state is Success) {
                  return ListView(children: [
                    RestaurantHeadCell(imageUrl: state.detailInfo.image_url ?? ""),
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
