import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_restaruant/domain/domain_barrel.dart';
import 'package:flutter_restaruant/domain/entities/a2ui_fallback_strings.dart';
import 'package:flutter_restaruant/flow/menu_vision/menu_vision_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

/// 特性測試：Menu Vision 畫面在「全缺值／全有值」下的顯示。T2 之後禁止修改。
class _FakeRepo implements MenuVisionRepository {
  _FakeRepo(this.data);
  final Map<String, Object?> data;

  @override
  Future<Uint8List?> captureImage() async => Uint8List.fromList([1]);
  @override
  Future<Uint8List?> pickImageFromGallery() async => Uint8List.fromList([1]);
  @override
  Future<A2UIComponent?> captureAndAnalyzeMenu() async => null;
  @override
  Future<A2UIComponent?> pickFromGalleryAndAnalyzeMenu() async => null;
  @override
  Future<A2UIComponent> analyzeMenuImageBytes(Uint8List imageBytes) async =>
      A2UIComponent.fromJson({'component_type': 'dish_catalog', 'data': data});
}

Future<void> _pumpCatalog(WidgetTester tester, Map<String, Object?> data) async {
  final bloc = MenuVisionBloc(repository: _FakeRepo(data));
  addTearDown(bloc.close);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: MenuVisionSheet(bloc: bloc))));
  await tester.tap(find.byKey(const Key('take_photo_button')));
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump();
}

void main() {
  setUpAll(() async => S.load(const Locale('zh', 'TW')));

  testWidgets('全欄位有值', (tester) async {
    await _pumpCatalog(tester, {
      'restaurant_title': '一風堂',
      'currency': 'JPY',
      'dishes': [
        {
          'id': 'd1',
          'name': '豚骨拉麵',
          'original_name': 'とんこつラーメン',
          'price': 280,
          'category': 'main',
          'allergens': [
            {'name': '蛋', 'risk_level': 'contains', 'note': 'n'},
            {'name': '花生', 'risk_level': 'may_contain', 'note': 'n'},
            {'name': '芝麻', 'risk_level': 'none', 'note': 'n'},
          ],
          'dietary_tags': ['招牌'],
          'spice_level': 2,
          'ingredients': ['叉燒', '糖心蛋'],
          'chef_recommendation_score': 0.9,
        },
      ],
    });
    expect(find.text('全部 (1)'), findsOneWidget);
    expect(find.text('主食 (1)'), findsOneWidget);
    expect(find.text('豚骨拉麵'), findsOneWidget);
    expect(find.text('とんこつラーメン'), findsOneWidget);
    expect(find.text('¥280'), findsOneWidget);
    expect(find.text('🌶️🌶️'), findsOneWidget);
    expect(find.text('主要食材：叉燒、糖心蛋'), findsOneWidget);
    expect(find.text('蛋 (含)'), findsOneWidget);
    expect(find.text('花生 (可能含有)'), findsOneWidget);
    expect(find.textContaining('芝麻'), findsNothing);
    expect(find.text('招牌'), findsOneWidget);
  });

  testWidgets('全欄位缺值', (tester) async {
    await _pumpCatalog(tester, {
      'dishes': [<String, Object?>{}],
    });
    expect(find.text('全部 (1)'), findsOneWidget);
    expect(find.text('其他 (1)'), findsOneWidget);
    expect(find.textContaining('NT\$'), findsNothing);
    expect(find.text(S.current.dish_card_spice_level_prefix), findsNothing);
    expect(find.textContaining(S.current.dish_card_ingredients_prefix), findsNothing);
    expect(find.byType(Chip), findsNothing);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    expect(find.byIcon(Icons.help_outline_rounded), findsNothing);
  });

  testWidgets('currency 缺值 → TWD；小數價格', (tester) async {
    await _pumpCatalog(tester, {
      'dishes': [
        {'name': 'A', 'price': 60},
        {'name': 'B', 'price': 60.5},
      ],
    });
    expect(find.text('NT\$60'), findsOneWidget);
    expect(find.text('NT\$60.50'), findsOneWidget);
  });

  testWidgets('allergen：缺 name 顯示空名；缺 risk_level 視為 none 不顯示', (tester) async {
    await _pumpCatalog(tester, {
      'dishes': [
        {
          'name': 'A',
          'allergens': [
            {'risk_level': 'contains'},
            {'name': '花生'},
          ],
        },
      ],
    });
    expect(find.text(' (含)'), findsOneWidget);
    expect(find.textContaining('花生'), findsNothing);
  });

  testWidgets('category 缺值與未知值都歸到其他', (tester) async {
    await _pumpCatalog(tester, {
      'dishes': [
        {'name': 'A'},
        {'name': 'B', 'category': 'xyz'},
      ],
    });
    expect(find.text('其他 (2)'), findsOneWidget);
  });

  testWidgets('dishes 缺值 → 失敗畫面顯示降級文字', (tester) async {
    await _pumpCatalog(tester, const {});
    expect(find.text(S.current.menu_vision_failure_title), findsOneWidget);
    expect(find.text(A2UIFallbackStrings.dishCatalogEmpty), findsOneWidget);
  });
}
