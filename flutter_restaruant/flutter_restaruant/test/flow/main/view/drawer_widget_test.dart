import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/flow/main/view/view_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';

void main() {
  testWidgets('DrawerWidget renders navigation tiles and triggers callbacks', (
    WidgetTester tester,
  ) async {
    bool keywordTapped = false;
    bool filterTapped = false;
    bool toggleTapped = false;
    bool myLocTapped = false;
    bool favoritesTapped = false;
    bool settingsTapped = false;

    Widget buildTestScaffold({required bool isListMode}) {
      return MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.delegate.supportedLocales,
        theme: AppThemeData.materialLight,
        home: Scaffold(
          drawer: DrawerWidget(
            isListMode: isListMode,
            onKeywordSearch: () => keywordTapped = true,
            onFilterRules: () => filterTapped = true,
            onToggleViewMode: () => toggleTapped = true,
            onMapMyLoc: () => myLocTapped = true,
            onFavorites: () => favoritesTapped = true,
            onSettings: () => settingsTapped = true,
          ),
          body: const SizedBox(),
        ),
      );
    }

    await tester.pumpWidget(buildTestScaffold(isListMode: true));

    // Open drawer
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    expect(find.byType(DrawerWidget), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(6));

    // Tap keyword search
    await tester.tap(find.widgetWithText(ListTile, S.current.keyword_search));
    await tester.pumpAndSettle();
    expect(keywordTapped, isTrue);

    // Open drawer again and tap filter rules
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, S.current.filter_rules));
    await tester.pumpAndSettle();
    expect(filterTapped, isTrue);

    // Open drawer and tap toggle view mode
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, S.current.map_mode));
    await tester.pumpAndSettle();
    expect(toggleTapped, isTrue);

    // Open drawer and tap map my loc
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, S.current.map_my_loc_title));
    await tester.pumpAndSettle();
    expect(myLocTapped, isTrue);

    // Open drawer and tap favorites
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, S.current.favorite_stores));
    await tester.pumpAndSettle();
    expect(favoritesTapped, isTrue);

    // Open drawer and tap settings
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, S.current.settings_title));
    await tester.pumpAndSettle();
    expect(settingsTapped, isTrue);
  });
}
