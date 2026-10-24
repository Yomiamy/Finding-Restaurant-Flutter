// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_autocomplete_term_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpAutocompleteTermDto _$YelpAutocompleteTermDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('YelpAutocompleteTermDto', json, ($checkedConvert) {
  final val = YelpAutocompleteTermDto(
    text: $checkedConvert('text', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$YelpAutocompleteTermDtoToJson(
  YelpAutocompleteTermDto instance,
) => <String, dynamic>{'text': instance.text};
