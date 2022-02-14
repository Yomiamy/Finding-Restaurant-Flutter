import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/component/EmptyDataWidget.dart';
import 'package:flutter_restaruant/component/LoadingWidget.dart';
import 'package:flutter_restaruant/component/cell/main_page/RestaurantItemCell.dart';
import 'package:flutter_restaruant/flow/favor/bloc/FavorBloc.dart';
import 'package:flutter_restaruant/flow/restaurant/view/RestaurantDetailPage.dart';
import 'package:flutter_restaruant/manager/SignInManager.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/utils/Dimens.dart';
import 'package:flutter_restaruant/utils/Tuple.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';

class FavorPage extends StatefulWidget {
  static const ROUTE_NAME = "/FavorPage";

  const FavorPage({Key? key}) : super(key: key);

  @override
  _FavorPageState createState() => _FavorPageState();
}

class _FavorPageState extends State<FavorPage> {

  @override
  Widget build(BuildContext context) {
    FavorBloc bloc = BlocProvider.of<FavorBloc>(context);

    bloc.add(FetchFavorInfoEvent(false));
    return PlatformScaffold(
        appBar: PlatformAppBar(
            leading: PlatformIconButton(
                padding: EdgeInsets.all(0),
                onPressed: () => Navigator.of(context).pop(),
                materialIcon: Icon(Icons.arrow_back,
                    color: Color(UIConstants.BACK_BTN_COLOR)),
                cupertinoIcon: Icon(CupertinoIcons.back,
                    color: Color(UIConstants.BACK_BTN_COLOR))),
            title: Text(UIConstants.FAVOR_TITLE,
                style: TextStyle(
                color: Colors.white,
                fontSize: Dimens.xxxxhFontSize)),
            backgroundColor: Color(UIConstants.APP_PRIMARY_COLOR)),
        body: BlocBuilder<FavorBloc, FavorState>(
            bloc: bloc,
            builder: (context, state) {
              if (state is InProgress) {
                return Center(child: LoadingWidget());
              } else if (state is Success) {
                List<YelpRestaurantSummaryInfo> favorInfos = state.favorInfos;

                return ListView.builder(
                    padding: EdgeInsets.only(top: 0, bottom: 0),
                    itemCount: favorInfos.length,
                    itemBuilder: (context, index) {
                      YelpRestaurantSummaryInfo favorInfo = favorInfos[index];

                      return GestureDetector(
                          child: RestaurantItemCell(summaryInfo: favorInfo),
                          onTap: () async {
                            Tuple2 arguments = Tuple2<YelpRestaurantSummaryInfo, dynamic>(favorInfo, null);
                            await Navigator.of(context).pushNamed(RestaurantDetailPage.ROUTE_NAME, arguments: arguments);

                            bloc.add(FetchFavorInfoEvent(true));
                          });
                    });
              } else {
                return EmptyDataWidget();
              }
            }));
  }
}
