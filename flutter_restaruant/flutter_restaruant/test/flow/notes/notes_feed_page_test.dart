import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/features/component/component_barrel.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/flow/notes/notes_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUgcNoteRepository extends Mock implements UgcNoteRepository {}

class _Data {
  static const UgcNoteEntity imageNote = UgcNoteEntity(
    id: 'note_img_1',
    title: '巷弄裡的手工義大利麵',
    content: '麵體彈牙，醬汁濃郁。',
    authorName: 'Chef Lin',
    authorAvatarUrl: '',
    isVideo: false,
    coverUrl: '',
    coverAspectRatio: 0.75,
    imageUrls: ['', ''],
    videoUrl: '',
    videoDurationSec: 0,
    restaurantName: 'Bella Pasta',
    createdAtMs: 1700000002000,
  );

  static const UgcNoteEntity videoNote = UgcNoteEntity(
    id: 'note_vid_1',
    title: '15秒直擊炙燒鮭魚握壽司',
    content: '油脂香氣撲鼻！',
    authorName: 'Sushi Lover',
    authorAvatarUrl: '',
    isVideo: true,
    coverUrl: '',
    coverAspectRatio: 1.0,
    imageUrls: [''],
    videoUrl: 'https://example.com/sushi.mp4',
    videoDurationSec: 15,
    restaurantName: '極上壽司',
    createdAtMs: 1700000001000,
  );
}

void main() {
  late _MockUgcNoteRepository mockRepository;

  setUp(() {
    mockRepository = _MockUgcNoteRepository();
  });

  Widget buildTestApp(NotesFeedBloc bloc) {
    return MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      theme: AppThemeData.materialLight,
      routes: {NoteDetailPage.routeName: (_) => const NoteDetailPage()},
      home: BlocProvider<NotesFeedBloc>.value(
        value: bloc,
        child: const NotesFeedPage(),
      ),
    );
  }

  group('NotesFeedPage Widget Tests', () {
    testWidgets('renders 2-column MasonryGridView with image and video cards', (
      tester,
    ) async {
      when(
        () => mockRepository.fetchNotes(),
      ).thenAnswer((_) async => const [_Data.imageNote, _Data.videoNote]);

      final bloc = NotesFeedBloc(repository: mockRepository);
      addTearDown(bloc.close);

      await tester.pumpWidget(buildTestApp(bloc));
      await tester.pumpAndSettle();

      expect(find.byType(MasonryGridView), findsOneWidget);
      expect(find.byType(NoteMasonryCard), findsNWidgets(2));
      expect(find.text('巷弄裡的手工義大利麵'), findsOneWidget);
      expect(find.text('Bella Pasta'), findsOneWidget);
      expect(find.text('Chef Lin'), findsOneWidget);
      expect(find.text('15秒直擊炙燒鮭魚握壽司'), findsOneWidget);
      expect(find.byKey(const Key('note_video_badge')), findsOneWidget);
      expect(find.text('0:15'), findsOneWidget);
    });

    testWidgets('renders EmptyDataWidget when notes list is empty', (
      tester,
    ) async {
      when(() => mockRepository.fetchNotes()).thenAnswer((_) async => const []);

      final bloc = NotesFeedBloc(repository: mockRepository);
      addTearDown(bloc.close);

      await tester.pumpWidget(buildTestApp(bloc));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyDataWidget), findsOneWidget);
      expect(find.text(S.current.notes_feed_empty), findsOneWidget);
    });

    testWidgets('renders retry button on failure and re-fetches when tapped', (
      tester,
    ) async {
      var callCount = 0;
      when(() => mockRepository.fetchNotes()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw Exception('Network error');
        }
        return const [_Data.imageNote];
      });

      final bloc = NotesFeedBloc(repository: mockRepository);
      addTearDown(bloc.close);

      await tester.pumpWidget(buildTestApp(bloc));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyDataWidget), findsOneWidget);
      final retryButton = find.byIcon(Icons.refresh);
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(callCount, 2);
      expect(find.byType(NoteMasonryCard), findsOneWidget);
    });

    testWidgets('tapping a card navigates to NoteDetailPage with note entity', (
      tester,
    ) async {
      when(
        () => mockRepository.fetchNotes(),
      ).thenAnswer((_) async => const [_Data.imageNote]);

      final bloc = NotesFeedBloc(repository: mockRepository);
      addTearDown(bloc.close);

      await tester.pumpWidget(buildTestApp(bloc));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('note_card_note_img_1')));
      await tester.pumpAndSettle();

      expect(find.byType(NoteDetailPage), findsOneWidget);
      expect(find.text('麵體彈牙，醬汁濃郁。'), findsOneWidget);
    });
  });
}
