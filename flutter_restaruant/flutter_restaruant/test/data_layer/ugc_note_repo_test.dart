import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_restaruant/api/dto/dto_barrel.dart';
import 'package:flutter_restaruant/data_layer/datasources/datasources_barrel.dart';
import 'package:flutter_restaruant/data_layer/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

class _Data {
  static const UgcNoteDto fullVideoDto = UgcNoteDto(
    id: 'note-1',
    title: 'Best Tonkotsu Ramen',
    content: 'Rich broth and chewy noodles.',
    authorName: 'Alice',
    authorAvatarUrl: 'https://example.com/avatar.jpg',
    mediaType: 'video',
    coverUrl: 'https://example.com/cover.jpg',
    coverAspectRatio: 0.75,
    imageUrls: ['https://example.com/img1.jpg'],
    videoUrl: 'https://example.com/video.mp4',
    videoDurationSec: 12,
    restaurantName: 'Ichiran',
    createdAtMs: 1700000000000,
  );

  static const UgcNoteDto extremeVideoDto = UgcNoteDto(
    id: 'note-2',
    title: '  Ramen Vlog  ',
    mediaType: 'video',
    videoUrl: 'https://example.com/vlog.mp4',
    coverAspectRatio: 0.1, // below min 0.6
    videoDurationSec: 45, // above max 15
  );

  static const UgcNoteDto fallbackImageDto = UgcNoteDto(
    mediaType: 'image',
    coverAspectRatio: 2.5, // above max 1.5
    imageUrls: [
      'https://example.com/photo1.jpg',
      'https://example.com/photo2.jpg',
    ],
  );

  static const Map<String, dynamic> olderFirestoreDoc = {
    'title': 'Older Note',
    'media_type': 'image',
    'cover_url': 'https://example.com/old.jpg',
    'created_at_ms': 1000,
  };

  static Map<String, dynamic> newestFirestoreDoc() => {
    'title': 'Newest Video Note',
    'media_type': 'video',
    'cover_url': 'https://example.com/new.jpg',
    'video_url': 'https://example.com/new.mp4',
    'video_duration_sec': 15,
    'created_at_ms': Timestamp.fromMillisecondsSinceEpoch(5000),
  };

  static const Map<String, dynamic> missingTsFirestoreDoc = {
    'title': 'No Timestamp Note',
    'media_type': 'image',
  };

  static const Map<String, dynamic> malformedFirestoreDoc = {
    'title': 12345,
    'image_urls': 'not-a-list',
  };
}

void main() {
  group('UgcNoteDto & UgcNoteEntity Tests', () {
    test('UgcNoteDto serializes and deserializes correctly', () {
      final json = _Data.fullVideoDto.toJson();
      final fromJson = UgcNoteDto.fromJson(json);

      expect(fromJson, equals(_Data.fullVideoDto));
    });

    test(
      'UgcNoteEntity.fromDto clamps coverAspectRatio and videoDurationSec',
      () {
        final entity = UgcNoteEntity.fromDto(_Data.extremeVideoDto);
        expect(entity.title, 'Ramen Vlog');
        expect(entity.isVideo, isTrue);
        expect(entity.coverAspectRatio, UgcNoteEntity.minAspectRatio);
        expect(entity.videoDurationSec, UgcNoteEntity.maxVideoDurationSec);
        expect(entity.formattedVideoDuration, '0:15');
      },
    );

    test(
      'UgcNoteEntity.fromDto falls back to imageUrls.first when coverUrl is empty',
      () {
        final entity = UgcNoteEntity.fromDto(
          _Data.fallbackImageDto,
          docId: 'doc-fallback',
        );
        expect(entity.id, 'doc-fallback');
        expect(entity.isVideo, isFalse);
        expect(entity.coverUrl, 'https://example.com/photo1.jpg');
        expect(entity.coverAspectRatio, UgcNoteEntity.maxAspectRatio);
        expect(entity.imageUrls.length, 2);
      },
    );
  });

  group('UgcNoteDataSource & UgcNoteRepo Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late UgcNoteDataSource dataSource;
    late UgcNoteRepo repo;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      dataSource = UgcNoteDataSource(firestore: fakeFirestore);
      repo = UgcNoteRepo(dataSource: dataSource);
    });

    test('fetchNotes returns empty list when collection is empty', () async {
      final notes = await repo.fetchNotes();
      expect(notes, isEmpty);
    });

    test(
      'fetchNotes sorts by created_at_ms descending and handles Timestamp or missing timestamp',
      () async {
        final col = fakeFirestore.collection(UgcNoteDataSource.collectionName);

        await col.doc('older').set(_Data.olderFirestoreDoc);
        await col.doc('newest').set(_Data.newestFirestoreDoc());
        await col.doc('missing_ts').set(_Data.missingTsFirestoreDoc);

        final notes = await repo.fetchNotes();

        expect(notes.length, 3);
        expect(notes[0].id, 'newest');
        expect(notes[0].isVideo, isTrue);
        expect(notes[0].createdAtMs, 5000);
        expect(notes[1].id, 'older');
        expect(notes[1].createdAtMs, 1000);
        expect(notes[2].id, 'missing_ts');
        expect(notes[2].createdAtMs, 0);
      },
    );

    test(
      'fetchNotes skips malformed document and returns remaining valid notes',
      () async {
        final col = fakeFirestore.collection(UgcNoteDataSource.collectionName);

        await col.doc('valid').set(_Data.olderFirestoreDoc);
        await col.doc('malformed').set(_Data.malformedFirestoreDoc);

        final notes = await repo.fetchNotes();

        expect(notes.length, 1);
        expect(notes.first.id, 'valid');
      },
    );
  });
}
