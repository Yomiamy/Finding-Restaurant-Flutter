import 'package:flutter/material.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/flow/notes/notes_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

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
  Widget buildDetailApp(UgcNoteEntity note) {
    return MaterialApp(
      localizationsDelegates: const [S.delegate],
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
  });
}
