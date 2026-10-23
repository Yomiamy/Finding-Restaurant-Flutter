import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'yelp_autocomplete_term_dto.g.dart';

@JsonSerializable(checked: true, fieldRename: FieldRename.snake)
class YelpAutocompleteTermDto extends Equatable {
  final String? text;

  const YelpAutocompleteTermDto({this.text});

  factory YelpAutocompleteTermDto.fromJson(Map<String, dynamic> json) =>
      _$YelpAutocompleteTermDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpAutocompleteTermDtoToJson(this);

  @override
  List<Object?> get props => [text];
}
