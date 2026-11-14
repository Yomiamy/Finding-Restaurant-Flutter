// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ugc_note_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UgcNoteDto _$UgcNoteDtoFromJson(Map<String, dynamic> json) => UgcNoteDto(
  id: json['id'] as String?,
  title: json['title'] as String?,
  content: json['content'] as String?,
  authorName: json['author_name'] as String?,
  authorAvatarUrl: json['author_avatar_url'] as String?,
  mediaType: json['media_type'] as String?,
  coverUrl: json['cover_url'] as String?,
  coverAspectRatio: (json['cover_aspect_ratio'] as num?)?.toDouble(),
  imageUrls: (json['image_urls'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  videoUrl: json['video_url'] as String?,
  videoDurationSec: (json['video_duration_sec'] as num?)?.toInt(),
  restaurantName: json['restaurant_name'] as String?,
  createdAtMs: (json['created_at_ms'] as num?)?.toInt(),
);

Map<String, dynamic> _$UgcNoteDtoToJson(UgcNoteDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'author_name': instance.authorName,
      'author_avatar_url': instance.authorAvatarUrl,
      'media_type': instance.mediaType,
      'cover_url': instance.coverUrl,
      'cover_aspect_ratio': instance.coverAspectRatio,
      'image_urls': instance.imageUrls,
      'video_url': instance.videoUrl,
      'video_duration_sec': instance.videoDurationSec,
      'restaurant_name': instance.restaurantName,
      'created_at_ms': instance.createdAtMs,
    };
