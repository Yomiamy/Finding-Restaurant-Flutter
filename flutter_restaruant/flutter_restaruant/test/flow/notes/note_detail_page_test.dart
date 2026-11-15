import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/flow/notes/notes_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class _MockRestaurantDetailRepository extends Mock
    implements RestaurantDetailRepository {}

class _Data {
  static const UgcNoteEntity multiImageNote = UgcNoteEntity(
    id: 'note_carousel',
    title: '台南深夜牛肉湯巡禮',
    content: '溫體牛涮三秒最鮮甜，湯頭清澈回甘。',
    authorName: 'Tainan Foodie',
    authorAvatarUrl: '',
    isVideo: false,
    coverUrl: '',
    coverAspectRatio: 1.0,
    imageUrls: ['', '', ''],
    videoUrl: '',
    videoDurationSec: 0,
    restaurantName: '阿財牛肉湯',
    createdAtMs: 1700000003000,
  );

  static const UgcNoteEntity linkedMultiImageNote = UgcNoteEntity(
    id: 'note_linked_carousel',
    title: '台北宵夜牛肉湯',
    content: '湯頭清甜順口。',
    authorName: 'Taipei Foodie',
    authorAvatarUrl: '',
    isVideo: false,
    coverUrl: '',
    coverAspectRatio: 1.0,
    imageUrls: [''],
    videoUrl: '',
    videoDurationSec: 0,
    restaurantName: '阿財牛肉湯',
    restaurantId: 'biz-beef-soup',
    createdAtMs: 1700000003500,
  );

  static const RestaurantDetailEntity beefSoupDetail = RestaurantDetailEntity(
    id: 'biz-beef-soup',
    name: '阿財牛肉湯 安平本店',
    rating: 4.6,
    reviewCount: 210,
    price: r'$',
    categories: [RestaurantCategoryEntity(alias: 'taiwanese', title: '台式小吃')],
  );

  static const UgcNoteEntity shortVideoNote = UgcNoteEntity(
    id: 'note_short_video',
    title: '12秒拉麵起鍋瞬間',
    content: '豚骨高湯濃郁掛麵！',
    authorName: 'Ramen Hunter',
    authorAvatarUrl: '',
    isVideo: true,
    coverUrl: '',
    coverAspectRatio: 0.75,
    imageUrls: [''],
    videoUrl: 'https://example.com/ramen.mp4',
    videoDurationSec: 12,
    restaurantName: '一蘭拉麵',
    createdAtMs: 1700000004000,
  );
}

void main() {
  late _MockRestaurantDetailRepository mockDetailRepository;

  setUp(() async {
    await GetIt.I.reset();
    mockDetailRepository = _MockRestaurantDetailRepository();
    GetIt.I.registerSingleton<RestaurantDetailRepository>(mockDetailRepository);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Widget buildDetailApp(UgcNoteEntity note) {
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
      home: NoteDetailPage(initialNote: note),
    );
  }

  group('NoteDetailPage Widget Tests', () {
    testWidgets(
      'renders NoteImageCarousel and updates page indicator on swipe',
      (tester) async {
        await tester.pumpWidget(buildDetailApp(_Data.multiImageNote));
        await tester.pumpAndSettle();

        expect(find.byType(NoteImageCarousel), findsOneWidget);
        expect(find.text('台南深夜牛肉湯巡禮'), findsOneWidget);
        expect(find.text('溫體牛涮三秒最鮮甜，湯頭清澈回甘。'), findsOneWidget);
        expect(find.text('Tainan Foodie'), findsOneWidget);
        expect(
          find.byKey(const Key('note_detail_restaurant_tag')),
          findsOneWidget,
        );
        expect(find.text('阿財牛肉湯'), findsOneWidget);
        expect(find.text('1 / 3'), findsOneWidget);

        await tester.fling(
          find.byKey(const Key('note_image_page_view')),
          const Offset(-500, 0),
          1000,
        );
        await tester.pumpAndSettle();

        expect(find.text('2 / 3'), findsOneWidget);
      },
    );

    testWidgets(
      'renders NoteVideoPlayer fallback panel gracefully when native video channel is absent',
      (tester) async {
        await tester.pumpWidget(buildDetailApp(_Data.shortVideoNote));
        await tester.pumpAndSettle();

        expect(find.byType(NoteVideoPlayer), findsOneWidget);
        expect(find.byKey(const Key('note_video_fallback')), findsOneWidget);
        expect(find.text('0:12'), findsOneWidget);
        expect(find.text(S.current.note_video_error), findsOneWidget);
        expect(find.text('12秒拉麵起鍋瞬間'), findsOneWidget);
        expect(find.text('一蘭拉麵'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping restaurant tag opens NoteRestaurantSummarySheet for linked note',
      (tester) async {
        when(
          () => mockDetailRepository.fetchYelpRestaurantDetailInfo(
            'biz-beef-soup',
          ),
        ).thenAnswer((_) async => _Data.beefSoupDetail);

        await tester.pumpWidget(buildDetailApp(_Data.linkedMultiImageNote));
        await tester.pumpAndSettle();

        final tagFinder = find.byKey(const Key('note_detail_restaurant_tag'));
        await tester.ensureVisible(tagFinder);
        await tester.pumpAndSettle();

        await tester.tap(tagFinder);
        await tester.pumpAndSettle();

        expect(find.byType(NoteRestaurantSummarySheet), findsOneWidget);
        expect(find.text('阿財牛肉湯 安平本店'), findsOneWidget);
        verify(
          () => mockDetailRepository.fetchYelpRestaurantDetailInfo(
            'biz-beef-soup',
          ),
        ).called(1);
      },
    );

    testWidgets(
      'tapping restaurant tag opens unlinked NoteRestaurantSummarySheet when restaurantId is empty',
      (tester) async {
        await tester.pumpWidget(buildDetailApp(_Data.multiImageNote));
        await tester.pumpAndSettle();

        final tagFinder = find.byKey(const Key('note_detail_restaurant_tag'));
        await tester.ensureVisible(tagFinder);
        await tester.pumpAndSettle();

        await tester.tap(tagFinder);
        await tester.pumpAndSettle();

        expect(find.byType(NoteRestaurantSummarySheet), findsOneWidget);
        expect(
          find.text(S.current.note_restaurant_sheet_unlinked_hint),
          findsOneWidget,
        );
        verifyNever(
          () => mockDetailRepository.fetchYelpRestaurantDetailInfo(any()),
        );
      },
    );
  });
}
