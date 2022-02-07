import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/component/EmptyDataWidget.dart';
import 'package:flutter_restaruant/component/ExpandableFabButton.dart';
import 'package:flutter_restaruant/component/LoadingWidget.dart';
import 'package:flutter_restaruant/component/ad/AppLifecycleReactor.dart';
import 'package:flutter_restaruant/component/ad/AppOpenAD.dart';
import 'package:flutter_restaruant/component/ad/AppOpenAdState.dart';
import 'package:flutter_restaruant/component/ad/BannerADState.dart';
import 'package:flutter_restaruant/component/ad/BannerAD.dart';
import 'package:flutter_restaruant/component/cell/main_page/RestaurantItemCell.dart';
import 'package:flutter_restaruant/flow/favor/view/FavorPage.dart';
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

class MainPageState extends State<MainPage> implements AppOpenADEvent {

  FilterConfigs _configs = FilterConfigs();
  ScrollController _scrollController = ScrollController();
  String _filterKeyword = "";
  late MainBloc _mainBloc;
  late AppLifecycleReactor _appLifecycleReactor;

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

  @override
  Widget build(BuildContext context) {
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
                      backgroundColor: Color(UIConstants.APP_BAR_COLOR),
                  )
                ],
                body: BlocBuilder<MainBloc, MainState>(
                    builder: (context, state) {
                      if(state is Success || state is LoadMoreSuccess) {
                        List<YelpRestaurantSummaryInfo> summaryInfos = (state is Success) ? state.summaryInfos : (state as LoadMoreSuccess).summaryInfos;

                        return NotificationListener<ScrollEndNotification>(
                          onNotification: (notification) {
                            if(this._scrollController.position.atEdge) {
                              int? price = this._configs.price;
                              int? openAt = this._configs.openAtInSec;
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
                                  YelpRestaurantSummaryInfo summaryInfo = summaryInfos[index - 2];

                                  return GestureDetector(
                                      child: RestaurantItemCell(summaryInfo: summaryInfo, isFavorPage: false),
                                      onTap: () {
                                        String id = summaryInfo.id ?? "";
                                        // TODO: 尚未指定
                                        Tuple2 arguments = Tuple2<String, bool>(id, true);

                                        Navigator.of(context).pushNamed(
                                            RestaurantDetailPage.ROUTE_NAME,
                                            arguments: arguments
                                        );
                                      });
                                }
                              })
                        );
                      } else if(state is InProgress || state is MainInitial || state is ResetSuccess) {
                        if(state is MainInitial || state is ResetSuccess) {
                          int? price = this._configs.price;
                          int? openAt = this._configs.openAtInSec;
                          String? sortBy = this._configs.sortBy;

                          this._mainBloc.add(FetchSearchInfo(price: price, openAt: openAt, sortBy: sortBy));
                        }
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
                          const Icon(Icons.stars),
                          const Icon(Icons.navigation),
                          const Icon(Icons.search),
                          const Icon(Icons.filter_list),
                        ],
                        childrenPressActions: [
                              () => Navigator.of(context).pushNamed(FavorPage.ROUTE_NAME),
                              () => this._mainBloc.add(Reset()),
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
                                                  this._mainBloc.add(FilterListByKeyword(keyword: this._filterKeyword, sortByStr: this._configs.sortBy));
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

                                this._configs = result.item1;
                                this._mainBloc.add(Reset());
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

  /// [AppOpenADEvent]
  @override
  void onAdDismissed() {}

  @override
  void onAdFailedToShow() {}
}
