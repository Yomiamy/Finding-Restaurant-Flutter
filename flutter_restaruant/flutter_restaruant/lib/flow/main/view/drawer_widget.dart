import 'package:flutter/material.dart';

import '../../../features/foundation/extension/extension_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';

/// 主頁面側邊選單元件 (Drawer)。
///
/// 包含關鍵字搜尋、篩選條件、檢視模式切換、定位重置、收藏與設定頁等導覽選項。
class DrawerWidget extends StatelessWidget {
  const DrawerWidget({
    super.key,
    required this.isListMode,
    required this.onKeywordSearch,
    required this.onFilterRules,
    required this.onToggleViewMode,
    required this.onMapMyLoc,
    required this.onFavorites,
    required this.onSettings,
  });

  final bool isListMode;
  final VoidCallback onKeywordSearch;
  final VoidCallback onFilterRules;
  final VoidCallback onToggleViewMode;
  final VoidCallback onMapMyLoc;
  final VoidCallback onFavorites;
  final VoidCallback onSettings;

  void _handleTap(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    context.runAfterFrame(action);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = S.current;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: ThemeColor.colord84a20),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  appLocalizations.main_page_title,
                  style: const TextStyle(
                    color: ThemeColor.colorffffff,
                    fontSize: ThemeFontSize.fontSize22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search, color: ThemeColor.colord84a20),
              title: Text(appLocalizations.keyword_search),
              onTap: () => _handleTap(context, onKeywordSearch),
            ),
            ListTile(
              leading: const Icon(
                Icons.filter_list,
                color: ThemeColor.colord84a20,
              ),
              title: Text(appLocalizations.filter_rules),
              onTap: () => _handleTap(context, onFilterRules),
            ),
            ListTile(
              leading: const Icon(Icons.map, color: ThemeColor.colord84a20),
              title: Text(
                isListMode
                    ? appLocalizations.map_mode
                    : appLocalizations.list_mode,
              ),
              onTap: () => _handleTap(context, onToggleViewMode),
            ),
            ListTile(
              leading: const Icon(
                Icons.navigation,
                color: ThemeColor.colord84a20,
              ),
              title: Text(appLocalizations.map_my_loc_title),
              onTap: () => _handleTap(context, onMapMyLoc),
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: ThemeColor.colord84a20),
              title: Text(appLocalizations.favorite_stores),
              onTap: () => _handleTap(context, onFavorites),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: ThemeColor.colord84a20),
              title: Text(appLocalizations.settings_title),
              onTap: () => _handleTap(context, onSettings),
            ),
          ],
        ),
      ),
    );
  }
}
