// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_autocomplete_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpAutocompleteDto _$YelpAutocompleteDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('YelpAutocompleteDto', json, ($checkedConvert) {
  final val = YelpAutocompleteDto(
    categories: $checkedConvert(
      'categories',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) =>
                YelpRestaurantCategoryDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    businesses: $checkedConvert(
      'businesses',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => YelpRestaurantSummaryDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    terms: $checkedConvert(
      'terms',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => YelpAutocompleteTermDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$YelpAutocompleteDtoToJson(
  YelpAutocompleteDto instance,
) => <String, dynamic>{
  'categories': instance.categories?.map((e) => e.toJson()).toList(),
  'businesses': instance.businesses?.map((e) => e.toJson()).toList(),
  'terms': instance.terms?.map((e) => e.toJson()).toList(),
};
