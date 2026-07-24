import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/component/empty_data_widget.dart';
import 'package:flutter_restaruant/component/loading_widget.dart';
import 'package:flutter_restaruant/component/cell/main_page/restaurant_item_cell.dart';
import 'package:flutter_restaruant/flow/favor/bloc/favor_bloc.dart';
import 'package:flutter_restaruant/flow/restaurant/view/restaurant_detail_page.dart';
import 'package:flutter_restaruant/model/yelp_restaurant_summary_info.dart';
import 'package:flutter_restaruant/utils/tuple.dart';
import 'package:flutter_restaruant/utils/ui_constants.dart';
import 'package:flutter_restaruant/gen/colors.gen.dart';

class FavorPage extends StatefulWidget {
  static const ROUTE_NAME = "/FavorPage";

  const FavorPage({Key? key}) : super(key: key);

  @override
  _FavorPageState createState() => _FavorPageState();
}

class _FavorPageState extends State<FavorPage> {
  late FavorBloc _favorBloc;

  @override
  void initState() {
    super.initState();

    this._favorBloc = BlocProvider.of<FavorBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    this._favorBloc.add(FetchFavorInfoEvent(false));

    return Scaffold(
        appBar: AppBar(
            leading: PlatformIconButton(
                padding: EdgeInsets.all(0),
                onPressed: () => Navigator.of(context).pop(),
                materialIcon: Icon(Icons.arrow_back,
                    color: ColorName.backBtnColor),
                cupertinoIcon: Icon(CupertinoIcons.back,
                    color: ColorName.backBtnColor)),
            title: Text(UIConstants.FAVOR_TITLE,
                style: TextStyle(
                    color: Colors.white, fontSize: UIConstants.xxxxhFontSize)),
            backgroundColor: ColorName.appPrimaryColor),
        body: BlocBuilder<FavorBloc, FavorState>(
            bloc: this._favorBloc,
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
                            Tuple2 arguments =
                                Tuple2<YelpRestaurantSummaryInfo, dynamic>(
                                    favorInfo, null);
                            await Navigator.of(context).pushNamed(
                                RestaurantDetailPage.ROUTE_NAME,
                                arguments: arguments);

                            this._favorBloc.add(FetchFavorInfoEvent(true));
                          });
                    });
              } else {
                return EmptyDataWidget();
              }
            }));
  }
}
