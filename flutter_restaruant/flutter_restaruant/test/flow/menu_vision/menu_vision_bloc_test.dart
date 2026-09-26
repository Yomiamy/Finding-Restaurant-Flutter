import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaruant/domain/domain_barrel.dart';
import 'package:flutter_restaruant/flow/menu_vision/menu_vision_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class MockMenuVisionRepository extends Mock implements MenuVisionRepository {}

class _Data {
  static final Uint8List sampleBytes = Uint8List.fromList([1, 2, 3, 4]);
}

void main() {
  setUpAll(() => registerFallbackValue(Uint8List(0)));

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

    setUp(() async {
      await S.load(const Locale('zh', 'TW'));
      mockRepo = MockMenuVisionRepository();
    });

    blocTest<MenuVisionBloc, MenuVisionState>(
      'emits [Loading, Success] when camera capture succeeds',
      build: () {
        when(
          () => mockRepo.captureImage(),
        ).thenAnswer((_) async => _Data.sampleBytes);
        when(
          () => mockRepo.analyzeMenuImageBytes(any()),
        ).thenAnswer((_) async => sampleCatalog);
        return MenuVisionBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const CaptureAndAnalyzeMenu()),
      expect: () => [
        const MenuVisionLoading(),
        MenuVisionSuccess(catalog: DishCatalogModel.fromEntity(sampleCatalog)),
      ],
      verify: (_) => verify(() => mockRepo.captureImage()).called(1),
    );

    blocTest<MenuVisionBloc, MenuVisionState>(
      'emits [Loading, Cancelled] when user cancels camera',
      build: () {
        when(() => mockRepo.captureImage()).thenAnswer((_) async => null);
        return MenuVisionBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const CaptureAndAnalyzeMenu()),
      expect: () => [const MenuVisionLoading(), const MenuVisionCancelled()],
    );

    blocTest<MenuVisionBloc, MenuVisionState>(
      'emits [Loading, Failure] when camera capture returns FallbackMarkdown',
      build: () {
        when(
          () => mockRepo.captureImage(),
        ).thenAnswer((_) async => _Data.sampleBytes);
        when(() => mockRepo.analyzeMenuImageBytes(any())).thenAnswer(
          (_) async => const FallbackMarkdownComponent(text: '辨識失敗'),
        );
        return MenuVisionBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const CaptureAndAnalyzeMenu()),
      expect: () => [
        const MenuVisionLoading(),
        MenuVisionFailure(message: '辨識失敗', failedImageBytes: _Data.sampleBytes),
      ],
    );

    blocTest<MenuVisionBloc, MenuVisionState>(
      'emits [Loading, Failure] when repository throws Exception',
      build: () {
        when(() => mockRepo.captureImage()).thenThrow(Exception('模擬相機錯誤'));
        return MenuVisionBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const CaptureAndAnalyzeMenu()),
      expect: () => [const MenuVisionLoading(), isA<MenuVisionFailure>()],
    );

    blocTest<MenuVisionBloc, MenuVisionState>(
      'keeps failedImageBytes for retry when analysis throws after capture',
      build: () {
        when(
          () => mockRepo.captureImage(),
        ).thenAnswer((_) async => _Data.sampleBytes);
        when(
          () => mockRepo.analyzeMenuImageBytes(any()),
        ).thenThrow(const FormatException('Empty menu analysis response'));
        return MenuVisionBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const CaptureAndAnalyzeMenu()),
      expect: () => [
        const MenuVisionLoading(),
        isA<MenuVisionFailure>().having(
          (s) => s.failedImageBytes,
          'failedImageBytes',
          _Data.sampleBytes,
        ),
      ],
    );

    blocTest<MenuVisionBloc, MenuVisionState>(
      'emits [Loading, Success] when gallery pick succeeds',
      build: () {
        when(
          () => mockRepo.pickImageFromGallery(),
        ).thenAnswer((_) async => _Data.sampleBytes);
        when(
          () => mockRepo.analyzeMenuImageBytes(any()),
        ).thenAnswer((_) async => sampleCatalog);
        return MenuVisionBloc(repository: mockRepo);
      },
      act: (bloc) =>
          bloc.add(const CaptureAndAnalyzeMenu(source: ImageSource.gallery)),
      expect: () => [
        const MenuVisionLoading(),
        MenuVisionSuccess(catalog: DishCatalogModel.fromEntity(sampleCatalog)),
      ],
      verify: (_) => verify(() => mockRepo.pickImageFromGallery()).called(1),
    );

    blocTest<MenuVisionBloc, MenuVisionState>(
      'emits [Loading, Success] on RetryMenuAnalysis',
      build: () {
        when(
          () => mockRepo.analyzeMenuImageBytes(any()),
        ).thenAnswer((_) async => sampleCatalog);
        return MenuVisionBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(
        RetryMenuAnalysis(imageBytes: Uint8List.fromList([1, 2, 3])),
      ),
      expect: () => [
        const MenuVisionLoading(),
        MenuVisionSuccess(catalog: DishCatalogModel.fromEntity(sampleCatalog)),
      ],
    );

    blocTest<MenuVisionBloc, MenuVisionState>(
      'Error from repository propagates instead of emitting Failure',
      build: () {
        when(
          () => mockRepo.analyzeMenuImageBytes(any()),
        ).thenThrow(StateError('bug'));
        return MenuVisionBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(
        RetryMenuAnalysis(imageBytes: Uint8List.fromList([1, 2, 3])),
      ),
      expect: () => [const MenuVisionLoading()],
      errors: () => [isA<StateError>()],
    );

    blocTest<MenuVisionBloc, MenuVisionState>(
      'emits [Initial] on ResetMenuVision',
      build: () => MenuVisionBloc(repository: mockRepo),
      seed: () => MenuVisionSuccess(
        catalog: DishCatalogModel.fromEntity(sampleCatalog),
      ),
      act: (bloc) => bloc.add(const ResetMenuVision()),
      expect: () => [const MenuVisionInitial()],
    );
  });
}
