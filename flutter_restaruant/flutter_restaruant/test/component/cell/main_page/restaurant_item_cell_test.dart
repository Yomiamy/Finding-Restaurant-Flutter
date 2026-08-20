import 'package:flutter/material.dart';
import 'package:flutter_restaruant/component/cell/main_page/restaurant_item_cell.dart';
import 'package:flutter_restaruant/component/rating_stars.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

/// 取出 cell 內 FadeInImage 的 imageErrorBuilder，直接在受限寬度下渲染它。
///
/// widget test 沒有真實網路，FadeInImage 不會走到 error 分支，
/// 因此改為直接驗證 builder 產出的 widget 是否自帶尺寸約束 ——
/// 那正是溢出的根因所在。
void main() {
  testWidgets('imageErrorBuilder 產出的圖不得撐爆受限的 Row', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [S.delegate],
        home: Scaffold(
          body: RestaurantItemCell(
            summaryInfo: RestaurantEntity(
              name: 'The Lounge',
              imageUrl: 'https://invalid.invalid/nope.png',
              distance: 583.37,
              rating: 4.0,
              reviewCount: 12,
            ),
          ),
        ),
      ),
    );

    final fadeInImage = tester.widget<FadeInImage>(find.byType(FadeInImage));
    final errorWidget = fadeInImage.imageErrorBuilder!(
      tester.element(find.byType(FadeInImage)),
      Object(),
      null,
    );

    // 放進一個比原圖(1280px)窄得多的 Row，未約束就會溢出。
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: Row(
              children: <Widget>[
                errorWidget,
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);

    final imageSize = tester.getSize(find.byType(Image).last);
    expect(imageSize.width, ThemeSize.size110);
  });

  // 地圖底部 PageView 的卡片寬度約 298px（360dp 螢幕 × viewportFraction 0.85
  // 再扣左右 padding）。扣掉圖片 110 + padding 15 + 間距 10 後只剩約 163px，
  // 舊版把這段用三個等權 Expanded 三等分 → 星星只分到約 54px，但它需要
  // 5 × 16 = 80px，於是 RenderFlex overflow。
  testWidgets('窄卡片下評分列不得溢出，且星星須完整顯示', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [S.delegate],
        home: Scaffold(
          body: SizedBox(
            width: 298,
            child: RestaurantItemCell(
              summaryInfo: RestaurantEntity(
                name: 'The Lounge Restaurant With A Long Name',
                distance: 583.37,
                rating: 4.5,
                reviewCount: 1234,
                price: r'$$$$',
              ),
            ),
          ),
        ),
      ),
    );

    // overflow 在 widget test 中會以 exception 形式浮現。
    expect(tester.takeException(), isNull);

    // 星星未被壓縮：5 顆 × 16px。
    final starsSize = tester.getSize(find.byType(RatingStars));
    expect(starsSize.width, 5 * ThemeSize.size16);
  });
}
