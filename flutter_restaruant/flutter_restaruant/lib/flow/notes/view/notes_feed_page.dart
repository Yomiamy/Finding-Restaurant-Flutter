import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../features/component/component_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../gen/assets.gen.dart';
import '../../../generated/l10n.dart';
import '../bloc/notes_feed_barrel.dart';
import 'note_detail_page.dart';

/// 雙排瀑布流探店食記與短影片列表頁。
class NotesFeedPage extends StatefulWidget {
  static const routeName = '/NotesFeedPage';

  const NotesFeedPage({super.key});

  @override
  State<NotesFeedPage> createState() => _NotesFeedPageState();
}

class _NotesFeedPageState extends State<NotesFeedPage> {
  late NotesFeedBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<NotesFeedBloc>();
    if (_bloc.state is NotesFeedInitial) {
      _bloc.add(const FetchNotesFeed());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: ThemeColor.colorffffff),
        ),
        title: Text(
          S.current.notes_feed_title,
          style: const TextStyle(
            color: ThemeColor.colorffffff,
            fontSize: ThemeFontSize.fontSize22,
          ),
        ),
        backgroundColor: ThemeColor.colord84a20,
      ),
      body: BlocBuilder<NotesFeedBloc, NotesFeedState>(
        bloc: _bloc,
        builder: (context, state) {
          return switch (state) {
            NotesFeedInitial() ||
            NotesFeedLoading() => const Center(child: LoadingWidget()),
            NotesFeedEmpty() => EmptyDataWidget(
              title: S.current.notes_feed_empty,
              icon: Icons.explore_outlined,
              onRetry: () => _bloc.add(const FetchNotesFeed()),
            ),
            NotesFeedFailure() => EmptyDataWidget.withDefaults(
              onRetry: () => _bloc.add(const FetchNotesFeed()),
            ),
            NotesFeedSuccess(:final notes) => RefreshIndicator(
              onRefresh: () async {
                final done = _bloc.stream.firstWhere(
                  (s) => s is! NotesFeedLoading,
                );
                _bloc.add(const FetchNotesFeed());
                await done;
              },
              child: MasonryGridView.count(
                key: const Key('notes_masonry_grid'),
                physics: const AlwaysScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: ThemeSize.space10,
                crossAxisSpacing: ThemeSize.space10,
                padding: const EdgeInsets.all(ThemeSize.space10),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  return NoteMasonryCard(note: notes[index]);
                },
              ),
            ),
          };
        },
      ),
    );
  }
}

/// 瀑布流中的單張食記／短影片卡片。
class NoteMasonryCard extends StatelessWidget {
  final UgcNoteEntity note;

  const NoteMasonryCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final restaurantName = note.restaurantName;

    return Card(
      key: Key('note_card_${note.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeSize.radius12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).pushNamed(NoteDetailPage.routeName, arguments: note);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: note.coverAspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NoteCoverImage(imageUrl: note.coverUrl),
                  if (note.isVideo)
                    Positioned(
                      top: ThemeSize.space8,
                      right: ThemeSize.space8,
                      child: NoteVideoBadge(
                        durationText: note.formattedVideoDuration,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ThemeSize.space10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (restaurantName.isNotEmpty) ...[
                    const SizedBox(height: ThemeSize.space4),
                    Row(
                      children: [
                        const Icon(
                          Icons.place,
                          size: ThemeSize.size14,
                          color: ThemeColor.colord84a20,
                        ),
                        const SizedBox(width: ThemeSize.space3),
                        Expanded(
                          child: Text(
                            restaurantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: ThemeSize.space8),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: ThemeSize.size14,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(width: ThemeSize.space4),
                      Expanded(
                        child: Text(
                          note.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 瀑布流卡片與詳情頁共用的網路圖片與預設佔位圖元件。
class NoteCoverImage extends StatelessWidget {
  final String imageUrl;

  const NoteCoverImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Assets.images.empty.image(fit: BoxFit.cover);
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          Assets.images.empty.image(fit: BoxFit.cover),
    );
  }
}

/// 短影片卡片右上角的播放角標與秒數提示。
class NoteVideoBadge extends StatelessWidget {
  final String durationText;

  const NoteVideoBadge({super.key, required this.durationText});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const Key('note_video_badge'),
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeSize.space8,
        vertical: ThemeSize.space3,
      ),
      decoration: BoxDecoration(
        color: ThemeColor.color8a000000,
        borderRadius: BorderRadius.circular(ThemeSize.radiusTag),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.play_arrow,
            size: ThemeSize.size14,
            color: ThemeColor.colorffffff,
          ),
          const SizedBox(width: ThemeSize.space3),
          Text(
            durationText,
            style: textTheme.labelSmall?.copyWith(
              color: ThemeColor.colorffffff,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
