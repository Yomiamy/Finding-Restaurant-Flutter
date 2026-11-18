import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/features/component/component_barrel.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/features/utils/utils_barrel.dart';
import 'package:flutter_restaruant/flow/restaurant/bloc/bloc_barrel.dart';
import 'package:flutter_restaruant/flow/restaurant/view/view_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class _MockRestaurantDetailRepository extends Mock
    implements RestaurantDetailRepository {}

class _MockReviewSummaryRepository extends Mock
    implements ReviewSummaryRepository {}

class _Data {
  static const RestaurantEntity summaryNotFavor = RestaurantEntity(
    id: 'biz-empty-hours',
    name: '無營業時間餐廳',
    favor: false,
  );

  static const RestaurantEntity summaryFavor = RestaurantEntity(
    id: 'biz-empty-hours',
    name: '無營業時間餐廳',
    favor: true,
  );

  static const RestaurantDetailEntity detailEmptyHours = RestaurantDetailEntity(
    id: 'biz-empty-hours',
    name: '無營業時間餐廳',
    imageUrl: 'https://example.com/rest.jpg',
    rating: 4.2,
    reviewCount: 15,
    hours: <RestaurantHoursEntity>[],
  );

  static const RestaurantDetailEntity detailNullOpen = RestaurantDetailEntity(
    id: 'biz-empty-hours',
    name: '無營業時間餐廳',
    imageUrl: 'https://example.com/rest.jpg',
    rating: 4.2,
    reviewCount: 15,
    hours: <RestaurantHoursEntity>[
      RestaurantHoursEntity(isOpenNow: false, open: null),
    ],
  );

  static const ReviewEntity emptyReviews = ReviewEntity(
    total: 0,
    reviews: <ReviewDetailEntity>[],
  );
}

void main() {
  late _MockRestaurantDetailRepository mockDetailRepository;
  late _MockReviewSummaryRepository mockReviewSummaryRepository;

  setUp(() async {
    await GetIt.I.reset();
    mockDetailRepository = _MockRestaurantDetailRepository();
    mockReviewSummaryRepository = _MockReviewSummaryRepository();
    GetIt.I.registerSingleton<ReviewSummaryRepository>(
      mockReviewSummaryRepository,
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Widget buildHostApp({
    required RestaurantDetailBloc bloc,
    required RestaurantEntity summaryInfo,
  }) {
    return MaterialApp(
      locale: const Locale('zh', 'TW'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      theme: AppThemeData.materialLight,
      routes: {
        RestaurantDetailPage.routeName: (_) =>
            BlocProvider<RestaurantDetailBloc>.value(
              value: bloc,
              child: const RestaurantDetailPage(),
            ),
      },
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('open_detail_btn'),
              onPressed: () {
                Navigator.of(context).pushNamed(
                  RestaurantDetailPage.routeName,
                  arguments: Tuple2<RestaurantEntity, dynamic>(
                    summaryInfo,
                    null,
                  ),
                );
              },
              child: const Text('Open Detail'),
            ),
          ),
        ),
      ),
    );
  }

  group('RestaurantDetailPage Widget Tests', () {
    testWidgets(
      'renders without RangeError when detail.hours is an empty list',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          when(
            () => mockDetailRepository.fetchYelpRestaurantDetailInfo(
              'biz-empty-hours',
            ),
          ).thenAnswer((_) async => _Data.detailEmptyHours);
          when(
            () => mockDetailRepository.fetchYelpRestaurantReviewInfo(
              'biz-empty-hours',
            ),
          ).thenAnswer((_) async => _Data.emptyReviews);

          final bloc = RestaurantDetailBloc(repository: mockDetailRepository);
          addTearDown(bloc.close);

          await tester.pumpWidget(
            buildHostApp(bloc: bloc, summaryInfo: _Data.summaryNotFavor),
          );

          await tester.tap(find.byKey(const Key('open_detail_btn')));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(RestaurantDetailPage), findsOneWidget);
          expect(find.text('無營業時間餐廳'), findsOneWidget);
          expect(find.byType(RestaurantBusinessHourCell), findsOneWidget);
          expect(find.text(S.current.business_hour), findsNothing);
          expect(find.byIcon(Icons.favorite_border), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'renders without error when detail.hours.first.open is null and shows favorite icon when favor is true',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          when(
            () => mockDetailRepository.fetchYelpRestaurantDetailInfo(
              'biz-empty-hours',
            ),
          ).thenAnswer((_) async => _Data.detailNullOpen);
          when(
            () => mockDetailRepository.fetchYelpRestaurantReviewInfo(
              'biz-empty-hours',
            ),
          ).thenAnswer((_) async => _Data.emptyReviews);

          final bloc = RestaurantDetailBloc(repository: mockDetailRepository);
          addTearDown(bloc.close);

          await tester.pumpWidget(
            buildHostApp(bloc: bloc, summaryInfo: _Data.summaryFavor),
          );

          await tester.tap(find.byKey(const Key('open_detail_btn')));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(RestaurantBusinessHourCell), findsOneWidget);
          expect(find.text(S.current.business_hour), findsNothing);
          expect(find.byIcon(Icons.favorite), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });
}
