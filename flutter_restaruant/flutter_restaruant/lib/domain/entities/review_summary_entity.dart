import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'entity_json_converters.dart';

part 'review_summary_entity.g.dart';

/// 餐廳評論智慧摘要領域實體
@immutable
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
)
class ReviewSummaryEntity extends Equatable {
  const ReviewSummaryEntity({
    this.pros = const [],
    this.cons = const [],
    this.highlights = const [],
    this.summary = '',
  });

  factory ReviewSummaryEntity.fromJson(Map<String, Object?> json) =>
      _$ReviewSummaryEntityFromJson(json);

  @JsonKey(fromJson: _stringListFromJson)
  final List<String> pros;

  @JsonKey(fromJson: _stringListFromJson)
  final List<String> cons;

  @JsonKey(fromJson: _stringListFromJson)
  final List<String> highlights;

  final String summary;

  Map<String, Object?> toJson() => _$ReviewSummaryEntityToJson(this);

  @override
  List<Object?> get props => [pros, cons, highlights, summary];
}

List<String> _stringListFromJson(List<Object?>? raw) =>
    stringListFromJson(raw) ?? const [];
