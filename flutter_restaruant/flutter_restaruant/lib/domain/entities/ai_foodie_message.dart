import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'a2ui_component.dart';

/// AI 覓食助理對話訊息實體
@immutable
final class AiFoodieMessage extends Equatable {
  const AiFoodieMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.components = const [],
    required this.createdAt,
  });

  factory AiFoodieMessage.user(String text) {
    return AiFoodieMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      isUser: true,
      text: text,
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

  factory AiFoodieMessage.fromJson(Map<String, Object?> json) {
    final rawComponents = json['components'] as List<Object?>? ?? const [];
    final components = rawComponents
        .whereType<Map<String, Object?>>()
        .map(A2UIComponent.fromJson)
        .toList(growable: false);

    return AiFoodieMessage(
      id: json['id'] as String? ?? '',
      isUser: json['is_user'] as bool? ?? false,
      text: json['text'] as String? ?? '',
      components: components,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final bool isUser;
  bool get isAssistant => !isUser;
  final String text;
  final List<A2UIComponent> components;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'is_user': isUser,
    'text': text,
    'components': components.map((c) => c.toJson()).toList(growable: false),
    'created_at': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, isUser, text, components, createdAt];
}
