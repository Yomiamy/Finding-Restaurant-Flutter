import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_restaruant/features/ai_assistant/domain/entities/ai_entities_barrel.dart';
import 'package:flutter_restaruant/features/ai_assistant/domain/repositories/menu_vision_repository.dart';
import 'package:flutter_restaruant/features/ai_assistant/presentation/bloc/menu_vision_bloc.dart';
import 'package:flutter_restaruant/features/ai_assistant/presentation/view/allergen_badge.dart';
import 'package:flutter_restaruant/features/ai_assistant/presentation/view/dish_card.dart';
import 'package:flutter_restaruant/features/ai_assistant/presentation/view/menu_vision_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

class MockMenuVisionRepository implements MenuVisionRepository {
  A2UIComponent? captureResult;
  A2UIComponent? galleryResult;
  A2UIComponent? analyzeResult;
  bool shouldThrow = false;

  @override
  Future<Uint8List?> captureImage() {
    if (shouldThrow) return Future.error(Exception('模擬錯誤'));
    if (captureResult == null) return Future.value(null);
    return Future.value(Uint8List.fromList([1, 2, 3]));
  }

  @override
  Future<Uint8List?> pickImageFromGallery() {
    if (shouldThrow) return Future.error(Exception('模擬錯誤'));
    if (galleryResult == null) return Future.value(null);
    return Future.value(Uint8List.fromList([1, 2, 3]));
  }

  @override
  Future<A2UIComponent?> captureAndAnalyzeMenu() {
    if (shouldThrow) return Future.error(Exception('模擬錯誤'));
    return Future.value(captureResult);
  }

  @override
  Future<A2UIComponent?> pickFromGalleryAndAnalyzeMenu() {
    if (shouldThrow) return Future.error(Exception('模擬錯誤'));
    return Future.value(galleryResult);
  }

  @override
  Future<A2UIComponent> analyzeMenuImageBytes(Uint8List imageBytes) {
    if (shouldThrow) return Future.error(Exception('模擬錯誤'));
    return Future.value(
      analyzeResult ??
          captureResult ??
          galleryResult ??
          const FallbackMarkdownComponent(text: '無結果'),
    );
  }
}

void main() {
  final sampleDish = DishItemEntity.fromJson({
    'id': 'dish-101',
    'name': '特製豚骨拉麵',
    'original_name': '特製とんこつラーメン',
    'price': 280,
    'category': 'main',
    'spice_level': 2,
    'ingredients': ['豚骨高湯', '叉燒', '糖心蛋', '青蔥'],
    'dietary_tags': ['人氣招牌'],
    'allergens': [
      {'name': '蛋', 'risk_level': 'contains', 'note': '含糖心蛋'},
      {'name': '花生', 'risk_level': 'may_contain', 'note': '生產線接觸'},
    ],
  });

  final sampleCatalog = DishCatalogComponent(
    restaurantTitle: '一風堂',
    dishes: [
      sampleDish,
      DishItemEntity.fromJson({
        'id': 'dish-102',
        'name': '日式煎餃',
        'original_name': '焼き餃子',
        'price': 120,
        'category': 'appetizer',
        'spice_level': 0,
        'allergens': <Map<String, Object?>>[],
      }),
    ],
  );

  group('AllergenBadge Widget Tests', () {
    testWidgets('renders allergen badge with risk level contains', (tester) async {
      const allergen = AllergenInfo(
        name: '海鮮',
        riskLevel: AllergenRiskLevel.contains,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllergenBadge(allergen: allergen),
          ),
        ),
      );

      expect(find.text('海鮮 (含)'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('renders allergen badge with risk level mayContain', (tester) async {
      const allergen = AllergenInfo(
        name: '花生',
        riskLevel: AllergenRiskLevel.mayContain,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllergenBadge(allergen: allergen),
          ),
        ),
      );

      expect(find.text('花生 (可能含有)'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
    });
  });

  group('DishCard Widget Tests', () {
    testWidgets('renders dish card details correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DishCard(dish: sampleDish, currency: 'JPY'),
          ),
        ),
      );

      expect(find.text('特製豚骨拉麵'), findsOneWidget);
      expect(find.text('特製とんこつラーメン'), findsOneWidget);
      expect(find.text('¥280'), findsOneWidget);
      expect(find.text('🌶️🌶️'), findsOneWidget);
      expect(find.text('主要食材：豚骨高湯、叉燒、糖心蛋、青蔥'), findsOneWidget);
      expect(find.text('蛋 (含)'), findsOneWidget);
      expect(find.text('花生 (可能含有)'), findsOneWidget);
      expect(find.text('人氣招牌'), findsOneWidget);
    });

    testWidgets('formats price correctly for TWD currency', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DishCard(dish: sampleDish, currency: 'TWD'),
          ),
        ),
      );

      expect(find.text('NT\$280'), findsOneWidget);
    });
  });

  group('MenuVisionSheet Widget Tests', () {
    late MockMenuVisionRepository mockRepo;
    late MenuVisionBloc bloc;

    setUp(() {
      mockRepo = MockMenuVisionRepository();
      bloc = MenuVisionBloc(repository: mockRepo);
    });

    tearDown(() {
      bloc.close();
    });

    testWidgets('renders initial prompt with take photo and gallery buttons',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuVisionSheet(
              restaurantTitle: '一風堂',
              bloc: bloc,
            ),
          ),
        ),
      );

      expect(find.text('AI 菜單視覺翻譯'), findsOneWidget);
      expect(find.text('一風堂'), findsOneWidget);
      expect(find.text('拍下菜單，AI 立即辨識'), findsOneWidget);
      expect(find.byKey(const Key('take_photo_button')), findsOneWidget);
      expect(find.byKey(const Key('gallery_pick_button')), findsOneWidget);
    });

    testWidgets('tapping take photo triggers capture and transitions to success',
        (tester) async {
      mockRepo.captureResult = sampleCatalog;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuVisionSheet(
              restaurantTitle: '一風堂',
              bloc: bloc,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('take_photo_button')));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(find.text('全部 (2)'), findsOneWidget);
      expect(find.text('主食 (1)'), findsOneWidget);
      expect(find.text('前菜 (1)'), findsOneWidget);
      expect(find.text('特製豚骨拉麵'), findsOneWidget);
    });

    testWidgets('displays error and retry when capture fails', (tester) async {
      mockRepo.shouldThrow = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuVisionSheet(
              restaurantTitle: '一風堂',
              bloc: bloc,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('take_photo_button')));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(find.text('辨識未能完成'), findsOneWidget);
      expect(find.text('重新拍攝'), findsOneWidget);
      expect(find.text('相簿重選'), findsOneWidget);
    });

    testWidgets('displays cancelled view when user cancels camera', (tester) async {
      mockRepo.captureResult = null;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuVisionSheet(
              restaurantTitle: '一風堂',
              bloc: bloc,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('take_photo_button')));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(find.text('已取消選取照片'), findsOneWidget);
    });
  });
}
