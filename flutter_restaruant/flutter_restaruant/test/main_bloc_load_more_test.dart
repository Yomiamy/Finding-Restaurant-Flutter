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

void _setMockGeolocator() {
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // geolocator 走 platform channel，測試環境需攔截，否則 getCurrentPosition 會拋錯
    _setMockGeolocator();
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
          () => mockRepo.fetchYelpSearchInfo(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            location: any(named: 'location'),
            price: any(named: 'price'),
            openAt: any(named: 'openAt'),
            sortByStr: any(named: 'sortByStr'),
            term: any(named: 'term'),
            categories: any(named: 'categories'),
            radius: any(named: 'radius'),
            openNow: any(named: 'openNow'),
          ),
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
          () => mockRepo.fetchYelpSearchInfo(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            location: any(named: 'location'),
            price: any(named: 'price'),
            openAt: any(named: 'openAt'),
            sortByStr: any(named: 'sortByStr'),
            term: any(named: 'term'),
            categories: any(named: 'categories'),
            radius: any(named: 'radius'),
            openNow: any(named: 'openNow'),
          ),
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
          () => mockRepo.fetchYelpSearchInfo(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            location: any(named: 'location'),
            price: any(named: 'price'),
            openAt: any(named: 'openAt'),
            sortByStr: any(named: 'sortByStr'),
            term: any(named: 'term'),
            categories: any(named: 'categories'),
            radius: any(named: 'radius'),
            openNow: any(named: 'openNow'),
          ),
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
          () => mockRepo.fetchYelpSearchInfo(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            location: any(named: 'location'),
            price: any(named: 'price'),
            openAt: any(named: 'openAt'),
            sortByStr: any(named: 'sortByStr'),
            term: any(named: 'term'),
            categories: any(named: 'categories'),
            radius: any(named: 'radius'),
            openNow: any(named: 'openNow'),
          ),
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
      'GPS 定位失敗時平滑回退至 location Taipei，不發出 Failure',
      setUp: () {
        addTearDown(_setMockGeolocator);
        const MethodChannel channel = MethodChannel(
          'flutter.baseflow.com/geolocator',
        );
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
              throw PlatformException(
                code: 'PERMISSION_DENIED',
                message: 'Location permissions are denied',
              );
            });
      },
      build: () {
        when(() => mockRepo.summaryInfoSet).thenReturn(<RestaurantEntity>{});
        when(
          () => mockRepo.fetchYelpSearchInfo(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            location: any(named: 'location'),
            price: any(named: 'price'),
            openAt: any(named: 'openAt'),
            sortByStr: any(named: 'sortByStr'),
            term: any(named: 'term'),
            categories: any(named: 'categories'),
            radius: any(named: 'radius'),
            openNow: any(named: 'openNow'),
          ),
        ).thenAnswer((_) async => _Data.nextPage);
        return MainBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const FetchSearchInfo()),
      expect: () => [isA<InProgress>(), isA<Success>()],
      verify: (_) {
        verify(
          () => mockRepo.fetchYelpSearchInfo(
            lat: null,
            lng: null,
            location: 'Taipei',
            price: null,
            openAt: null,
            sortByStr: null,
            term: null,
            categories: null,
            radius: null,
            openNow: null,
          ),
        ).called(1);
      },
    );

    blocTest<MainBloc, MainState>(
      '若 FetchSearchInfo 已指定 location 則優先採用且不查詢 GPS',
      build: () {
        when(() => mockRepo.summaryInfoSet).thenReturn(<RestaurantEntity>{});
        when(
          () => mockRepo.fetchYelpSearchInfo(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            location: any(named: 'location'),
            price: any(named: 'price'),
            openAt: any(named: 'openAt'),
            sortByStr: any(named: 'sortByStr'),
            term: any(named: 'term'),
            categories: any(named: 'categories'),
            radius: any(named: 'radius'),
            openNow: any(named: 'openNow'),
          ),
        ).thenAnswer((_) async => _Data.nextPage);
        return MainBloc(repository: mockRepo);
      },
      act: (bloc) =>
          bloc.add(const FetchSearchInfo(location: 'Tainan', price: '1,2')),
      expect: () => [isA<InProgress>(), isA<Success>()],
      verify: (_) {
        verify(
          () => mockRepo.fetchYelpSearchInfo(
            lat: null,
            lng: null,
            location: 'Tainan',
            price: '1,2',
            openAt: null,
            sortByStr: null,
            term: null,
            categories: null,
            radius: null,
            openNow: null,
          ),
        ).called(1);
      },
    );

    blocTest<MainBloc, MainState>(
      'FilterListByKeyword 直通遠端搜尋發出 InProgress → Success 並傳遞 term',
      build: () {
        when(
          () => mockRepo.fetchYelpSearchInfo(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            location: any(named: 'location'),
            price: any(named: 'price'),
            openAt: any(named: 'openAt'),
            sortByStr: any(named: 'sortByStr'),
            term: any(named: 'term'),
            categories: any(named: 'categories'),
            radius: any(named: 'radius'),
            openNow: any(named: 'openNow'),
          ),
        ).thenAnswer((_) async => _Data.nextPage);
        return MainBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(
        const FilterListByKeyword(keyword: 'Ramen', sortByStr: 'best_match'),
      ),
      expect: () => [isA<InProgress>(), isA<Success>()],
      verify: (_) {
        verify(
          () => mockRepo.fetchYelpSearchInfo(
            lat: 25.0,
            lng: 121.5,
            location: null,
            price: null,
            openAt: null,
            sortByStr: 'best_match',
            term: 'Ramen',
            categories: null,
            radius: null,
            openNow: null,
          ),
        ).called(1);
      },
    );

    blocTest<MainBloc, MainState>(
      'FilterListByKeyword 在 GPS 定位失敗時平滑回退至 location Taipei 並發送 term',
      setUp: () {
        addTearDown(_setMockGeolocator);
        const MethodChannel channel = MethodChannel(
          'flutter.baseflow.com/geolocator',
        );
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
              throw PlatformException(
                code: 'PERMISSION_DENIED',
                message: 'Location permissions are denied',
              );
            });
      },
      build: () {
        when(
          () => mockRepo.fetchYelpSearchInfo(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            location: any(named: 'location'),
            price: any(named: 'price'),
            openAt: any(named: 'openAt'),
            sortByStr: any(named: 'sortByStr'),
            term: any(named: 'term'),
            categories: any(named: 'categories'),
            radius: any(named: 'radius'),
            openNow: any(named: 'openNow'),
          ),
        ).thenAnswer((_) async => _Data.nextPage);
        return MainBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(
        const FilterListByKeyword(keyword: 'Ramen', sortByStr: 'best_match'),
      ),
      expect: () => [isA<InProgress>(), isA<Success>()],
      verify: (_) {
        verify(
          () => mockRepo.fetchYelpSearchInfo(
            lat: null,
            lng: null,
            location: 'Taipei',
            price: null,
            openAt: null,
            sortByStr: 'best_match',
            term: 'Ramen',
            categories: null,
            radius: null,
            openNow: null,
          ),
        ).called(1);
      },
    );

    blocTest<MainBloc, MainState>(
      'FilterListByKeyword 發生例外時發出 InProgress → Failure',
      build: () {
        when(
          () => mockRepo.fetchYelpSearchInfo(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            location: any(named: 'location'),
            price: any(named: 'price'),
            openAt: any(named: 'openAt'),
            sortByStr: any(named: 'sortByStr'),
            term: any(named: 'term'),
            categories: any(named: 'categories'),
            radius: any(named: 'radius'),
            openNow: any(named: 'openNow'),
          ),
        ).thenThrow(Exception('Network error'));
        return MainBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const FilterListByKeyword(keyword: 'Ramen')),
      expect: () => [isA<InProgress>(), isA<Failure>()],
    );
  });
}
