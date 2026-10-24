import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'yelp_service_offerings_dto.g.dart';

/// `/v3/businesses/{id}/service_offerings` 的回應。
///
/// ⚠️ 僅供參照：該端點已被 Yelp 標為 deprecated。官方只定義 [active]、[eligible]
/// 為字串陣列，未列出可能的值。
@JsonSerializable(checked: true, fieldRename: FieldRename.snake)
class YelpServiceOfferingsDto extends Equatable {
  final List<String>? active;
  final List<String>? eligible;

  const YelpServiceOfferingsDto({this.active, this.eligible});

  factory YelpServiceOfferingsDto.fromJson(Map<String, dynamic> json) =>
      _$YelpServiceOfferingsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpServiceOfferingsDtoToJson(this);

  @override
  List<Object?> get props => [active, eligible];
}
