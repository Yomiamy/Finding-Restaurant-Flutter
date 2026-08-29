import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../../../component/component_barrel.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../features/utils/utils_barrel.dart';
import '../../../generated/l10n.dart';
import '../../../model/model_barrel.dart';
import '../../favor/view/view_barrel.dart';
import '../../filter/view/view_barrel.dart';
import '../../restaurant/view/view_barrel.dart';
import '../../settings/view/view_barrel.dart';
import '../bloc/bloc_barrel.dart';
import 'map_widget.dart';
import 'restaurant_info_list_widget.dart';

class MainPage extends StatefulWidget {
  static const routeName = '/MainPage';

  const MainPage({Key key = const Key('MainPage')}) : super(key: key);

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> implements AppOpenADEvent {
  FilterConfigs _configs = FilterConfigs();
  String _filterKeyword = '';
  bool _isListMode = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late MainBloc _mainBloc;
  late List<RestaurantEntity> _summaryInfos;

  MainPageState();

  @override
  void initState() {
    super.initState();

    _mainBloc = BlocProvider.of<MainBloc>(context);
    _summaryInfos = List.empty();

    _mainBloc.add(const NotificationSetup());
    _mainBloc.add(
      FetchSearchInfo(
        price: _configs.price,
        openAt: _configs.openAtInSec,
        sortBy: _configs.sortBy,
      ),
    );

    handleNotificationData();
  }

  @override
  void didUpdateWidget(covariant MainPage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = Builder(
      builder: (innerContext) => _buildContent(innerContext),
    );

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
        style: const TextStyle(
          color: Colors.white,
          fontSize: ThemeFontSize.fontSize24,
        ),
      ),
      backgroundColor: ThemeColor.appPrimary,
      leading: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () => _openDrawer(),
        icon: const Icon(Icons.menu, color: Colors.white),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocConsumer<MainBloc, MainState>(
      listener: (context, state) {
        if (state is ResetSuccess) {
          _mainBloc.add(
            FetchSearchInfo(
              price: _configs.price,
              openAt: _configs.openAtInSec,
              sortBy: _configs.sortBy,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is Success) {
          _summaryInfos = state.summaryInfos;
        } else if (state is LoadMoreSuccess) {
          _summaryInfos = state.summaryInfos;
        } else if (state is LoadMoreInProgress) {
          _summaryInfos = state.summaryInfos;
        }

        if (state is InProgress ||
            state is MainInitial ||
            state is ResetSuccess) {
          return _isListMode
              ? ListView.builder(
                  itemCount: 10,
                  itemBuilder: (_, __) => const RestaurantItemSkeleton(),
                )
              : const Center(child: LoadingWidget());
        }

        if (_summaryInfos.isEmpty) {
          return EmptyDataWidget.withDefaults();
        }

        // display restaurant list
        return _isListMode
            ? RestaurantInfoListWidget(
                _summaryInfos,
                _configs,
                isLoadingMore: state is LoadMoreInProgress,
              )
            : MapWidget(_summaryInfos);
      },
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final appLocalizations = S.current;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: ThemeColor.appPrimary),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  appLocalizations.main_page_title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: ThemeFontSize.fontSize22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search, color: ThemeColor.appPrimary),
              title: Text(appLocalizations.keyword_search),
              onTap: () {
                Navigator.of(context).pop();
                _runAfterDrawerClosed(() {
                  _showKeywordDialog();
                });
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.filter_list,
                color: ThemeColor.appPrimary,
              ),
              title: Text(appLocalizations.filter_rules),
              onTap: () {
                Navigator.of(context).pop();
                _runAfterDrawerClosed(() {
                  _openFilterPage();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.map, color: ThemeColor.appPrimary),
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
                    _isListMode = !_isListMode;
                  });
                  _mainBloc.add(const Reset());
                });
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.navigation,
                color: ThemeColor.appPrimary,
              ),
              title: Text(appLocalizations.map_my_loc_title),
              onTap: () {
                Navigator.of(context).pop();
                _runAfterDrawerClosed(() {
                  _mainBloc.add(const Reset());
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: ThemeColor.appPrimary),
              title: Text(appLocalizations.favorite_stores),
              onTap: () {
                Navigator.of(context).pop();
                _runAfterDrawerClosed(() {
                  Navigator.of(this.context).pushNamed(FavorPage.routeName);
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: ThemeColor.appPrimary),
              title: Text(appLocalizations.settings_title),
              onTap: () {
                Navigator.of(context).pop();
                _runAfterDrawerClosed(() {
                  Navigator.of(this.context).pushNamed(SettingsPage.routeName);
                });
              },
            ),
          ],
        ),
      ),
    );
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
          _filterKeyword = keyword;
        },
      ),
      actions: [
        PlatformTextButton(
          onPressed: () {
            _mainBloc.add(
              FilterListByKeyword(
                keyword: _filterKeyword,
                sortByStr: _configs.sortBy,
              ),
            );
            _filterKeyword = '';
            Navigator.pop(context);
          },
          child: PlatformText(S.current.confirm),
        ),
        PlatformTextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: PlatformText(S.current.cancel),
        ),
      ],
    );
  }

  Future<void> _openFilterPage() async {
    Tuple2<FilterConfigs, dynamic> arguments = Tuple2<FilterConfigs, dynamic>(
      _configs,
      null,
    );
    Tuple2<FilterConfigs, dynamic>? result =
        (await Navigator.of(
              context,
            ).pushNamed(FilterPage.routeName, arguments: arguments))
            as Tuple2<FilterConfigs, dynamic>?;

    if (result == null || !mounted) {
      return;
    }

    _configs = result.item1;
    _mainBloc.add(const Reset());
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
      if (!mounted) return;
      // Waiting building is finish and run.
      final args =
          ModalRoute.of(context)?.settings.arguments
              as Tuple2<RestaurantEntity, dynamic>?;
      RestaurantEntity? summaryInfoFromNotification = args?.item1;

      if (summaryInfoFromNotification == null) {
        return;
      }

      Tuple2 arguments = Tuple2<RestaurantEntity, dynamic>(
        summaryInfoFromNotification,
        null,
      );
      // Avoid duplicate push, use pushNamedAndRemoveUntil instead of push
      Navigator.of(context).pushNamedAndRemoveUntil(
        RestaurantDetailPage.routeName,
        ModalRoute.withName(MainPage.routeName),
        arguments: arguments,
      );
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
