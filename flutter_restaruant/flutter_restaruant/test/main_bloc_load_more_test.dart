import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/flow/main/bloc/bloc_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMainRepository extends Mock implements MainRepository {}

class _Data {
  static const RestaurantEntity existing = RestaurantEntity(
    id: 'existing-1',
    name: '既有店家',
  );

  static const List<RestaurantEntity> nextPage = [
    RestaurantEntity(id: 'next-1', name: '新店家一'),
    RestaurantEntity(id: 'next-2', name: '新店家二'),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // geolocator 走 platform channel，測試環境需攔截，否則 getCurrentPosition 會拋錯
    const MethodChannel channel = MethodChannel(
      'flutter.baseflow.com/geolocator',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'checkPermission':
            case 'requestPermission':
              return 3; // LocationPermission.whileInUse
            case 'getCurrentPosition':
              return <String, dynamic>{
                'latitude': 25.0,
                'longitude': 121.5,
                'timestamp': 0,
                'accuracy': 1.0,
                'altitude': 0.0,
                'altitude_accuracy': 0.0,
                'heading': 0.0,
                'heading_accuracy': 0.0,
                'speed': 0.0,
                'speed_accuracy': 0.0,
              };
            default:
              return null;
          }
        });
  });

  group('MainBloc load-more state sequence', () {
    late _MockMainRepository mockRepo;

    setUp(() {
      mockRepo = _MockMainRepository();
    });

    blocTest<MainBloc, MainState>(
      '首次載入（無既有資料）發出 InProgress → Success',
      build: () {
        when(() => mockRepo.summaryInfoSet).thenReturn(<RestaurantEntity>{});
        when(
          () => mockRepo.fetchYelpSearchInfo(any(), any(), any(), any(), any()),
        ).thenAnswer((_) async => _Data.nextPage);
        return MainBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const FetchSearchInfo()),
      expect: () => [isA<InProgress>(), isA<Success>()],
    );

    blocTest<MainBloc, MainState>(
      '已有資料時再載入發出 LoadMoreInProgress → LoadMoreSuccess',
      build: () {
        when(() => mockRepo.summaryInfoSet).thenReturn({_Data.existing});
        when(
          () => mockRepo.fetchYelpSearchInfo(any(), any(), any(), any(), any()),
        ).thenAnswer((_) async => _Data.nextPage);
        return MainBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const FetchSearchInfo()),
      expect: () => [isA<LoadMoreInProgress>(), isA<LoadMoreSuccess>()],
    );

    blocTest<MainBloc, MainState>(
      '關鍵字過濾中載入更多：LoadMoreInProgress 不得把被過濾掉的項目撈回來',
      build: () {
        when(
          () => mockRepo.summaryInfoSet,
        ).thenReturn({_Data.existing, _Data.nextPage.first});
        when(
          () => mockRepo.fetchYelpSearchInfo(any(), any(), any(), any(), any()),
        ).thenAnswer((_) async => _Data.nextPage);
        return MainBloc(repository: mockRepo);
      },
      seed: () => const Success(summaryInfos: [_Data.existing]),
      act: (bloc) => bloc.add(const FetchSearchInfo()),
      expect: () => [
        isA<LoadMoreInProgress>().having(
          (s) => s.summaryInfos,
          'summaryInfos',
          [_Data.existing],
        ),
        isA<LoadMoreSuccess>(),
      ],
    );

    blocTest<MainBloc, MainState>(
      'LoadMoreInProgress 攜帶當前已載入清單供 UI 續繪',
      build: () {
        when(() => mockRepo.summaryInfoSet).thenReturn({_Data.existing});
        when(
          () => mockRepo.fetchYelpSearchInfo(any(), any(), any(), any(), any()),
        ).thenAnswer((_) async => _Data.nextPage);
        return MainBloc(repository: mockRepo);
      },
      seed: () => const Success(summaryInfos: [_Data.existing]),
      act: (bloc) => bloc.add(const FetchSearchInfo()),
      expect: () => [
        isA<LoadMoreInProgress>().having(
          (s) => s.summaryInfos,
          'summaryInfos',
          [_Data.existing],
        ),
        isA<LoadMoreSuccess>(),
      ],
    );
  });
}
