import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaruant/component/cell/restaurant_detail/restaurant_comment_cell.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

class _Data {
  static const review = ReviewDetailEntity(
    id: 'r1',
    rating: 4,
    user: ReviewerEntity(name: 'Reviewer'),
    text: 'Nice food',
    url: 'https://www.yelp.com/biz/test?hrid=r1',
  );
}

void main() {
  setUpAll(() async {
    await S.load(const Locale('zh', 'TW'));
  });

  // 鎖住 UI-9.1：評論區不得在建構時依賴只有 Android／iOS 實作的瀏覽器元件。
  testWidgets('macOS 上評論區可正常建構並顯示評論', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RestaurantCommentCell(reviewInfos: [_Data.review]),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Reviewer'), findsOneWidget);
      expect(find.text('Nice food'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
