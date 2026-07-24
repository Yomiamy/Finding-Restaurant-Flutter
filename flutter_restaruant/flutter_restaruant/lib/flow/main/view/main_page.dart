import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/component/empty_data_widget.dart';
import 'package:flutter_restaruant/component/loading_widget.dart';
import 'package:flutter_restaruant/component/ad/app_open_ad_state.dart';
import 'package:flutter_restaruant/flow/favor/view/favor_page.dart';
import 'package:flutter_restaruant/flow/filter/view/filter_page.dart';
import 'package:flutter_restaruant/flow/main/view/map_widget.dart';
import 'package:flutter_restaruant/flow/main/view/restaurant_info_list_widget.dart';
import 'package:flutter_restaruant/flow/restaurant/view/restaurant_detail_page.dart';
import 'package:flutter_restaruant/flow/settings/view/settings_page.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_restaruant/model/filter_configs.dart';
import 'package:flutter_restaruant/model/yelp_restaurant_summary_info.dart';
import 'package:flutter_restaruant/utils/tuple.dart';
import 'package:flutter_restaruant/utils/ui_constants.dart';
import 'package:flutter_restaruant/utils/view_utils.dart';

import '../bloc/main_bloc.dart';
import 'package:flutter_restaruant/gen/colors.gen.dart';

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

    this._mainBloc.add(NotificationSetup());
    this._mainBloc.add(FetchSearchInfo(
        price: this._configs.price,
        openAt: this._configs.openAtInSec,
        sortBy: this._configs.sortBy));

    this.handleNotificationData();
  }

  @override
  void didUpdateWidget(covariant MainPage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = Builder(builder: (innerContext) => _buildContent(innerContext));

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(),
      body: content,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          S.current.main_page_title,
          style: TextStyle(color: Colors.white, fontSize: UIConstants.xxxxhFontSize),
        ),
        backgroundColor: ColorName.appPrimaryColor,
        leading: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () => _openDrawer(),
            icon: Icon(Icons.menu, color: Colors.white)));
  }

  Widget _buildContent(BuildContext context) {
    return BlocConsumer<MainBloc, MainState>(
        listener: (context, state) {
          if (state is ResetSuccess) {
            this._mainBloc.add(FetchSearchInfo(
                price: this._configs.price,
                openAt: this._configs.openAtInSec,
                sortBy: this._configs.sortBy));
          }
        },
        builder: (context, state) {
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
            return Center(child: LoadingWidget());
          } else {
            return EmptyDataWidget();
          }
        });
  }

  Drawer _buildDrawer(BuildContext context) {
    final appLocalizations = S.current;

    return Drawer(
        child: SafeArea(
            child: ListView(padding: EdgeInsets.zero, children: [
      DrawerHeader(
          decoration: BoxDecoration(color: ColorName.appPrimaryColor),
          child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(appLocalizations.main_page_title,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: UIConstants.xxxhFontSize,
                      fontWeight: FontWeight.bold)))),
      ListTile(
          leading: Icon(Icons.settings, color: ColorName.appPrimaryColor),
          title: Text(appLocalizations.settings_title),
          onTap: () {
            Navigator.of(context).pop();
            _runAfterDrawerClosed(() {
              Navigator.of(this.context).pushNamed(SettingsPage.ROUTE_NAME);
            });
          }),
      ListTile(
          leading: Icon(Icons.favorite, color: ColorName.appPrimaryColor),
          title: Text(appLocalizations.favorite_store_add),
          onTap: () {
            Navigator.of(context).pop();
            _runAfterDrawerClosed(() {
              Navigator.of(this.context).pushNamed(FavorPage.ROUTE_NAME);
            });
          }),
      ListTile(
          leading: Icon(Icons.map, color: ColorName.appPrimaryColor),
          title: Text(
            _isListMode
                ? appLocalizations.map_mode
                : appLocalizations.list_mode,
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
          leading: Icon(Icons.navigation, color: ColorName.appPrimaryColor),
          title: Text(appLocalizations.map_my_loc_title),
          onTap: () {
            Navigator.of(context).pop();
            _runAfterDrawerClosed(() {
              this._mainBloc.add(Reset());
            });
          }),
      ListTile(
          leading: Icon(Icons.search, color: ColorName.appPrimaryColor),
          title: Text(appLocalizations.keyword_search),
          onTap: () {
            Navigator.of(context).pop();
            _runAfterDrawerClosed(() {
              _showKeywordDialog();
            });
          }),
      ListTile(
          leading: Icon(Icons.filter_list, color: ColorName.appPrimaryColor),
          title: Text(appLocalizations.filter_rules),
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
        title: S.current.keyword_search,
        msgWidget: PlatformTextField(
          hintText: S.current.keyword_search_hint,
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
              child: PlatformText(S.current.confirm)),
          PlatformTextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: PlatformText(S.current.cancel))
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

  void updateState(VoidCallback fn) {
    setState(fn);
  }

  /// [AppOpenADEvent]
  @override
  void onAdDismissed() {}

  @override
  void onAdFailedToShow() {}
}
