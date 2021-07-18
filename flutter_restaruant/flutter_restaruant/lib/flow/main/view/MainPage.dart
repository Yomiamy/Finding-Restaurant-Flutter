import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/component/EmptyDataWidget.dart';
import 'package:flutter_restaruant/component/LoadingWidget.dart';
import 'package:flutter_restaruant/component/cell/main_page/RestaurantItemCell.dart';
import 'package:flutter_restaruant/flow/filter/view/FilterPage.dart';
import 'package:flutter_restaruant/flow/restaurant/view/RestaurantDetailPage.dart';
import 'package:flutter_restaruant/model/YelpRestaurantDetailInfo.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/utils/Dimens.dart';
import 'package:flutter_restaruant/utils/Tuple.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';
import '../bloc/MainBloc.dart';

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
        body: Stack(
          children: <Widget>[
            NestedScrollView(
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
                                    String id = summaryInfo.id ?? "";
                                    Tuple2 arguments = Tuple2<String, dynamic>(id, null);

                                    Navigator.of(context).pushNamed(RestaurantDetailPage.ROUTE_NAME, arguments: arguments);
                                  });
                            });
                      } else if(state is InProgress) {
                        return Center(child: LoadingWidget(text: "Loading..."));
                      } else {
                        return EmptyDataWidget();
                      }
                    }
                )
            ),
            Align(
              alignment: Alignment.bottomRight,
              child:ElevatedButton(
                  child: Icon(Icons.archive),
                  onPressed: () async {
                    Tuple3<int, int, int> arguments = Tuple3<int, int, int>(0, 0, 0);
                    Tuple3<int, int, int> result = (await Navigator.of(context).pushNamed(FilterPage.ROUTE_NAME, arguments: arguments)) as Tuple3<int, int, int>;

                    debugPrint("_priceLevelIndex = ${result.item1}, _sortingRulIndex = ${result.item2}, _businessTime = ${result.item3}");
                  }
              )
            )
          ]
        )
    );
  }
}
