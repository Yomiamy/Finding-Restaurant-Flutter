import 'package:flutter/material.dart';
import 'package:flutter_restaruant/features/component/cell/restaurant_detail/restaurant_detail_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

class _Data {
  static const String name = 'Gary Danko';
  static const String yelpUrl =
      'https://www.yelp.com/biz/gary-danko-san-francisco';
}

void main() {
  group('RestaurantDetailTitle Widget Tests', () {
    testWidgets('url 非空時店名後顯示 Yelp 外開 icon', (tester) async {
      await _pumpTitle(
        tester,
        const RestaurantDetailTitle(_Data.name, url: _Data.yelpUrl),
      );

      expect(find.text(_Data.name), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
      expect(find.byTooltip(S.current.open_in_yelp), findsOneWidget);
    });

    testWidgets('url 為 null 或空字串時只顯示店名', (tester) async {
      await _pumpTitle(tester, const RestaurantDetailTitle(_Data.name));
      expect(find.text(_Data.name), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsNothing);

      await _pumpTitle(
        tester,
        const RestaurantDetailTitle(_Data.name, url: ''),
      );
      expect(find.text(_Data.name), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsNothing);
    });
  });
}

Future<void> _pumpTitle(WidgetTester tester, Widget title) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(appBar: AppBar(title: title)),
  ),
);
