import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:video_player/video_player.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../features/component/component_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';
import 'notes_feed_page.dart';

/// 探店食記與 15 秒短影片詳情頁。
class NoteDetailPage extends StatefulWidget {
  static const routeName = '/NoteDetailPage';

  final UgcNoteEntity? initialNote;

  const NoteDetailPage({super.key, this.initialNote});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  bool _isInit = false;
  UgcNoteEntity? _note;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      _note = widget.initialNote ?? (args is UgcNoteEntity ? args : null);
      _isInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = _note;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: ThemeColor.colorffffff),
        ),
        title: Text(
          S.current.note_detail_title,
          style: const TextStyle(
            color: ThemeColor.colorffffff,
            fontSize: ThemeFontSize.fontSize22,
          ),
        ),
        backgroundColor: ThemeColor.colord84a20,
      ),
      body: note == null
          ? EmptyDataWidget.withDefaults()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (note.isVideo)
                    NoteVideoPlayer(
                      videoUrl: note.videoUrl,
                      coverUrl: note.coverUrl,
                      aspectRatio: note.coverAspectRatio,
                      formattedDuration: note.formattedVideoDuration,
                    )
                  else
                    NoteImageCarousel(
                      imageUrls: note.imageUrls,
                      aspectRatio: note.coverAspectRatio,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(ThemeSize.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.account_circle,
                              size: ThemeSize.size24,
                              color: ThemeColor.colord84a20,
                            ),
                            const SizedBox(width: ThemeSize.space8),
                            Expanded(
                              child: Text(
                                note.authorName,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: ThemeSize.space12),
                        Text(
                          note.title,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (note.restaurantName.isNotEmpty) ...[
                          const SizedBox(height: ThemeSize.space8),
                          NoteRestaurantTag(
                            restaurantName: note.restaurantName,
                          ),
                        ],
                        const SizedBox(height: ThemeSize.space12),
                        Text(
                          note.content,
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
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

/// 詳情頁中的靜態餐廳名稱標籤。
class NoteRestaurantTag extends StatelessWidget {
  final String restaurantName;

  const NoteRestaurantTag({super.key, required this.restaurantName});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const Key('note_detail_restaurant_tag'),
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeSize.space10,
        vertical: ThemeSize.space4,
      ),
      decoration: BoxDecoration(
        color: ThemeColor.colord84a20.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ThemeSize.radiusTag),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.place,
            size: ThemeSize.size16,
            color: ThemeColor.colord84a20,
          ),
          const SizedBox(width: ThemeSize.space4),
          Flexible(
            child: Text(
              restaurantName,
              style: textTheme.bodyMedium?.copyWith(
                color: ThemeColor.colord84a20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 多圖食記的左右滑動輪播元件與頁碼指示器。
class NoteImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double aspectRatio;

  const NoteImageCarousel({
    super.key,
    required this.imageUrls,
    required this.aspectRatio,
  });

  @override
  State<NoteImageCarousel> createState() => _NoteImageCarouselState();
}

class _NoteImageCarouselState extends State<NoteImageCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls.isEmpty ? const [''] : widget.imageUrls;
    final textTheme = Theme.of(context).textTheme;

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            key: const Key('note_image_page_view'),
            itemCount: urls.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return NoteCoverImage(imageUrl: urls[index]);
            },
          ),
          if (urls.length > 1)
            Positioned(
              bottom: ThemeSize.space12,
              right: ThemeSize.space12,
              child: Container(
                key: const Key('note_carousel_indicator'),
                padding: const EdgeInsets.symmetric(
                  horizontal: ThemeSize.space10,
                  vertical: ThemeSize.space4,
                ),
                decoration: BoxDecoration(
                  color: ThemeColor.color8a000000,
                  borderRadius: BorderRadius.circular(ThemeSize.radiusTag),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${urls.length}',
                  style: textTheme.labelSmall?.copyWith(
                    color: ThemeColor.colorffffff,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 15 秒短影片播放元件，支援點擊播放／暫停與無原生通道時的降級視覺面板。
class NoteVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String coverUrl;
  final double aspectRatio;
  final String formattedDuration;

  const NoteVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.coverUrl,
    required this.aspectRatio,
    required this.formattedDuration,
  });

  @override
  State<NoteVideoPlayer> createState() => _NoteVideoPlayerState();
}

class _NoteVideoPlayerState extends State<NoteVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initVideo());
  }

  Future<void> _initVideo() async {
    final uri = Uri.tryParse(widget.videoUrl);
    if (uri == null || widget.videoUrl.isEmpty) {
      if (mounted) {
        setState(() => _hasError = true);
      }
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setLooping(true);
      if (!mounted) return;
      await controller.play();
      if (!mounted) return;
      setState(() => _isInitialized = true);
    } on Exception catch (e, st) {
      Logger().w('NoteVideoPlayer init failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _hasError = true);
    } on UnimplementedError catch (e, st) {
      // video_player_platform_interface 預設無原生通道（如 Widget 測試）時拋出 UnimplementedError
      Logger().w(
        'NoteVideoPlayer platform unimplemented',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null || !_isInitialized) return;
    if (controller.value.isPlaying) {
      unawaited(controller.pause());
    } else {
      unawaited(controller.play());
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (_hasError || controller == null) {
      return NoteVideoFallbackPanel(
        coverUrl: widget.coverUrl,
        aspectRatio: widget.aspectRatio,
        formattedDuration: widget.formattedDuration,
      );
    }

    if (!_isInitialized) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: const ColoredBox(
          color: ThemeColor.color8a000000,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: GestureDetector(
        key: const Key('note_video_surface'),
        onTap: _togglePlayPause,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoPlayer(controller),
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                if (value.isPlaying) return const SizedBox.shrink();
                return child ?? const SizedBox.shrink();
              },
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  size: ThemeSize.size64,
                  color: ThemeColor.colorffffff,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(controller, allowScrubbing: true),
            ),
          ],
        ),
      ),
    );
  }
}

/// 短影片無法初始化或處於無原生通道環境時的降級面板。
class NoteVideoFallbackPanel extends StatelessWidget {
  final String coverUrl;
  final double aspectRatio;
  final String formattedDuration;

  const NoteVideoFallbackPanel({
    super.key,
    required this.coverUrl,
    required this.aspectRatio,
    required this.formattedDuration,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AspectRatio(
      key: const Key('note_video_fallback'),
      aspectRatio: aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NoteCoverImage(imageUrl: coverUrl),
          ColoredBox(
            color: ThemeColor.color8a000000,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_outline,
                  size: ThemeSize.size64,
                  color: ThemeColor.colorffffff,
                ),
                const SizedBox(height: ThemeSize.space8),
                Text(
                  formattedDuration,
                  style: textTheme.titleMedium?.copyWith(
                    color: ThemeColor.colorffffff,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: ThemeSize.space4),
                Text(
                  S.current.note_video_error,
                  style: textTheme.bodyMedium?.copyWith(
                    color: ThemeColor.colorffffff,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
