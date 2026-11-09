import 'package:equatable/equatable.dart';

import '../../api/dto/ugc_note_dto.dart';

/// 探店筆記領域實體（唯讀瀏覽模型）。
class UgcNoteEntity extends Equatable {
  static const double defaultAspectRatio = 0.8;
  static const double minAspectRatio = 0.6;
  static const double maxAspectRatio = 1.5;
  static const int maxVideoDurationSec = 15;

  final String id;
  final String title;
  final String content;
  final String authorName;
  final String authorAvatarUrl;
  final bool isVideo;
  final String coverUrl;
  final double coverAspectRatio;
  final List<String> imageUrls;
  final String videoUrl;
  final int videoDurationSec;
  final String restaurantName;
  final int createdAtMs;

  const UgcNoteEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.isVideo,
    required this.coverUrl,
    required this.coverAspectRatio,
    required this.imageUrls,
    required this.videoUrl,
    required this.videoDurationSec,
    required this.restaurantName,
    required this.createdAtMs,
  });

  factory UgcNoteEntity.fromDto(UgcNoteDto dto, {String? docId}) {
    final rawRatio = dto.coverAspectRatio ?? defaultAspectRatio;
    final safeRatio = rawRatio.isNaN || rawRatio.isInfinite || rawRatio <= 0
        ? defaultAspectRatio
        : rawRatio.clamp(minAspectRatio, maxAspectRatio);

    final rawImages = (dto.imageUrls ?? const <String>[])
        .where((e) => e.trim().isNotEmpty)
        .map((e) => e.trim())
        .toList();
    final primaryCover = (dto.coverUrl?.trim().isNotEmpty ?? false)
        ? dto.coverUrl!.trim()
        : (rawImages.isNotEmpty ? rawImages.first : '');
    final normalizedImages = rawImages.isNotEmpty
        ? rawImages
        : (primaryCover.isNotEmpty ? <String>[primaryCover] : const <String>[]);

    final videoUrl = dto.videoUrl?.trim() ?? '';
    final isVideo = dto.mediaType == 'video' && videoUrl.isNotEmpty;
    final rawDuration = dto.videoDurationSec ?? maxVideoDurationSec;
    final safeDuration = rawDuration.clamp(1, maxVideoDurationSec);

    return UgcNoteEntity(
      id: (dto.id?.trim().isNotEmpty ?? false) ? dto.id!.trim() : (docId ?? ''),
      title: dto.title?.trim() ?? '',
      content: dto.content?.trim() ?? '',
      authorName: dto.authorName?.trim() ?? '',
      authorAvatarUrl: dto.authorAvatarUrl?.trim() ?? '',
      isVideo: isVideo,
      coverUrl: primaryCover,
      coverAspectRatio: safeRatio,
      imageUrls: normalizedImages,
      videoUrl: videoUrl,
      videoDurationSec: safeDuration,
      restaurantName: dto.restaurantName?.trim() ?? '',
      createdAtMs: dto.createdAtMs ?? 0,
    );
  }

  /// 格式化為 `0:SS`（最多 15 秒）。
  String get formattedVideoDuration {
    final secs = videoDurationSec.clamp(1, maxVideoDurationSec);
    return '0:${secs.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    authorName,
    authorAvatarUrl,
    isVideo,
    coverUrl,
    coverAspectRatio,
    imageUrls,
    videoUrl,
    videoDurationSec,
    restaurantName,
    createdAtMs,
  ];
}
