import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_restaruant/features/ai_assistant/data/repositories/menu_vision_repo.dart';
import 'package:flutter_restaruant/features/ai_assistant/domain/entities/ai_entities_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class FakeImagePicker extends ImagePicker {
  FakeImagePicker({this.fileToReturn});

  final XFile? fileToReturn;
  ImageSource? lastSource;
  double? lastMaxWidth;
  double? lastMaxHeight;
  int? lastImageQuality;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    lastSource = source;
    lastMaxWidth = maxWidth;
    lastMaxHeight = maxHeight;
    lastImageQuality = imageQuality;
    return fileToReturn;
  }
}

void main() {
  final sampleValidJson = jsonEncode({
    'restaurant_title': '居酒屋 一休',
    'currency': 'JPY',
    'dishes': [
      {
        'id': 'dish-1',
        'name': '烤飯糰',
        'original_name': '焼きおにぎり',
        'category': 'main',
        'price': 350,
        'ingredients': ['越光米', '醬油'],
        'allergens': [
          {'name': '大豆', 'risk_level': 'contains', 'note': '醬油含有'},
        ],
        'spice_level': 0,
        'dietary_tags': ['vegetarian'],
        'chef_recommendation_score': 0.88,
      },
    ],
  });

  group('MenuVisionRepo Unit Tests', () {
    test('analyzeMenuImageBytes parses valid JSON to DishCatalogComponent', () async {
      final repo = MenuVisionRepo(
        analyzer: (bytes) async => sampleValidJson,
      );

      final result = await repo.analyzeMenuImageBytes(Uint8List.fromList([1, 2, 3]));
      expect(result, isA<DishCatalogComponent>());

      final catalog = result as DishCatalogComponent;
      expect(catalog.restaurantTitle, '居酒屋 一休');
      expect(catalog.currency, 'JPY');
      expect(catalog.dishes.length, 1);

      final dish = catalog.dishes.first;
      expect(dish.id, 'dish-1');
      expect(dish.name, '烤飯糰');
      expect(dish.originalName, '焼きおにぎり');
      expect(dish.category, DishCategory.main);
      expect(dish.price, 350.0);
      expect(dish.allergens.length, 1);
      expect(dish.allergens.first.riskLevel, AllergenRiskLevel.contains);
    });

    test('analyzeMenuImageBytes falls back to FallbackMarkdownComponent on empty response', () async {
      final repo = MenuVisionRepo(
        analyzer: (bytes) async => '',
      );

      final result = await repo.analyzeMenuImageBytes(Uint8List.fromList([1, 2, 3]));
      expect(result, isA<FallbackMarkdownComponent>());
      expect((result as FallbackMarkdownComponent).text, contains('未能取得'));
    });

    test('analyzeMenuImageBytes falls back on Exception during analyzer', () async {
      final repo = MenuVisionRepo(
        analyzer: (bytes) async => throw Exception('網路連線逾時 (HTTP 429)'),
      );

      final result = await repo.analyzeMenuImageBytes(Uint8List.fromList([1, 2, 3]));
      expect(result, isA<FallbackMarkdownComponent>());
      expect((result as FallbackMarkdownComponent).text, contains('菜單辨識異常'));
    });

    test('captureAndAnalyzeMenu returns null when user cancels camera', () async {
      final picker = FakeImagePicker(fileToReturn: null);
      final repo = MenuVisionRepo(
        picker: picker,
        analyzer: (bytes) async => sampleValidJson,
      );

      final result = await repo.captureAndAnalyzeMenu();
      expect(result, isNull);
      expect(picker.lastSource, ImageSource.camera);
      expect(picker.lastMaxWidth, 1500);
      expect(picker.lastMaxHeight, 1500);
      expect(picker.lastImageQuality, 85);
    });

    test('captureAndAnalyzeMenu succeeds with photo', () async {
      final dummyBytes = Uint8List.fromList([10, 20, 30]);
      final dummyFile = XFile.fromData(dummyBytes, name: 'menu.jpg');
      final picker = FakeImagePicker(fileToReturn: dummyFile);

      final repo = MenuVisionRepo(
        picker: picker,
        analyzer: (bytes) async => sampleValidJson,
      );

      final result = await repo.captureAndAnalyzeMenu();
      expect(result, isA<DishCatalogComponent>());
      expect((result as DishCatalogComponent).dishes.first.name, '烤飯糰');
    });

    test('pickFromGalleryAndAnalyzeMenu returns null when user cancels gallery', () async {
      final picker = FakeImagePicker(fileToReturn: null);
      final repo = MenuVisionRepo(
        picker: picker,
        analyzer: (bytes) async => sampleValidJson,
      );

      final result = await repo.pickFromGalleryAndAnalyzeMenu();
      expect(result, isNull);
      expect(picker.lastSource, ImageSource.gallery);
    });

    test('pickFromGalleryAndAnalyzeMenu succeeds with gallery image', () async {
      final dummyBytes = Uint8List.fromList([40, 50, 60]);
      final dummyFile = XFile.fromData(dummyBytes, name: 'gallery.jpg');
      final picker = FakeImagePicker(fileToReturn: dummyFile);

      final repo = MenuVisionRepo(
        picker: picker,
        analyzer: (bytes) async => sampleValidJson,
      );

      final result = await repo.pickFromGalleryAndAnalyzeMenu();
      expect(result, isA<DishCatalogComponent>());
    });
  });
}
