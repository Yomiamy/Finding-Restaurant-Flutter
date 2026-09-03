import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_restaruant/component/ad/banner_ad.dart';
import 'package:flutter_restaruant/component/ad/banner_ad_state.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  group('BannerAD Widget Tests', () {
    testWidgets('載入前預留 50dp 固定佔位高度與頂部邊框以消滅版面突跳 (CLS)', (tester) async {
      final completer = Completer<InitializationStatus>();
      final adState = BannerADState(completer.future);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BannerAD(adState: adState),
          ),
        ),
      );

      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.minHeight == ThemeSize.space50,
      );
      expect(containerFinder, findsOneWidget);

      final container = tester.widget<Container>(containerFinder);
      expect(container.constraints?.maxHeight, equals(ThemeSize.space50));

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, equals(ThemeColor.colorfffbf7));
      expect(decoration?.border?.top.color, equals(ThemeColor.color9e9e9e));
      expect(decoration?.border?.top.width, equals(0.5));
    });
  });
}
