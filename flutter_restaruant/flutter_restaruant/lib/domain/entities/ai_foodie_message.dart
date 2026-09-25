import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'a2ui_component.dart';
import 'entity_json_converters.dart';

part 'ai_foodie_message.g.dart';

/// AI 覓食助理對話訊息實體
@immutable
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
  explicitToJson: true,
)
final class AiFoodieMessage extends Equatable {
  const AiFoodieMessage({
    this.id,
    this.isUser,
    this.text,
    this.components,
    this.createdAt,
  });

  factory AiFoodieMessage.user(String text) {
    return AiFoodieMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      isUser: true,
      text: text,
      components: const [],
      createdAt: DateTime.now(),
    );
  }

  factory AiFoodieMessage.assistant({
    required String text,
    List<A2UIComponent> components = const [],
  }) {
    return AiFoodieMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      isUser: false,
      text: text,
      components: components,
      createdAt: DateTime.now(),
    );
  }

  factory AiFoodieMessage.fromJson(Map<String, Object?> json) =>
      _$AiFoodieMessageFromJson(json);

  final String? id;
  final bool? isUser;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isAssistant => isUser != true;
  final String? text;
  @JsonKey(fromJson: _componentsFromJson, toJson: _componentsToJson)
  final List<A2UIComponent>? components;
  @JsonKey(fromJson: _createdAtFromJson)
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$AiFoodieMessageToJson(this);

  @override
  List<Object?> get props => [id, isUser, text, components, createdAt];
}

List<A2UIComponent>? _componentsFromJson(List<Object?>? raw) =>
    mapListFromJson(raw, A2UIComponent.fromJson);

List<Map<String, Object?>>? _componentsToJson(
  List<A2UIComponent>? components,
) => components?.map((c) => c.toEnvelopeJson()).toList();

/// 參數型別 `String?`：非字串由 checked 產生碼包成 CheckedFromJsonException；字串解析失敗回傳 null。
DateTime? _createdAtFromJson(String? value) =>
    value == null ? null : DateTime.tryParse(value);
