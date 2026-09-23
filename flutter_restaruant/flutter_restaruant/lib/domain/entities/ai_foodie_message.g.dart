// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_foodie_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AiFoodieMessage _$AiFoodieMessageFromJson(Map<String, dynamic> json) =>
    AiFoodieMessage(
      id: json['id'] as String?,
      isUser: json['is_user'] as bool?,
      text: json['text'] as String?,
      components: _componentsFromJson(json['components'] as List?),
      createdAt: _createdAtFromJson(json['created_at'] as String?),
    );

Map<String, dynamic> _$AiFoodieMessageToJson(AiFoodieMessage instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'is_user': ?instance.isUser,
      'text': ?instance.text,
      'components': ?instance.components?.map((e) => e.toJson()).toList(),
      'created_at': ?instance.createdAt?.toIso8601String(),
    };
