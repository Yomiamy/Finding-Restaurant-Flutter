import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ugc_note_dto.g.dart';

@JsonSerializable()
class UgcNoteDto extends Equatable {
  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'title')
  final String? title;

  @JsonKey(name: 'content')
  final String? content;

  @JsonKey(name: 'author_name')
  final String? authorName;

  @JsonKey(name: 'author_avatar_url')
  final String? authorAvatarUrl;

  @JsonKey(name: 'media_type')
  final String? mediaType;

  @JsonKey(name: 'cover_url')
  final String? coverUrl;

  @JsonKey(name: 'cover_aspect_ratio')
  final double? coverAspectRatio;

  @JsonKey(name: 'image_urls')
  final List<String>? imageUrls;

  @JsonKey(name: 'video_url')
  final String? videoUrl;

  @JsonKey(name: 'video_duration_sec')
  final int? videoDurationSec;

  @JsonKey(name: 'restaurant_name')
  final String? restaurantName;

  @JsonKey(name: 'created_at_ms')
  final int? createdAtMs;

  const UgcNoteDto({
    this.id,
    this.title,
    this.content,
    this.authorName,
    this.authorAvatarUrl,
    this.mediaType,
    this.coverUrl,
    this.coverAspectRatio,
    this.imageUrls,
    this.videoUrl,
    this.videoDurationSec,
    this.restaurantName,
    this.createdAtMs,
  });

  factory UgcNoteDto.fromJson(Map<String, dynamic> json) =>
      _$UgcNoteDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UgcNoteDtoToJson(this);

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    authorName,
    authorAvatarUrl,
    mediaType,
    coverUrl,
    coverAspectRatio,
    imageUrls,
    videoUrl,
    videoDurationSec,
    restaurantName,
    createdAtMs,
  ];
}
