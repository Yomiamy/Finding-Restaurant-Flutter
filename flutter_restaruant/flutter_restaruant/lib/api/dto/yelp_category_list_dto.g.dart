// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_category_list_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpCategoryListDto _$YelpCategoryListDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('YelpCategoryListDto', json, ($checkedConvert) {
      final val = YelpCategoryListDto(
        categories: $checkedConvert(
          'categories',
          (v) => (v as List<dynamic>?)
              ?.map(
                (e) => YelpRestaurantCategoryDto.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$YelpCategoryListDtoToJson(
  YelpCategoryListDto instance,
) => <String, dynamic>{
  'categories': instance.categories?.map((e) => e.toJson()).toList(),
};
