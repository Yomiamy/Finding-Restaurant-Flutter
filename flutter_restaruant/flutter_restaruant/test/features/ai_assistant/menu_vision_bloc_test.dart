import 'dart:typed_data';

import 'package:flutter_restaruant/features/ai_assistant/domain/entities/ai_entities_barrel.dart';
import 'package:flutter_restaruant/features/ai_assistant/domain/repositories/menu_vision_repository.dart';
import 'package:flutter_restaruant/features/ai_assistant/presentation/bloc/menu_vision_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:image_picker/image_picker.dart';

class MockMenuVisionRepository implements MenuVisionRepository {
  A2UIComponent? captureResult;
  A2UIComponent? galleryResult;
  A2UIComponent? analyzeResult;
  bool shouldThrow = false;
  bool captureCalled = false;
  bool galleryCalled = false;

  @override
  Future<A2UIComponent?> captureAndAnalyzeMenu() async {
    captureCalled = true;
    if (shouldThrow) throw Exception('模擬網路錯誤');
    return captureResult;
  }

  @override
  Future<A2UIComponent?> pickFromGalleryAndAnalyzeMenu() async {
    galleryCalled = true;
    if (shouldThrow) throw Exception('模擬相簿錯誤');
    return galleryResult;
  }

  @override
  Future<A2UIComponent> analyzeMenuImageBytes(Uint8List imageBytes) async {
    if (shouldThrow) throw Exception('模擬重試錯誤');
    return analyzeResult ??
        const FallbackMarkdownComponent(text: '未設定結果');
  }
}

void main() {
  final sampleCatalog = DishCatalogComponent(
    restaurantTitle: '居酒屋 一休',
    dishes: [
      DishItemEntity.fromJson({
        'id': 'dish-1',
        'name': '烤飯糰',
        'original_name': '焼きおにぎり',
        'category': 'main',
        'price': 350,
        'allergens': <Map<String, Object?>>[],
        'spice_level': 0,
      }),
    ],
  );

  group('MenuVisionBloc Tests', () {
    late MockMenuVisionRepository mockRepo;

    setUp(() {
      mockRepo = MockMenuVisionRepository();
    });

    blocTest<MenuVisionBloc, MenuVisionState>(
      'emits [Loading, Success] when camera capture succeeds',
      build: () {
        mockRepo.captureResult = sampleCatalog;
        return MenuVisionBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const CaptureAndAnalyzeMenu()),
      expect: () => [
        const MenuVisionLoading(),
        MenuVisionSuccess(catalog: sampleCatalog),
      ],
      verify: (_) => expect(mockRepo.captureCalled, isTrue),
    );

    blocTest<MenuVisionBloc, MenuVisionState>(
      'emits [Loading, Cancelled] when user cancels camera',
      build: () {
        mockRepo.captureResult = null;
        return MenuVisionBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const CaptureAndAnalyzeMenu()),
      expect: () => [
        const MenuVisionLoading(),
        const MenuVisionCancelled(),
      ],
    );

    blocTest<MenuVisionBloc, MenuVisionState>(
      'emits [Loading, Failure] when camera capture returns FallbackMarkdown',
      build: () {
        mockRepo.captureResult = const FallbackMarkdownComponent(
          text: '辨識失敗',
        );
        return MenuVisionBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const CaptureAndAnalyzeMenu()),
      expect: () => [
        const MenuVisionLoading(),
        const MenuVisionFailure(message: '辨識失敗'),
      ],
    );

    blocTest<MenuVisionBloc, MenuVisionState>(
      'emits [Loading, Failure] when repository throws Exception',
      build: () {
        mockRepo.shouldThrow = true;
        return MenuVisionBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const CaptureAndAnalyzeMenu()),
      expect: () => [
        const MenuVisionLoading(),
        isA<MenuVisionFailure>(),
      ],
    );

    blocTest<MenuVisionBloc, MenuVisionState>(
      'emits [Loading, Success] when gallery pick succeeds',
      build: () {
        mockRepo.galleryResult = sampleCatalog;
        return MenuVisionBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(
        const CaptureAndAnalyzeMenu(source: ImageSource.gallery),
      ),
      expect: () => [
        const MenuVisionLoading(),
        MenuVisionSuccess(catalog: sampleCatalog),
      ],
      verify: (_) => expect(mockRepo.galleryCalled, isTrue),
    );

    blocTest<MenuVisionBloc, MenuVisionState>(
      'emits [Loading, Success] on RetryMenuAnalysis',
      build: () {
        mockRepo.analyzeResult = sampleCatalog;
        return MenuVisionBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(
        RetryMenuAnalysis(imageBytes: Uint8List.fromList([1, 2, 3])),
      ),
      expect: () => [
        const MenuVisionLoading(),
        MenuVisionSuccess(catalog: sampleCatalog),
      ],
    );

    blocTest<MenuVisionBloc, MenuVisionState>(
      'emits [Initial] on ResetMenuVision',
      build: () => MenuVisionBloc(repository: mockRepo),
      seed: () => MenuVisionSuccess(catalog: sampleCatalog),
      act: (bloc) => bloc.add(const ResetMenuVision()),
      expect: () => [const MenuVisionInitial()],
    );
  });
}
