import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/component/cell/main_page/RestaurantItemCell.dart';
import 'package:flutter_restaruant/flow/restaurant/RestaurantDetailPage.dart';
import 'package:flutter_restaruant/model/YelpRestaurantDetailInfo.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/model/YelpSearchInfo.dart';
import 'package:flutter_restaruant/utils/Dimens.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';

import 'bloc/MainBloc.dart';

class MainPage extends StatefulWidget {
  final String title;

  MainPage({Key key = const Key("MainPage"),  this.title = ""}) : super(key: key);

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {

  MainPageState();

  @override
  Widget build(BuildContext context) {
    Widget title = Text(this.widget.title,
        style: TextStyle(color: Colors.white, fontSize: Dimens.xxxxhFontSize));

    BlocProvider.of<MainBloc>(context).add(FetchSearchInfo());

    return PlatformScaffold(
        body: NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool isBoxIsScrolled) =>
          <Widget>[
        CupertinoSliverNavigationBar(
            largeTitle: title, backgroundColor: Color(UIConstants.AppBarColor))
      ],
      body: BlocBuilder<MainBloc, MainState>(
        builder: (context, state) {
          if(state is Success) {
            return ListView.builder(
                padding: EdgeInsets.only(top: 0, bottom: 0),
                itemExtent: RestaurantItemCell.IMAGE_H.toDouble(),
                cacheExtent: RestaurantItemCell.IMAGE_H.toDouble(),
                itemCount: state.searchInfo.businesses?.length ?? 0 ,
                itemBuilder: (context, index) {
                  YelpRestaurantSummaryInfo summaryInfo = state.searchInfo.businesses?[index] ?? YelpRestaurantSummaryInfo();

                  return GestureDetector(
                      child: RestaurantItemCell(summaryInfo: summaryInfo),
                      onTap: () {
                        Navigator.of(context).push(platformPageRoute(context: context, builder: (context) {
                          // FIXME: TBD
                          YelpRestaurantDetailInfo detailInfo = YelpRestaurantDetailInfo();
                          detailInfo.image_url = "https://image.cache.storm.mg/styles/smg-800x533-fp/s3/media/image/2018/10/19/20181019-122810_U9180_M464177_c0e4.jpg?itok=S8YLNR-e";
                          return RestaurantDetailPage(detailInfo: detailInfo);
                        }));
                      });
                });
          } else if(state is InProgress) {
            return Center(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget> [
                  CircularProgressIndicator(),
                  Text("Loading...")
                ]
              )
            );
          } else {
            return Center(child: Text("No Data.",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize:  Dimens.hFontSize)
              )
            );
          }
        }
      )
    ));
  }
}
