import 'package:equatable/equatable.dart';

import '../../api/dto/food_map_dto.dart';

class FoodMapEntity extends Equatable {
  static const int maxTitleLength = 40;
  static const int maxDescriptionLength = 120;
  static const int inviteCodeLength = 8;

  final String id;
  final String title;
  final String description;
  final String ownerUid;
  final String ownerName;
  final String inviteCode;
  final List<String> memberUids;
  final Map<String, String> memberNames;
  final int itemCount;
  final int createdAtMs;
  final int updatedAtMs;

  const FoodMapEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.ownerUid,
    required this.ownerName,
    required this.inviteCode,
    required this.memberUids,
    required this.memberNames,
    required this.itemCount,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  factory FoodMapEntity.fromDto(FoodMapDto dto, {required String docId}) {
    final ownerUid = (dto.ownerUid ?? '').trim();
    final ownerName = (dto.ownerName ?? '').trim();

    final seen = <String>{};
    final normalizedUids = <String>[];
    final rawUids = dto.memberUids ?? const <String>[];
    if (ownerUid.isNotEmpty && !rawUids.any((e) => e.trim() == ownerUid)) {
      seen.add(ownerUid);
      normalizedUids.add(ownerUid);
    }
    for (final rawUid in rawUids) {
      final uid = rawUid.trim();
      if (uid.isNotEmpty && seen.add(uid)) {
        normalizedUids.add(uid);
      }
    }

    final normalizedNames = <String, String>{};
    for (final entry in (dto.memberNames ?? const <String, String>{}).entries) {
      final key = entry.key.trim();
      final value = entry.value.trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        normalizedNames[key] = value;
      }
    }
    if (ownerUid.isNotEmpty &&
        ownerName.isNotEmpty &&
        !normalizedNames.containsKey(ownerUid)) {
      normalizedNames[ownerUid] = ownerName;
    }

    final rawItemCount = dto.itemCount ?? 0;

    return FoodMapEntity(
      id: docId.trim(),
      title: (dto.title ?? '').trim(),
      description: (dto.description ?? '').trim(),
      ownerUid: ownerUid,
      ownerName: ownerName,
      inviteCode: (dto.inviteCode ?? '').trim().toUpperCase(),
      memberUids: List<String>.unmodifiable(normalizedUids),
      memberNames: Map<String, String>.unmodifiable(normalizedNames),
      itemCount: rawItemCount < 0 ? 0 : rawItemCount,
      createdAtMs: dto.createdAtMs ?? 0,
      updatedAtMs: dto.updatedAtMs ?? 0,
    );
  }

  bool isOwner(String uid) => uid.isNotEmpty && ownerUid == uid;

  int get memberCount => memberUids.length;

  String memberDisplayName(String uid) {
    final mapped = memberNames[uid];
    if (mapped != null && mapped.isNotEmpty) {
      return mapped;
    }
    if (uid == ownerUid && ownerName.isNotEmpty) {
      return ownerName;
    }
    return uid;
  }

  FoodMapEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? ownerUid,
    String? ownerName,
    String? inviteCode,
    List<String>? memberUids,
    Map<String, String>? memberNames,
    int? itemCount,
    int? createdAtMs,
    int? updatedAtMs,
  }) {
    return FoodMapEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ownerUid: ownerUid ?? this.ownerUid,
      ownerName: ownerName ?? this.ownerName,
      inviteCode: inviteCode ?? this.inviteCode,
      memberUids: memberUids ?? this.memberUids,
      memberNames: memberNames ?? this.memberNames,
      itemCount: itemCount ?? this.itemCount,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    ownerUid,
    ownerName,
    inviteCode,
    memberUids,
    memberNames,
    itemCount,
    createdAtMs,
    updatedAtMs,
  ];
}
