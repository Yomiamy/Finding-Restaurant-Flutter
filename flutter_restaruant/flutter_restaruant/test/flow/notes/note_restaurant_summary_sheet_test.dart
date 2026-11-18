import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/features/component/component_barrel.dart';
import 'package:flutter_restaruant/features/component/rating_stars.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/features/utils/utils_barrel.dart';
import 'package:flutter_restaruant/flow/notes/notes_barrel.dart';
import 'package:flutter_restaruant/flow/restaurant/view/restaurant_detail_page.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class _MockRestaurantDetailRepository extends Mock
    implements RestaurantDetailRepository {}

class _MockFavorRepository extends Mock implements FavorRepository {}

class _Data {
  static const UgcNoteEntity unlinkedNote = UgcNoteEntity(
    id: 'note_unlinked',
    title: '小籠包實測',
    content: '皮薄餡多，湯汁鮮甜。',
    authorName: 'Foodie Chen',
    authorAvatarUrl: '',
    isVideo: false,
    coverUrl: '',
    coverAspectRatio: 0.8,
    imageUrls: [''],
    videoUrl: '',
    videoDurationSec: 0,
    restaurantName: '  鼎泰豐 信義店  ',
    restaurantId: '',
    createdAtMs: 1700000001000,
  );

  static const UgcNoteEntity linkedNote = UgcNoteEntity(
    id: 'note_linked',
    title: '一蘭豚骨拉麵初體驗',
    content: '半熟蛋與秘製辣醬必加！',
    authorName: 'Ramen Fan',
    authorAvatarUrl: '',
    isVideo: false,
    coverUrl: '',
    coverAspectRatio: 0.8,
    imageUrls: [''],
    videoUrl: '',
    videoDurationSec: 0,
    restaurantName: '一蘭拉麵',
    restaurantId: 'biz-ichiran',
    createdAtMs: 1700000002000,
  );

  static const RestaurantDetailEntity fullDetailOpen = RestaurantDetailEntity(
    id: 'biz-ichiran',
    name: '一蘭拉麵 台北本店',
    imageUrl: '',
    isClosed: false,
    reviewCount: 328,
    rating: 4.5,
    phone: '+886227583868',
    price: r'$$',
    categories: [RestaurantCategoryEntity(alias: 'ramen', title: '日式拉麵')],
    location: RestaurantLocationEntity(displayAddress: ['台北市信義區松仁路97號', '1樓']),
    coordinates: RestaurantCoordinatesEntity(
      latitude: 25.033964,
      longitude: 121.564468,
    ),
    hours: [RestaurantHoursEntity(isOpenNow: true)],
  );

  static const RestaurantDetailEntity detailClosed = RestaurantDetailEntity(
    id: 'biz-ichiran',
    name: '一蘭拉麵 台北本店',
    rating: 4.0,
    reviewCount: 100,
    hours: [RestaurantHoursEntity(isOpenNow: false)],
  );

  static const RestaurantDetailEntity detailEmptyHours = RestaurantDetailEntity(
    id: 'biz-ichiran',
    name: '一蘭拉麵 台北本店',
    rating: 4.0,
    reviewCount: 100,
    hours: [],
  );

  static const RestaurantDetailEntity detailNullOpenStatus =
      RestaurantDetailEntity(
        id: 'biz-ichiran',
        name: '一蘭拉麵 台北本店',
        rating: 4.0,
        reviewCount: 100,
        hours: [RestaurantHoursEntity(isOpenNow: null)],
      );

  static const RestaurantDetailEntity detailMissingId = RestaurantDetailEntity(
    id: null,
    name: '一蘭拉麵 台北本店',
    imageUrl: '',
    rating: 4.8,
    reviewCount: 512,
    price: r'$$$',
    phone: '+886227583868',
    categories: [
      RestaurantCategoryEntity(alias: 'ramen', title: '日式拉麵'),
      RestaurantCategoryEntity(alias: 'japanese', title: '日本料理'),
    ],
    location: RestaurantLocationEntity(displayAddress: ['台北市信義區松仁路97號']),
    coordinates: RestaurantCoordinatesEntity(
      latitude: 25.033964,
      longitude: 121.564468,
    ),
    hours: [RestaurantHoursEntity(isOpenNow: true)],
  );

  static const RestaurantDetailEntity longTextDetail = RestaurantDetailEntity(
    id: 'biz-long',
    name: '超級無敵霹靂長名稱居酒屋兼手工炭火燒肉串燒專門店信義區松壽路旗艦總店',
    rating: 4.9,
    reviewCount: 99999,
    price: r'$$$$',
    categories: [
      RestaurantCategoryEntity(alias: 'izakaya', title: '日式居酒屋料理'),
      RestaurantCategoryEntity(alias: 'yakitori', title: '炭火串燒專門'),
      RestaurantCategoryEntity(alias: 'sake', title: '清酒專賣'),
    ],
    location: RestaurantLocationEntity(
      displayAddress: ['台北市信義區松壽路一段123號地下一樓B1美食廣場東側轉角處'],
    ),
    hours: [RestaurantHoursEntity(isOpenNow: true)],
  );

  static const UgcNoteEntity invalidIdNote = UgcNoteEntity(
    id: 'note_invalid_id',
    title: '異常 ID 筆記',
    content: '測試路徑跳脫防護。',
    authorName: 'Tester',
    authorAvatarUrl: '',
    isVideo: false,
    coverUrl: '',
    coverAspectRatio: 0.8,
    imageUrls: [''],
    videoUrl: '',
    videoDurationSec: 0,
    restaurantName: '測試餐廳',
    restaurantId: '../search',
    createdAtMs: 1700000003000,
  );
}

void main() {
  late _MockRestaurantDetailRepository mockRepository;
  late _MockFavorRepository mockFavorRepository;
  late List<NoteRestaurantSheetBloc> createdBlocs;

  setUp(() async {
    await GetIt.I.reset();
    mockRepository = _MockRestaurantDetailRepository();
    mockFavorRepository = _MockFavorRepository();
    createdBlocs = <NoteRestaurantSheetBloc>[];
  });

  tearDown(() async {
    for (final bloc in createdBlocs) {
      await bloc.close();
    }
    await GetIt.I.reset();
  });

  Widget buildHostApp({
    required UgcNoteEntity note,
    NoteRestaurantSheetBloc? bloc,
    RestaurantDetailRepository? repository,
    FavorRepository? favorRepository,
    bool useGetIt = false,
    void Function(String query)? onOpenMaps,
    Map<String, WidgetBuilder> routes = const {},
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
      routes: routes,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('open_sheet_btn'),
              onPressed: () {
                final resolvedBloc = useGetIt
                    ? null
                    : (bloc ??
                          NoteRestaurantSheetBloc(
                            repository: repository,
                            favorRepository: favorRepository,
                            logger: Logger(level: Level.off),
                          ));
                if (!useGetIt && bloc == null && resolvedBloc != null) {
                  createdBlocs.add(resolvedBloc);
                }
                NoteRestaurantSummarySheet.show(
                  context,
                  note: note,
                  bloc: resolvedBloc,
                  onOpenMaps: onOpenMaps,
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );
  }

  group('NoteRestaurantSummarySheet Widget Tests', () {
    testWidgets(
      'renders unlinked mode when restaurantId is empty without calling repository',
      (tester) async {
        String? openedQuery;

        await tester.pumpWidget(
          buildHostApp(
            note: _Data.unlinkedNote,
            repository: mockRepository,
            onOpenMaps: (query) => openedQuery = query,
          ),
        );

        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pumpAndSettle();

        verifyNever(() => mockRepository.fetchYelpRestaurantDetailInfo(any()));
        expect(find.textContaining('鼎泰豐 信義店'), findsOneWidget);
        expect(
          find.text(S.current.note_restaurant_sheet_unlinked_hint),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('note_restaurant_sheet_detail_btn')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('note_restaurant_sheet_maps_btn')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('note_restaurant_sheet_maps_btn')),
        );
        await tester.pump();

        expect(openedQuery, '鼎泰豐 信義店');
      },
    );

    testWidgets(
      'shows LoadingWidget while fetching and renders full detail with coordinates on success',
      (tester) async {
        final completer = Completer<RestaurantDetailEntity>();
        String? openedQuery;

        when(
          () => mockRepository.fetchYelpRestaurantDetailInfo('biz-ichiran'),
        ).thenAnswer((_) => completer.future);

        await tester.pumpWidget(
          buildHostApp(
            note: _Data.linkedNote,
            repository: mockRepository,
            onOpenMaps: (query) => openedQuery = query,
          ),
        );

        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pump();
        await tester.pump();

        expect(find.byType(LoadingWidget), findsOneWidget);
        expect(find.text('一蘭拉麵'), findsOneWidget);

        completer.complete(_Data.fullDetailOpen);
        await tester.pumpAndSettle();

        expect(find.byType(LoadingWidget), findsNothing);
        expect(find.text('一蘭拉麵 台北本店'), findsOneWidget);
        expect(find.byType(RatingStars), findsOneWidget);
        expect(find.text('4.5'), findsOneWidget);
        expect(
          find.text('328${S.current.review_count_suffix}'),
          findsOneWidget,
        );
        expect(find.text(r'$$ · 日式拉麵'), findsOneWidget);
        expect(find.text('台北市信義區松仁路97號, 1樓'), findsOneWidget);

        final openBadgeFinder = find.text(S.current.business_status_open);
        expect(openBadgeFinder, findsOneWidget);
        final openBadgeBox = tester.widget<DecoratedBox>(
          find
              .ancestor(
                of: openBadgeFinder,
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final openDecoration = openBadgeBox.decoration as BoxDecoration;
        expect(openDecoration.color, const Color(0xFF2E7D32));

        expect(
          find.byKey(const Key('note_restaurant_sheet_detail_btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('note_restaurant_sheet_maps_btn')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('note_restaurant_sheet_maps_btn')),
        );
        await tester.pump();

        expect(openedQuery, '25.033964,121.564468');
      },
    );

    testWidgets(
      'renders closed badge with grey background and omits badge when hours are empty or isOpenNow is null',
      (tester) async {
        when(
          () => mockRepository.fetchYelpRestaurantDetailInfo('biz-ichiran'),
        ).thenAnswer((_) async => _Data.detailClosed);

        await tester.pumpWidget(
          buildHostApp(note: _Data.linkedNote, repository: mockRepository),
        );
        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pumpAndSettle();

        final closedBadgeFinder = find.text(S.current.business_status_closed);
        expect(closedBadgeFinder, findsOneWidget);
        expect(find.text(S.current.business_status_open), findsNothing);
        final closedBadgeBox = tester.widget<DecoratedBox>(
          find
              .ancestor(
                of: closedBadgeFinder,
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final closedDecoration = closedBadgeBox.decoration as BoxDecoration;
        expect(
          closedDecoration.color,
          AppThemeData.materialLight.colorScheme.outline,
        );

        // Close sheet and verify empty hours list omits status badge
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        when(
          () => mockRepository.fetchYelpRestaurantDetailInfo('biz-ichiran'),
        ).thenAnswer((_) async => _Data.detailEmptyHours);
        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pumpAndSettle();

        expect(find.text(S.current.business_status_open), findsNothing);
        expect(find.text(S.current.business_status_closed), findsNothing);

        // Close sheet and verify isOpenNow == null omits status badge
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        when(
          () => mockRepository.fetchYelpRestaurantDetailInfo('biz-ichiran'),
        ).thenAnswer((_) async => _Data.detailNullOpenStatus);
        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pumpAndSettle();

        expect(find.text(S.current.business_status_open), findsNothing);
        expect(find.text(S.current.business_status_closed), findsNothing);
      },
    );

    testWidgets(
      'tapping view detail pops sheet, pushes RestaurantDetailPage with mapped RestaurantEntity and fallback id',
      (tester) async {
        Tuple2<RestaurantEntity, dynamic>? pushedArgs;

        when(
          () => mockRepository.fetchYelpRestaurantDetailInfo('biz-ichiran'),
        ).thenAnswer((_) async => _Data.detailMissingId);

        await tester.pumpWidget(
          buildHostApp(
            note: _Data.linkedNote,
            repository: mockRepository,
            routes: {
              RestaurantDetailPage.routeName: (context) {
                pushedArgs =
                    ModalRoute.of(context)?.settings.arguments
                        as Tuple2<RestaurantEntity, dynamic>?;
                return const Scaffold(body: Text('Restaurant Detail Stub'));
              },
            },
          ),
        );

        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('note_restaurant_sheet_detail_btn')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(NoteRestaurantSummarySheet), findsNothing);
        expect(find.text('Restaurant Detail Stub'), findsOneWidget);
        expect(pushedArgs, isNotNull);
        expect(pushedArgs?.item2, isNull);

        final entity = pushedArgs!.item1;
        expect(entity.id, 'biz-ichiran');
        expect(entity.name, '一蘭拉麵 台北本店');
        expect(entity.rating, 4.8);
        expect(entity.reviewCount, 512);
        expect(entity.price, r'$$$');
        expect(entity.phone, '+886227583868');
        expect(entity.categories?.length, 2);
        expect(entity.location?.displayAddress, ['台北市信義區松仁路97號']);
        expect(entity.coordinates?.latitude, 25.033964);
        expect(entity.coordinates?.longitude, 121.564468);
      },
    );

    testWidgets(
      'shows failure state with retry and fallback maps on Exception, then recovers on retry',
      (tester) async {
        var callCount = 0;
        String? openedQuery;

        when(
          () => mockRepository.fetchYelpRestaurantDetailInfo('biz-ichiran'),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            throw Exception('Network timeout');
          }
          return _Data.fullDetailOpen;
        });

        await tester.pumpWidget(
          buildHostApp(
            note: _Data.linkedNote,
            repository: mockRepository,
            onOpenMaps: (query) => openedQuery = query,
          ),
        );

        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pumpAndSettle();

        expect(
          find.text(S.current.note_restaurant_sheet_error),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('note_restaurant_sheet_retry_btn')),
          findsOneWidget,
        );
        expect(find.text(S.current.empty_data_retry), findsOneWidget);
        expect(
          find.byKey(const Key('note_restaurant_sheet_maps_btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('note_restaurant_sheet_detail_btn')),
          findsNothing,
        );

        await tester.tap(
          find.byKey(const Key('note_restaurant_sheet_maps_btn')),
        );
        await tester.pump();
        expect(openedQuery, '一蘭拉麵');

        await tester.tap(
          find.byKey(const Key('note_restaurant_sheet_retry_btn')),
        );
        await tester.pumpAndSettle();

        expect(callCount, 2);
        expect(find.text(S.current.note_restaurant_sheet_error), findsNothing);
        expect(
          find.byKey(const Key('note_restaurant_sheet_detail_btn')),
          findsOneWidget,
        );
        expect(find.text('一蘭拉麵 台北本店'), findsOneWidget);
      },
    );

    testWidgets(
      'shows failure state when repository returns empty RestaurantDetailEntity',
      (tester) async {
        when(
          () => mockRepository.fetchYelpRestaurantDetailInfo('biz-ichiran'),
        ).thenAnswer((_) async => const RestaurantDetailEntity());

        await tester.pumpWidget(
          buildHostApp(note: _Data.linkedNote, repository: mockRepository),
        );

        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pumpAndSettle();

        expect(
          find.text(S.current.note_restaurant_sheet_error),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('note_restaurant_sheet_retry_btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('note_restaurant_sheet_maps_btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('note_restaurant_sheet_detail_btn')),
          findsNothing,
        );
      },
    );

    testWidgets('renders without overflow on 320px narrow screen', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;

      when(
        () => mockRepository.fetchYelpRestaurantDetailInfo('biz-ichiran'),
      ).thenAnswer((_) async => _Data.longTextDetail);

      await tester.pumpWidget(
        buildHostApp(note: _Data.linkedNote, repository: mockRepository),
      );

      await tester.tap(find.byKey(const Key('open_sheet_btn')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('note_restaurant_sheet_detail_btn')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('note_restaurant_sheet_maps_btn')),
        findsOneWidget,
      );
    });

    testWidgets(
      'rejects invalid restaurantId with path or query characters without calling repository',
      (tester) async {
        await tester.pumpWidget(
          buildHostApp(note: _Data.invalidIdNote, repository: mockRepository),
        );

        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pumpAndSettle();

        verifyNever(() => mockRepository.fetchYelpRestaurantDetailInfo(any()));
        expect(
          find.text(S.current.note_restaurant_sheet_error),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('note_restaurant_sheet_retry_btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('note_restaurant_sheet_detail_btn')),
          findsNothing,
        );

        await tester.tap(
          find.byKey(const Key('note_restaurant_sheet_retry_btn')),
        );
        await tester.pump();
        verifyNever(() => mockRepository.fetchYelpRestaurantDetailInfo(any()));
      },
    );

    testWidgets(
      'resolves favorited status via FavorRepository and forwards favor: true to RestaurantDetailPage',
      (tester) async {
        Tuple2<RestaurantEntity, dynamic>? pushedArgs;

        when(
          () => mockRepository.fetchYelpRestaurantDetailInfo('biz-ichiran'),
        ).thenAnswer((_) async => _Data.fullDetailOpen);
        when(
          () => mockFavorRepository.isFavor('biz-ichiran'),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(
          buildHostApp(
            note: _Data.linkedNote,
            repository: mockRepository,
            favorRepository: mockFavorRepository,
            routes: {
              RestaurantDetailPage.routeName: (context) {
                pushedArgs =
                    ModalRoute.of(context)?.settings.arguments
                        as Tuple2<RestaurantEntity, dynamic>?;
                return const Scaffold(body: Text('Restaurant Detail Stub'));
              },
            },
          ),
        );

        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('note_restaurant_sheet_detail_btn')),
        );
        await tester.pumpAndSettle();

        expect(pushedArgs, isNotNull);
        expect(pushedArgs!.item1.id, 'biz-ichiran');
        expect(pushedArgs!.item1.favor, isTrue);
        verify(() => mockFavorRepository.isFavor('biz-ichiran')).called(1);
      },
    );

    testWidgets(
      'falls back to favor: false when FavorRepository throws Exception',
      (tester) async {
        Tuple2<RestaurantEntity, dynamic>? pushedArgs;

        when(
          () => mockRepository.fetchYelpRestaurantDetailInfo('biz-ichiran'),
        ).thenAnswer((_) async => _Data.fullDetailOpen);
        when(
          () => mockFavorRepository.isFavor('biz-ichiran'),
        ).thenAnswer((_) async => throw Exception('Firestore unavailable'));

        await tester.pumpWidget(
          buildHostApp(
            note: _Data.linkedNote,
            repository: mockRepository,
            favorRepository: mockFavorRepository,
            routes: {
              RestaurantDetailPage.routeName: (context) {
                pushedArgs =
                    ModalRoute.of(context)?.settings.arguments
                        as Tuple2<RestaurantEntity, dynamic>?;
                return const Scaffold(body: Text('Restaurant Detail Stub'));
              },
            },
          ),
        );

        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('note_restaurant_sheet_detail_btn')),
        );
        await tester.pumpAndSettle();

        expect(pushedArgs, isNotNull);
        expect(pushedArgs!.item1.favor, isFalse);
      },
    );

    testWidgets(
      'falls back to favor: false when favorite lookup hangs past timeout',
      (tester) async {
        final favorCompleter = Completer<bool>();
        Tuple2<RestaurantEntity, dynamic>? pushedArgs;
        String? openedQuery;

        when(
          () => mockRepository.fetchYelpRestaurantDetailInfo('biz-ichiran'),
        ).thenAnswer((_) async => _Data.fullDetailOpen);
        when(
          () => mockFavorRepository.isFavor('biz-ichiran'),
        ).thenAnswer((_) => favorCompleter.future);

        await tester.pumpWidget(
          buildHostApp(
            note: _Data.linkedNote,
            repository: mockRepository,
            favorRepository: mockFavorRepository,
            onOpenMaps: (query) => openedQuery = query,
            routes: {
              RestaurantDetailPage.routeName: (context) {
                pushedArgs =
                    ModalRoute.of(context)?.settings.arguments
                        as Tuple2<RestaurantEntity, dynamic>?;
                return const Scaffold(body: Text('Restaurant Detail Stub'));
              },
            },
          ),
        );

        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pump();
        await tester.pump();

        expect(find.byType(LoadingWidget), findsOneWidget);

        await tester.pump(NoteRestaurantSheetBloc.defaultFavorLookupTimeout);
        await tester.pumpAndSettle();

        expect(find.byType(LoadingWidget), findsNothing);
        expect(find.text('一蘭拉麵 台北本店'), findsOneWidget);
        expect(
          find.byKey(const Key('note_restaurant_sheet_maps_btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('note_restaurant_sheet_detail_btn')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('note_restaurant_sheet_maps_btn')),
        );
        await tester.pump();
        expect(openedQuery, '25.033964,121.564468');

        await tester.tap(
          find.byKey(const Key('note_restaurant_sheet_detail_btn')),
        );
        await tester.pumpAndSettle();

        expect(pushedArgs, isNotNull);
        expect(pushedArgs!.item1.id, 'biz-ichiran');
        expect(pushedArgs!.item1.favor, isFalse);
      },
    );

    testWidgets(
      'protects bottom action button from nonzero bottom system view padding',
      (tester) async {
        const bottomInset = 34.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        tester.view.padding = FakeViewPadding(
          bottom: bottomInset * tester.view.devicePixelRatio,
        );
        tester.view.viewPadding = FakeViewPadding(
          bottom: bottomInset * tester.view.devicePixelRatio,
        );

        when(
          () => mockRepository.fetchYelpRestaurantDetailInfo('biz-ichiran'),
        ).thenAnswer((_) async => _Data.fullDetailOpen);

        await tester.pumpWidget(
          buildHostApp(note: _Data.linkedNote, repository: mockRepository),
        );

        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pumpAndSettle();

        final mapsBtnBottom = tester
            .getBottomLeft(
              find.byKey(const Key('note_restaurant_sheet_maps_btn')),
            )
            .dy;
        expect(
          mapsBtnBottom,
          lessThanOrEqualTo(800.0 - bottomInset - ThemeSize.space16),
        );
      },
    );

    testWidgets(
      'close button provides localized close tooltip and dismisses the sheet',
      (tester) async {
        await tester.pumpWidget(
          buildHostApp(note: _Data.unlinkedNote, repository: mockRepository),
        );

        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pumpAndSettle();

        final closeTooltip = MaterialLocalizations.of(
          tester.element(find.byType(NoteRestaurantSummarySheet)),
        ).closeButtonTooltip;
        expect(find.byTooltip(closeTooltip), findsOneWidget);

        await tester.tap(find.byTooltip(closeTooltip));
        await tester.pumpAndSettle();

        expect(find.byType(NoteRestaurantSummarySheet), findsNothing);
      },
    );

    test(
      'buildGoogleMapsQuery prefers coordinates, then detail name, then trimmed note name',
      () {
        expect(
          NoteRestaurantSummarySheet.buildGoogleMapsQuery(
            _Data.linkedNote,
            _Data.fullDetailOpen,
          ),
          '25.033964,121.564468',
        );
        expect(
          NoteRestaurantSummarySheet.buildGoogleMapsQuery(
            _Data.linkedNote,
            _Data.detailClosed,
          ),
          '一蘭拉麵 台北本店',
        );
        expect(
          NoteRestaurantSummarySheet.buildGoogleMapsQuery(
            _Data.unlinkedNote,
            null,
          ),
          '鼎泰豐 信義店',
        );
      },
    );

    testWidgets(
      'uses GetIt dependencies when bloc is omitted and preserves injected bloc after sheet dismissal',
      (tester) async {
        GetIt.I.registerSingleton<RestaurantDetailRepository>(mockRepository);
        GetIt.I.registerSingleton<FavorRepository>(mockFavorRepository);
        when(
          () => mockRepository.fetchYelpRestaurantDetailInfo('biz-ichiran'),
        ).thenAnswer((_) async => _Data.fullDetailOpen);
        when(
          () => mockFavorRepository.isFavor('biz-ichiran'),
        ).thenAnswer((_) async => false);

        await tester.pumpWidget(
          buildHostApp(note: _Data.linkedNote, useGetIt: true),
        );
        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pumpAndSettle();

        expect(find.text('一蘭拉麵 台北本店'), findsOneWidget);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.byType(NoteRestaurantSummarySheet), findsNothing);

        final externalBloc = NoteRestaurantSheetBloc(
          repository: mockRepository,
          favorRepository: mockFavorRepository,
          logger: Logger(level: Level.off),
        );
        addTearDown(externalBloc.close);

        await tester.pumpWidget(
          buildHostApp(note: _Data.linkedNote, bloc: externalBloc),
        );
        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pumpAndSettle();
        expect(find.text('一蘭拉麵 台北本店'), findsOneWidget);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(externalBloc.isClosed, isFalse);
      },
    );
  });
}
