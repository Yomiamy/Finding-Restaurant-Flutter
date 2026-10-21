// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_summary_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewSummaryEntity _$ReviewSummaryEntityFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReviewSummaryEntity', json, ($checkedConvert) {
      final val = ReviewSummaryEntity(
        pros: $checkedConvert(
          'pros',
          (v) => v == null ? const [] : _stringListFromJson(v as List?),
        ),
        cons: $checkedConvert(
          'cons',
          (v) => v == null ? const [] : _stringListFromJson(v as List?),
        ),
        highlights: $checkedConvert(
          'highlights',
          (v) => v == null ? const [] : _stringListFromJson(v as List?),
        ),
        summary: $checkedConvert('summary', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$ReviewSummaryEntityToJson(
  ReviewSummaryEntity instance,
) => <String, dynamic>{
  'pros': instance.pros,
  'cons': instance.cons,
  'highlights': instance.highlights,
  'summary': instance.summary,
};
