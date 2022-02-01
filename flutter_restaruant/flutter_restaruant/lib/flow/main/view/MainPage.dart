import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/component/EmptyDataWidget.dart';
import 'package:flutter_restaruant/component/ExpandableFabButton.dart';
import 'package:flutter_restaruant/component/LoadingWidget.dart';
import 'package:flutter_restaruant/component/ad/BannerADState.dart';
import 'package:flutter_restaruant/component/ad/BannerAD.dart';
import 'package:flutter_restaruant/component/cell/main_page/RestaurantItemCell.dart';
import 'package:flutter_restaruant/flow/filter/view/FilterPage.dart';
import 'package:flutter_restaruant/flow/restaurant/view/RestaurantDetailPage.dart';
import 'package:flutter_restaruant/model/FilterConfigs.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:provider/provider.dart';
import 'package:flutter_restaruant/utils/Dimens.dart';
import 'package:flutter_restaruant/utils/Tuple.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../bloc/MainBloc.dart';
import 'FilterTagsWidget.dart';

class MainPage extends StatefulWidget {

  static const ROUTE_NAME = "/MainPage";

  MainPage({Key key = const Key("MainPage")}) : super(key: key);

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {

  FilterConfigs _configs = FilterConfigs();
  ScrollController _scrollController = ScrollController();
  String _filterKeyword = "";
  late MainBloc _mainBloc;

  MainPageState();

  @override
  void initState() {
    super.initState();

    this._mainBloc = BlocProvider.of<MainBloc>(context);
  }

  @override
  void didUpdateWidget(covariant MainPage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void _clearAndFeach() {
    int? price = this._configs.price;
    int? openAt = this._configs.openAt;
    String? sortBy = this._configs.sortBy;

    this._mainBloc.add(ResetOffset());
    this._mainBloc.add(FetchSearchInfo(price: price, openAt: openAt, sortBy: sortBy));
  }

  @override
  Widget build(BuildContext context) {
    this._clearAndFeach();

    return PlatformScaffold(
        body: Stack(
          children: <Widget>[
            NestedScrollView(
                headerSliverBuilder: (BuildContext context, bool isBoxIsScrolled) =>
                <Widget>[
                  CupertinoSliverNavigationBar(
                      automaticallyImplyLeading: false,
                      largeTitle: Text(UIConstants.APP_TITLE,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: Dimens.xxxxhFontSize)
                      ),
                      backgroundColor: Color(UIConstants.AppBarColor),
                  )
                ],
                body: BlocBuilder<MainBloc, MainState>(
                    builder: (context, state) {
                      if(state is Success || state is LoadMoreSuccess) {
                        List<YelpRestaurantSummaryInfo> summaryInfos = (state is Success) ? state.summaryInfos : (state as LoadMoreSuccess).summaryInfos;

                        return NotificationListener<ScrollEndNotification>(
                          onNotification: (notification) {
                            if(notification is ScrollEndNotification && this._scrollController.position.atEdge) {
                              int? price = this._configs.price;
                              int? openAt = this._configs.openAt;
                              String? sortBy = this._configs.sortBy;

                              // Load more when scrolling reach the edge of ListView
                              this._mainBloc.add(FetchSearchInfo(price: price, openAt: openAt, sortBy: sortBy));
                            }
                            return true;
                          },
                          child: ListView.builder(
                              padding: EdgeInsets.only(top: 0, bottom: 0),
                              controller: this._scrollController,
                              itemCount: summaryInfos.length + 2 ,
                              itemBuilder: (context, index) {
                                if(index == 0) {
                                  final adState = Provider.of<BannerADState>(context);

                                  return BannerAD(adState: adState);
                                } else if(index == 1) {
                                  return FilterTagsWidget(filterConfigs: this._configs);
                                } else {
                                  YelpRestaurantSummaryInfo summaryInfo = summaryInfos[index - 1];

                                  return GestureDetector(
                                      child: RestaurantItemCell(summaryInfo: summaryInfo),
                                      onTap: () {
                                        String id = summaryInfo.id ?? "";
                                        Tuple2 arguments = Tuple2<String, dynamic>(id, null);

                                        Navigator.of(context).pushNamed(
                                            RestaurantDetailPage.ROUTE_NAME,
                                            arguments: arguments
                                        );
                                      });
                                }
                              })
                        );
                      } else if(state is InProgress) {
                        return Center(child: LoadingWidget());
                      } else {
                        return EmptyDataWidget();
                      }
                    }
                )
            ),
            Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                    padding: EdgeInsets.only(right: 30, bottom: 50),
                    child: ExpandableFabButton(
                        initialOpen: false,
                        distance: 120,
                        mainIcon: Icon(Icons.menu),
                        children: [
                          const Icon(Icons.navigation),
                          const Icon(Icons.search),
                          const Icon(Icons.filter_list),
                        ],
                        childrenPressActions: [
                              () { this._clearAndFeach(); },
                              () {
                                    showPlatformDialog(
                                        context: context,
                                        builder: (context) => PlatformAlertDialog(
                                          key: GlobalKey(debugLabel: "FilterListByKeywordDialog"),
                                          title: PlatformText(
                                            "關鍵字過濾",
                                            style: TextStyle(
                                              fontSize: Dimens.xxhFontSize,
                                              fontWeight: FontWeight.bold
                                            ),
                                          ),
                                          content: PlatformTextField(
                                            hintText: "店名/分類/地區/路",
                                            onChanged: (keyword) {
                                                  this._filterKeyword = keyword;
                                              },
                                          ),
                                          actions: [
                                            PlatformButton(
                                                onPressed: () {
                                                  this._mainBloc.add(FilterListByKeyword(keyword: this._filterKeyword));
                                                  this._filterKeyword = "";

                                                  Navigator.pop(context);
                                                },
                                                child: PlatformText("確定")
                                            ),
                                            PlatformButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: PlatformText("取消")
                                            )
                                          ],
                                        )
                                    );
                                  },
                              () async {
                                Tuple2<FilterConfigs, dynamic> arguments = Tuple2<FilterConfigs, dynamic>(this._configs, null);
                                Tuple2<FilterConfigs, dynamic>? result = (await Navigator.of(context).pushNamed(FilterPage.ROUTE_NAME, arguments: arguments)) as Tuple2<FilterConfigs, dynamic>?;

                                if(result == null) return;

                                setState(() {
                                  this._configs = result.item1;
                                });
                            }
                        ])
                )
            )
          ]
        )
    );
  }

  Future<AnchoredAdaptiveBannerAdSize?> _anchoredAdaptiveBannerAdSize(
      BuildContext context) async {
    return await AdSize.getAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).orientation == Orientation.portrait
          ? Orientation.portrait
          : Orientation.landscape,
      MediaQuery.of(context).size.width.toInt(),
    );
  }
}
