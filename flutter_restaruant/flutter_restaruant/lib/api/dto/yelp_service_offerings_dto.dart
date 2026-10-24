import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'yelp_service_offerings_dto.g.dart';

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
