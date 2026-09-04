import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../../../component/component_barrel.dart';
import '../../../di/di_barrel.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../../../features/foundation/extension/extension_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../features/utils/utils_barrel.dart';
import '../../../generated/l10n.dart';
import '../../../model/model_barrel.dart';
import '../../favor/view/view_barrel.dart';
import '../../filter/view/view_barrel.dart';
import '../../restaurant/view/view_barrel.dart';
import '../../settings/view/view_barrel.dart';
import '../bloc/bloc_barrel.dart';
import 'drawer_widget.dart';
import 'main_page_content_widget.dart';

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

  MainPageState();

  @override
  void initState() {
    super.initState();

    _mainBloc = BlocProvider.of<MainBloc>(context);

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
    return Scaffold(
      key: _scaffoldKey,
      drawer: DrawerWidget(
        isListMode: _isListMode,
        onKeywordSearch: _showKeywordDialog,
        onFilterRules: _openFilterPage,
        onToggleViewMode: _toggleViewMode,
        onMapMyLoc: () => _mainBloc.add(const Reset()),
        onFavorites: _navigateToFavorites,
        onSettings: _navigateToSettings,
      ),
      appBar: _buildAppBar(context),
      body: MainPageContentWidget(
        filterConfigs: _configs,
        isListMode: _isListMode,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BannerAD(adState: getIt<BannerADState>()),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        S.current.main_page_title,
        style: const TextStyle(
          color: ThemeColor.colorffffff,
          fontSize: ThemeFontSize.fontSize24,
        ),
      ),
      backgroundColor: ThemeColor.colord84a20,
      leading: IconButton(
        padding: EdgeInsets.zero,
        onPressed: _openDrawer,
        icon: const Icon(Icons.menu, color: ThemeColor.colorffffff),
      ),
    );
  }

  void _toggleViewMode() {
    if (!mounted) return;
    setState(() {
      _isListMode = !_isListMode;
    });
    _mainBloc.add(const Reset());
  }

  void _navigateToFavorites() {
    if (!mounted) return;
    Navigator.of(context).pushNamed(FavorPage.routeName);
  }

  void _navigateToSettings() {
    if (!mounted) return;
    Navigator.of(context).pushNamed(SettingsPage.routeName);
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

    setState(() {
      _configs = result.item1;
    });
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
    context.runAfterFrame(() {
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
