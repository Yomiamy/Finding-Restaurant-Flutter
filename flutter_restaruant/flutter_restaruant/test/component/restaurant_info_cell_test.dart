import 'package:flutter/material.dart';
import 'package:flutter_restaruant/component/cell/restaurant_detail/restaurant_info_cell.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RestaurantInfoCell Widget Tests', () {
    testWidgets('營業中時標籤顯示 OPEN 且為綠底', (tester) async {
      const detail = RestaurantDetailEntity(
        name: 'Test Restaurant',
        phone: '+886212345678',
        rating: 4.5,
        reviewCount: 100,
        categories: [RestaurantCategoryEntity(alias: 'cafe', title: '咖啡廳')],
        location: RestaurantLocationEntity(
          address1: '信義路五段7號',
          displayAddress: ['台北市信義區信義路五段7號'],
        ),
        hours: [RestaurantHoursEntity(isOpenNow: true, open: [])],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeData.materialLight,
          localizationsDelegates: const [S.delegate],
          home: const Scaffold(
            body: RestaurantInfoCell(detailInfo: detail, staticMapUrl: ''),
          ),
        ),
      );

      expect(find.text('OPEN'), findsOneWidget);
      expect(find.text('+886212345678'), findsOneWidget);
      expect(find.text('咖啡廳'), findsOneWidget);

      final decoratedBox = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('OPEN'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF2E7D32));
    });

    testWidgets('已打烊時標籤顯示 CLOSE', (tester) async {
      const detail = RestaurantDetailEntity(
        name: 'Closed Restaurant',
        rating: 3.0,
        reviewCount: 20,
        hours: [RestaurantHoursEntity(isOpenNow: false, open: [])],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeData.materialLight,
          localizationsDelegates: const [S.delegate],
          home: const Scaffold(
            body: RestaurantInfoCell(detailInfo: detail, staticMapUrl: ''),
          ),
        ),
      );

      expect(find.text('CLOSE'), findsOneWidget);
    });
  });
}
