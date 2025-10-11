import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/component/EmptyDataWidget.dart';
import 'package:flutter_restaruant/component/LoadingWidget.dart';
import 'package:flutter_restaruant/component/ad/AppOpenAdState.dart';
import 'package:flutter_restaruant/flow/favor/view/FavorPage.dart';
import 'package:flutter_restaruant/flow/filter/view/FilterPage.dart';
import 'package:flutter_restaruant/flow/main/view/MapWidget.dart';
import 'package:flutter_restaruant/flow/main/view/RestaurantInfoListWidget.dart';
import 'package:flutter_restaruant/flow/restaurant/view/RestaurantDetailPage.dart';
import 'package:flutter_restaruant/flow/settings/view/SettingsPage.dart';
import 'package:flutter_restaruant/l10n/app_localizations.dart';
import 'package:flutter_restaruant/model/FilterConfigs.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/utils/Tuple.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';
import 'package:flutter_restaruant/utils/ViewUtils.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../bloc/MainBloc.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
    final Widget content = Builder(builder: (innerContext) => _buildContent(innerContext));

    return PlatformScaffold(
      body: content,
      material: (_, __) => MaterialScaffoldData(
        widgetKey: _scaffoldKey,
        drawer: _buildDrawer(context),
      ),
      cupertino: (_, __) => CupertinoPageScaffoldData(
        body: Scaffold(
          key: _scaffoldKey,
          drawer: _buildDrawer(context),
          body: content,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool isBoxIsScrolled) => <Widget>[
              CupertinoSliverNavigationBar(
                  automaticallyImplyLeading: false,
                  largeTitle: Text(AppLocalizations.of(context)?.main_page_title ?? "",
                      style: TextStyle(color: Colors.white, fontSize: UIConstants.xxxxhFontSize)),
                  backgroundColor: Color(UIConstants.APP_PRIMARY_COLOR),
                  trailing: PlatformIconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _openDrawer(),
                      materialIcon: Icon(Icons.menu, color: Colors.white),
                      cupertinoIcon: Icon(CupertinoIcons.bars, color: Colors.white)))
            ],
        body: BlocBuilder<MainBloc, MainState>(builder: (context, state) {
          if (state is Success || state is LoadMoreSuccess || state is ToggleFavorSuccess) {
            if (state is Success || state is LoadMoreSuccess) {
              this._summaryInfos =
                  (state is Success) ? state.summaryInfos : (state as LoadMoreSuccess).summaryInfos;
            }
            // display restaurant list
            return _isListMode
                ? RestaurantInfoListWidget(this._summaryInfos, this._configs)
                : MapWidget(this._summaryInfos);
          } else if (state is InProgress || state is MainInitial || state is ResetSuccess) {
            if (state is MainInitial || state is ResetSuccess) {
              int? price = this._configs.price;
              int? openAt = this._configs.openAtInSec;
              String? sortBy = this._configs.sortBy;

              if (state is MainInitial) {
                // Request FCM
                this._mainBloc.add(NotificationSetup());
                this.handleNotificationData();
              }
              this._mainBloc.add(FetchSearchInfo(price: price, openAt: openAt, sortBy: sortBy));
            }
            return Center(child: LoadingWidget());
          } else {
            return EmptyDataWidget();
          }
        }));
  }

  Drawer _buildDrawer(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Drawer(
        child: SafeArea(
            child: ListView(padding: EdgeInsets.zero, children: [
      DrawerHeader(
          decoration: BoxDecoration(color: Color(UIConstants.APP_PRIMARY_COLOR)),
          child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(appLocalizations?.main_page_title ?? "",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: UIConstants.xxxhFontSize,
                      fontWeight: FontWeight.bold)))),
      ListTile(
          leading: Icon(Icons.settings, color: Color(UIConstants.APP_PRIMARY_COLOR)),
          title: Text(appLocalizations?.settings_title ?? "Settings"),
          onTap: () {
            Navigator.of(context).pop();
            _runAfterDrawerClosed(() {
              Navigator.of(this.context).pushNamed(SettingsPage.ROUTE_NAME);
            });
          }),
      ListTile(
          leading: Icon(Icons.favorite, color: Color(UIConstants.APP_PRIMARY_COLOR)),
          title: Text(appLocalizations?.favorite_store_add ?? "Favorites"),
          onTap: () {
            Navigator.of(context).pop();
            _runAfterDrawerClosed(() {
              Navigator.of(this.context).pushNamed(FavorPage.ROUTE_NAME);
            });
          }),
      ListTile(
          leading: Icon(Icons.map, color: Color(UIConstants.APP_PRIMARY_COLOR)),
          title: Text(
            _isListMode
                ? (appLocalizations?.map_mode ?? 'Map Mode')
                : (appLocalizations?.list_mode ?? 'List Mode'),
          ),
          onTap: () {
            Navigator.of(context).pop();
            _runAfterDrawerClosed(() {
              if (!mounted) return;
              setState(() {
                this._isListMode = !this._isListMode;
              });
              this._mainBloc.add(Reset());
            });
          }),
      ListTile(
          leading: Icon(Icons.navigation, color: Color(UIConstants.APP_PRIMARY_COLOR)),
          title: Text(appLocalizations?.map_my_loc_title ?? "Reset Location"),
          onTap: () {
            Navigator.of(context).pop();
            _runAfterDrawerClosed(() {
              this._mainBloc.add(Reset());
            });
          }),
      ListTile(
          leading: Icon(Icons.search, color: Color(UIConstants.APP_PRIMARY_COLOR)),
          title: Text(appLocalizations?.keyword_search ?? "Keyword Search"),
          onTap: () {
            Navigator.of(context).pop();
            _runAfterDrawerClosed(() {
              _showKeywordDialog();
            });
          }),
      ListTile(
          leading: Icon(Icons.filter_list, color: Color(UIConstants.APP_PRIMARY_COLOR)),
          title: Text(appLocalizations?.filter_rules ?? "Filter"),
          onTap: () {
            Navigator.of(context).pop();
            _runAfterDrawerClosed(() {
              _openFilterPage();
            });
          })
    ])));
  }

  void _runAfterDrawerClosed(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      action();
    });
  }

  void _showKeywordDialog() {
    if (!mounted) {
      return;
    }

    ViewUtils.showPromptDialog(
        context: context,
        title: AppLocalizations.of(context)?.keyword_search ?? "",
        msgWidget: PlatformTextField(
          hintText: AppLocalizations.of(context)?.keyword_search_hint ?? "",
          onChanged: (keyword) {
            this._filterKeyword = keyword;
          },
        ),
        actions: [
          PlatformTextButton(
              onPressed: () {
                this._mainBloc.add(FilterListByKeyword(
                    keyword: this._filterKeyword, sortByStr: this._configs.sortBy));
                this._filterKeyword = "";
                Navigator.pop(context);
              },
              child: PlatformText(AppLocalizations.of(context)?.confirm ?? "")),
          PlatformTextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: PlatformText(AppLocalizations.of(context)?.cancel ?? ""))
        ]);
  }

  Future<void> _openFilterPage() async {
    Tuple2<FilterConfigs, dynamic> arguments = Tuple2<FilterConfigs, dynamic>(this._configs, null);
    Tuple2<FilterConfigs, dynamic>? result = (await Navigator.of(this.context)
        .pushNamed(FilterPage.ROUTE_NAME, arguments: arguments)) as Tuple2<FilterConfigs, dynamic>?;

    if (result == null || !mounted) {
      return;
    }

    this._configs = result.item1;
    this._mainBloc.add(Reset());
  }

  void _openDrawer() {
    final scaffoldState = _scaffoldKey.currentState;

    if (scaffoldState != null) {
      scaffoldState.openDrawer();
    }
  }

  /// --- FCM notification
  void handleNotificationData() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // Waiting building is finish and run.
      final args =
          ModalRoute.of(context)?.settings.arguments as Tuple2<YelpRestaurantSummaryInfo, dynamic>?;
      YelpRestaurantSummaryInfo? summaryInfoFromNotification = args?.item1;

      if (summaryInfoFromNotification == null) {
        return;
      }

      Tuple2 arguments =
          Tuple2<YelpRestaurantSummaryInfo, dynamic>(summaryInfoFromNotification, null);
      // Avoid duplicate push, use pushNamedAndRemoveUntil instead of push
      Navigator.of(context).pushNamedAndRemoveUntil(
          RestaurantDetailPage.ROUTE_NAME, ModalRoute.withName(MainPage.ROUTE_NAME),
          arguments: arguments);
    });
  }

  /// --- AD
  Future<AnchoredAdaptiveBannerAdSize?> _anchoredAdaptiveBannerAdSize(BuildContext context) async {
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
