import 'package:flutter/material.dart';
import 'package:flutter_restaruant/features/component/cell/restaurant_detail/restaurant_info_cell.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/gen/assets.gen.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

class _Data {
  static const String phone = '+14157492060';
  static const String displayPhone = '(415) 749-2060';
  static const String price = '\$\$';
  static const String cafe = '咖啡廳';
  static const String yelpUrl =
      'https://www.yelp.com/biz/gary-danko-san-francisco';
}

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

      expect(find.text(S.current.business_status_open), findsOneWidget);
      expect(find.text('+886212345678'), findsOneWidget);
      expect(find.text('咖啡廳'), findsOneWidget);

      final decoratedBox = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text(S.current.business_status_open),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF2E7D32));
    });

    testWidgets('已打烊時標籤顯示 CLOSED', (tester) async {
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

      expect(find.text(S.current.business_status_closed), findsOneWidget);
    });

    testWidgets('靜態地圖載入與錯誤回退使用 iconStaticMapPlachold 專屬佔位圖', (tester) async {
      const detail = RestaurantDetailEntity(
        name: 'Map Restaurant',
        hours: [RestaurantHoursEntity(isOpenNow: true, open: [])],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeData.materialLight,
          localizationsDelegates: const [S.delegate],
          home: const Scaffold(
            body: RestaurantInfoCell(
              detailInfo: detail,
              staticMapUrl: 'https://maps.googleapis.com/maps/api/staticmap',
            ),
          ),
        ),
      );

      final fadeInImageFinder = find.byType(FadeInImage);
      expect(fadeInImageFinder, findsOneWidget);

      const expectedAssetPath = 'images/icon_static_map_plachold.png';
      expect(
        Assets.images.iconStaticMapPlachold.path,
        expectedAssetPath,
      );

      final fadeInImage = tester.widget<FadeInImage>(fadeInImageFinder);
      final placeholder = fadeInImage.placeholder;
      final AssetImage placeholderAssetImage;
      if (placeholder is ResizeImage) {
        placeholderAssetImage = placeholder.imageProvider as AssetImage;
      } else {
        placeholderAssetImage = placeholder as AssetImage;
      }
      expect(
        placeholderAssetImage.assetName,
        expectedAssetPath,
      );

      final errorWidget = fadeInImage.imageErrorBuilder!(
        tester.element(fadeInImageFinder),
        Exception('Network error'),
        null,
      ) as Image;
      final errorImageProvider = errorWidget.image as AssetImage;
      expect(
        errorImageProvider.assetName,
        expectedAssetPath,
      );
      expect(errorWidget.fit, BoxFit.cover);
    });

    testWidgets('displayPhone 非空時電話列顯示 displayPhone', (tester) async {
      await _pumpCell(
        tester,
        const RestaurantDetailEntity(
          phone: _Data.phone,
          displayPhone: _Data.displayPhone,
        ),
      );

      expect(find.text(_Data.displayPhone), findsOneWidget);
      expect(find.text(_Data.phone), findsNothing);
    });

    testWidgets('displayPhone 為空字串時回退顯示 phone', (tester) async {
      await _pumpCell(
        tester,
        const RestaurantDetailEntity(phone: _Data.phone, displayPhone: ''),
      );

      expect(find.text(_Data.phone), findsOneWidget);
    });

    testWidgets('phone 為空時即使有 displayPhone 也不顯示電話列', (tester) async {
      await _pumpCell(
        tester,
        const RestaurantDetailEntity(displayPhone: _Data.displayPhone),
      );

      expect(find.text(_Data.displayPhone), findsNothing);
    });

    testWidgets('價位併入分類列最前面', (tester) async {
      await _pumpCell(
        tester,
        const RestaurantDetailEntity(
          price: _Data.price,
          categories: [RestaurantCategoryEntity(title: _Data.cafe)],
        ),
      );

      expect(find.text('${_Data.price} · ${_Data.cafe}'), findsOneWidget);
    });

    testWidgets('無分類時分類列只顯示價位', (tester) async {
      await _pumpCell(tester, const RestaurantDetailEntity(price: _Data.price));

      expect(find.text(_Data.price), findsOneWidget);
    });

    testWidgets('price 為空字串時分類列與現行一致', (tester) async {
      await _pumpCell(
        tester,
        const RestaurantDetailEntity(
          price: '',
          categories: [RestaurantCategoryEntity(title: _Data.cafe)],
        ),
      );

      expect(find.text(_Data.cafe), findsOneWidget);
    });

    testWidgets('url 非空時 cell 不再顯示 Yelp 連結', (tester) async {
      await _pumpCell(tester, const RestaurantDetailEntity(url: _Data.yelpUrl));

      expect(find.text(S.current.open_in_yelp), findsNothing);
      expect(find.byIcon(Icons.open_in_new), findsNothing);
    });

    testWidgets('新欄位全有值且分類多到截斷時不 overflow', (tester) async {
      await _pumpCell(
        tester,
        RestaurantDetailEntity(
          id: 'gary-danko-id',
          phone: _Data.phone,
          displayPhone: _Data.displayPhone,
          price: _Data.price,
          url: _Data.yelpUrl,
          categories: List.generate(
            20,
            (i) => RestaurantCategoryEntity(title: 'Category $i'),
          ),
          location: const RestaurantLocationEntity(
            displayAddress: ['800 N Point St, San Francisco, CA 94109'],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpCell(WidgetTester tester, RestaurantDetailEntity detail) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppThemeData.materialLight,
        localizationsDelegates: const [S.delegate],
        home: Scaffold(
          body: RestaurantInfoCell(detailInfo: detail, staticMapUrl: ''),
        ),
      ),
    );
