// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_service_offerings_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpServiceOfferingsDto _$YelpServiceOfferingsDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('YelpServiceOfferingsDto', json, ($checkedConvert) {
  final val = YelpServiceOfferingsDto(
    active: $checkedConvert(
      'active',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
    ),
    eligible: $checkedConvert(
      'eligible',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$YelpServiceOfferingsDtoToJson(
  YelpServiceOfferingsDto instance,
) => <String, dynamic>{
  'active': instance.active,
  'eligible': instance.eligible,
};
