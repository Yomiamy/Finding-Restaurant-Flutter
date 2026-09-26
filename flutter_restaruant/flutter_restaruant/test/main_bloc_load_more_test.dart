import 'package:flutter/services.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/flow/main/bloc/bloc_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMainRepository extends Mock implements MainRepository {}

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
    late MockMainRepository mockRepo;
    late MainBloc bloc;

    tearDown(() => bloc.close());

    test('首次載入（無既有資料）發出 InProgress → Success', () async {
      mockRepo = MockMainRepository();
      when(() => mockRepo.summaryInfoSet).thenReturn(<RestaurantEntity>{});
      when(
        () => mockRepo.fetchYelpSearchInfo(any(), any(), any(), any(), any()),
      ).thenAnswer((_) async => _Data.nextPage);
      bloc = MainBloc(repository: mockRepo);

      bloc.add(const FetchSearchInfo());

      await expectLater(
        bloc.stream,
        emitsInOrder([isA<InProgress>(), isA<Success>()]),
      );
    });

    test('已有資料時再載入發出 LoadMoreInProgress → LoadMoreSuccess', () async {
      mockRepo = MockMainRepository();
      when(() => mockRepo.summaryInfoSet).thenReturn({_Data.existing});
      when(
        () => mockRepo.fetchYelpSearchInfo(any(), any(), any(), any(), any()),
      ).thenAnswer((_) async => _Data.nextPage);
      bloc = MainBloc(repository: mockRepo);

      bloc.add(const FetchSearchInfo());

      await expectLater(
        bloc.stream,
        emitsInOrder([isA<LoadMoreInProgress>(), isA<LoadMoreSuccess>()]),
      );
    });

    test('關鍵字過濾中載入更多：LoadMoreInProgress 不得把被過濾掉的項目撈回來', () async {
      // repository 的 set 有 2 筆，但畫面因關鍵字過濾只顯示 1 筆。
      // 載入中若改讀 summaryInfoSet，畫面會從 1 筆突然跳成 2 筆。
      mockRepo = MockMainRepository();
      when(
        () => mockRepo.summaryInfoSet,
      ).thenReturn({_Data.existing, _Data.nextPage.first});
      when(
        () => mockRepo.fetchYelpSearchInfo(any(), any(), any(), any(), any()),
      ).thenAnswer((_) async => _Data.nextPage);
      bloc = MainBloc(repository: mockRepo);

      // 先讓畫面進入「只顯示 1 筆」的過濾後狀態
      bloc.emit(const Success(summaryInfos: [_Data.existing]));

      bloc.add(const FetchSearchInfo());

      final MainState first = await bloc.stream.first;

      expect(first, isA<LoadMoreInProgress>());
      expect((first as LoadMoreInProgress).summaryInfos, [
        _Data.existing,
      ], reason: '載入中應沿用畫面當前清單，而非 repository 的全量 set');
    });

    test('LoadMoreInProgress 攜帶當前已載入清單供 UI 續繪', () async {
      mockRepo = MockMainRepository();
      when(() => mockRepo.summaryInfoSet).thenReturn({_Data.existing});
      when(
        () => mockRepo.fetchYelpSearchInfo(any(), any(), any(), any(), any()),
      ).thenAnswer((_) async => _Data.nextPage);
      bloc = MainBloc(repository: mockRepo);

      // 真實流程中，畫面有資料必然來自前一次 Success/LoadMoreSuccess
      bloc.emit(const Success(summaryInfos: [_Data.existing]));

      bloc.add(const FetchSearchInfo());

      final MainState first = await bloc.stream.first;

      expect(first, isA<LoadMoreInProgress>());
      expect((first as LoadMoreInProgress).summaryInfos, [_Data.existing]);
    });
  });
}
