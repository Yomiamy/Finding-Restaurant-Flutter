import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_restaruant/domain/domain_barrel.dart';
import 'package:flutter_restaruant/flow/notes/bloc/notes_feed_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUgcNoteRepository extends Mock implements UgcNoteRepository {}

class _Data {
  static const sampleNotes = [
    UgcNoteEntity(
      id: 'note-1',
      title: 'Midnight Ramen in Zhongshan',
      content: 'Amazing pork bone soup!',
      authorName: 'Foodie Mia',
      authorAvatarUrl: '',
      isVideo: true,
      coverUrl: 'https://example.com/cover1.jpg',
      coverAspectRatio: 0.75,
      imageUrls: ['https://example.com/cover1.jpg'],
      videoUrl: 'https://example.com/vlog1.mp4',
      videoDurationSec: 15,
      restaurantName: 'Enishi Ramen',
      createdAtMs: 1700000000000,
    ),
  ];
}

void main() {
  group('NotesFeedBloc Tests', () {
    late _MockUgcNoteRepository mockRepo;

    setUp(() {
      mockRepo = _MockUgcNoteRepository();
    });

    test('initial state is NotesFeedInitial', () {
      final bloc = NotesFeedBloc(repository: mockRepo);
      expect(bloc.state, const NotesFeedInitial());
      bloc.close();
    });

    blocTest<NotesFeedBloc, NotesFeedState>(
      'emits [NotesFeedLoading, NotesFeedSuccess] when fetchNotes returns notes',
      build: () {
        when(
          () => mockRepo.fetchNotes(),
        ).thenAnswer((_) async => _Data.sampleNotes);
        return NotesFeedBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const FetchNotesFeed()),
      expect: () => const [
        NotesFeedLoading(),
        NotesFeedSuccess(notes: _Data.sampleNotes),
      ],
      verify: (_) {
        verify(() => mockRepo.fetchNotes()).called(1);
      },
    );

    blocTest<NotesFeedBloc, NotesFeedState>(
      'emits [NotesFeedLoading, NotesFeedEmpty] when fetchNotes returns empty list',
      build: () {
        when(() => mockRepo.fetchNotes()).thenAnswer((_) async => const []);
        return NotesFeedBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const FetchNotesFeed()),
      expect: () => const [NotesFeedLoading(), NotesFeedEmpty()],
    );

    blocTest<NotesFeedBloc, NotesFeedState>(
      'emits [NotesFeedLoading, NotesFeedFailure] when fetchNotes throws Exception',
      build: () {
        when(
          () => mockRepo.fetchNotes(),
        ).thenThrow(Exception('Firestore network error'));
        return NotesFeedBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const FetchNotesFeed()),
      expect: () => const [
        NotesFeedLoading(),
        NotesFeedFailure('Exception: Firestore network error'),
      ],
    );

    test(
      'ignores stale response when an earlier FetchNotesFeed finishes after a newer one',
      () async {
        final firstCompleter = Completer<List<UgcNoteEntity>>();
        final secondCompleter = Completer<List<UgcNoteEntity>>();
        var callCount = 0;

        when(() => mockRepo.fetchNotes()).thenAnswer((_) {
          callCount++;
          return callCount == 1
              ? firstCompleter.future
              : secondCompleter.future;
        });

        final bloc = NotesFeedBloc(repository: mockRepo);
        addTearDown(bloc.close);

        bloc
          ..add(const FetchNotesFeed())
          ..add(const FetchNotesFeed());

        await Future<void>.delayed(Duration.zero);

        secondCompleter.complete(_Data.sampleNotes);
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state, const NotesFeedSuccess(notes: _Data.sampleNotes));

        firstCompleter.complete(const []);
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state, const NotesFeedSuccess(notes: _Data.sampleNotes));
      },
    );
  });
}
