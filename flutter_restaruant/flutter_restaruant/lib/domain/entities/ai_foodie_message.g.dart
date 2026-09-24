// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_foodie_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AiFoodieMessage _$AiFoodieMessageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AiFoodieMessage', json, ($checkedConvert) {
      final val = AiFoodieMessage(
        id: $checkedConvert('id', (v) => v as String?),
        isUser: $checkedConvert('is_user', (v) => v as bool?),
        text: $checkedConvert('text', (v) => v as String?),
        components: $checkedConvert(
          'components',
          (v) => _componentsFromJson(v as List?),
        ),
        createdAt: $checkedConvert(
          'created_at',
          (v) => _createdAtFromJson(v as String?),
        ),
      );
      return val;
    }, fieldKeyMap: const {'isUser': 'is_user', 'createdAt': 'created_at'});

Map<String, dynamic> _$AiFoodieMessageToJson(AiFoodieMessage instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'is_user': ?instance.isUser,
      'text': ?instance.text,
      'components': ?instance.components?.map((e) => e.toJson()).toList(),
      'created_at': ?instance.createdAt?.toIso8601String(),
    };
