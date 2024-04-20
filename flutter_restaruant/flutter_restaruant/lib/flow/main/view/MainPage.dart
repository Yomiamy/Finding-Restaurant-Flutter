import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/component/EmptyDataWidget.dart';
import 'package:flutter_restaruant/component/ExpandableFabButton.dart';
import 'package:flutter_restaruant/component/LoadingWidget.dart';
import 'package:flutter_restaruant/component/ad/AppOpenAdState.dart';
import 'package:flutter_restaruant/flow/favor/view/FavorPage.dart';
import 'package:flutter_restaruant/flow/filter/view/FilterPage.dart';
import 'package:flutter_restaruant/flow/main/view/MapWidget.dart';
import 'package:flutter_restaruant/flow/main/view/RestaurantInfoListWidget.dart';
import 'package:flutter_restaruant/flow/restaurant/view/RestaurantDetailPage.dart';
import 'package:flutter_restaruant/flow/settings/view/SettingsPage.dart';
import 'package:flutter_restaruant/model/FilterConfigs.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/utils/Tuple.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';
import 'package:flutter_restaruant/utils/ViewUtils.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../bloc/MainBloc.dart';
import 'FilterTagsWidget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MainPage extends StatefulWidget {
  static const ROUTE_NAME = "/MainPage";

  MainPage({Key key = const Key("MainPage")}) : super(key: key);

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> implements AppOpenADEvent {
  FilterConfigs _configs = FilterConfigs();
  String _filterKeyword = "";
  bool _isListMode = true;
  late MainBloc _mainBloc;
  late List<YelpRestaurantSummaryInfo> _summaryInfos;

  MainPageState();

  @override
  void initState() {
    super.initState();

    this._mainBloc = BlocProvider.of<MainBloc>(context);
    this._summaryInfos = List.empty();
  }

  @override
  void didUpdateWidget(covariant MainPage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
        body: Stack(children: <Widget>[
      NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool isBoxIsScrolled) =>
              <Widget>[
                CupertinoSliverNavigationBar(
                  automaticallyImplyLeading: false,
                  largeTitle: Text(
                      AppLocalizations?.of(context)?.main_page_title ?? "",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: UIConstants.xxxxhFontSize)),
                  backgroundColor: Color(UIConstants.APP_PRIMARY_COLOR),
                )
              ],
          body: BlocBuilder<MainBloc, MainState>(builder: (context, state) {
            if (state is Success ||
                state is LoadMoreSuccess ||
                state is ToggleFavorSuccess) {
              if (state is Success || state is LoadMoreSuccess) {
                this._summaryInfos = (state is Success)
                    ? state.summaryInfos
                    : (state as LoadMoreSuccess).summaryInfos;
              }
              // display restaurant list
              return _isListMode
                  ? RestaurantInfoListWidget(this._summaryInfos, this._configs)
                  : MapWidget(this._summaryInfos);
            } else if (state is InProgress ||
                state is MainInitial ||
                state is ResetSuccess) {
              if (state is MainInitial || state is ResetSuccess) {
                int? price = this._configs.price;
                int? openAt = this._configs.openAtInSec;
                String? sortBy = this._configs.sortBy;

                if (state is MainInitial) {
                  // Request FCM
                  this._mainBloc.add(NotificationSetup());
                  this.handleNotificationData();
                }
                this._mainBloc.add(FetchSearchInfo(
                    price: price, openAt: openAt, sortBy: sortBy));
              }
              return Center(child: LoadingWidget());
            } else {
              return EmptyDataWidget();
            }
          })),
      Align(
          alignment: Alignment.bottomRight,
          child: Padding(
              padding: EdgeInsets.only(right: 30, bottom: 50),
              child: ExpandableFabButton(
                  initialOpen: false,
                  distance: 190,
                  mainIcon: Icon(Icons.menu),
                  children: [
                    const Icon(Icons.settings),
                    const Icon(Icons.favorite),
                    const Icon(Icons.map),
                    const Icon(Icons.navigation),
                    const Icon(Icons.search),
                    const Icon(Icons.filter_list),
                  ],
                  childrenPressActions: [
                    () => Navigator.of(context)
                        .pushNamed(SettingsPage.ROUTE_NAME),
                    () => Navigator.of(context).pushNamed(FavorPage.ROUTE_NAME),
                    () {
                      this._isListMode = !_isListMode;

                      this._mainBloc.add(Reset());
                    },
                    () => this._mainBloc.add(Reset()),
                    () {
                      ViewUtils.showPromptDialog(
                          context: context,
                          title: AppLocalizations?.of(context)
                              ?.keyword_search ??
                              "",
                          msgWidget: PlatformTextField(
                            hintText: AppLocalizations?.of(context)
                                ?.keyword_search_hint ??
                                "",
                            onChanged: (keyword) {
                              this._filterKeyword = keyword;
                            },
                          ),
                          actions: [
                            PlatformTextButton(
                                onPressed: () {
                                  this._mainBloc.add(
                                      FilterListByKeyword(
                                          keyword:
                                          this._filterKeyword,
                                          sortByStr:
                                          this._configs.sortBy));
                                  this._filterKeyword = "";
                                  Navigator.pop(context);
                                },
                                child: PlatformText(
                                    AppLocalizations?.of(context)
                                        ?.confirm ??
                                        "")),
                            PlatformTextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: PlatformText(
                                    AppLocalizations?.of(context)
                                        ?.cancel ??
                                        "")
                            )
                          ]);
                    },
                    () async {
                      Tuple2<FilterConfigs, dynamic> arguments =
                          Tuple2<FilterConfigs, dynamic>(this._configs, null);
                      Tuple2<FilterConfigs, dynamic>? result =
                          (await Navigator.of(context).pushNamed(
                                  FilterPage.ROUTE_NAME,
                                  arguments: arguments))
                              as Tuple2<FilterConfigs, dynamic>?;

                      if (result == null) return;

                      this._configs = result.item1;
                      this._mainBloc.add(Reset());
                    }
                  ])))
    ]));
  }

  /// --- FCM notification
  void handleNotificationData() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // Waiting building is finish and run.
      final args = ModalRoute.of(context)?.settings.arguments
          as Tuple2<YelpRestaurantSummaryInfo, dynamic>?;
      YelpRestaurantSummaryInfo? summaryInfoFromNotification = args?.item1;

      if (summaryInfoFromNotification == null) {
        return;
      }

      Tuple2 arguments = Tuple2<YelpRestaurantSummaryInfo, dynamic>(
          summaryInfoFromNotification, null);
      // Avoid duplicate push, use pushNamedAndRemoveUntil instead of push
      Navigator.of(context).pushNamedAndRemoveUntil(
          RestaurantDetailPage.ROUTE_NAME,
          ModalRoute.withName(MainPage.ROUTE_NAME),
          arguments: arguments);
    });
  }

  /// --- AD
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
