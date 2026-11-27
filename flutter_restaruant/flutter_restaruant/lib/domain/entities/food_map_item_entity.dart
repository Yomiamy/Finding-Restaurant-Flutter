import 'package:equatable/equatable.dart';

import '../../api/dto/food_map_item_dto.dart';
import 'food_map_vote.dart';
import 'restaurant_entity.dart';

class FoodMapItemEntity extends Equatable {
  static const int maxNoteLength = 140;

  final String restaurantId;
  final RestaurantEntity restaurant;
  final String addedByUid;
  final String addedByName;
  final String note;
  final int addedAtMs;
  final Map<String, int> votes;

  const FoodMapItemEntity({
    required this.restaurantId,
    required this.restaurant,
    required this.addedByUid,
    required this.addedByName,
    required this.note,
    required this.addedAtMs,
    required this.votes,
  });

  factory FoodMapItemEntity.fromDto(
    FoodMapItemDto dto, {
    required String docId,
  }) {
    final restaurantDto = dto.restaurant;
    if (restaurantDto == null) {
      throw const FormatException('FoodMapItemDto is missing restaurant');
    }

    final dtoId = (restaurantDto.id ?? '').trim();
    final resolvedId = dtoId.isNotEmpty ? dtoId : docId.trim();
    final restaurant = RestaurantEntity.fromDto(
      restaurantDto,
    ).copyWith(id: resolvedId);

    final validVotes = <String, int>{};
    for (final entry in dto.votes.entries) {
      final uid = entry.key.trim();
      final value = entry.value;
      if (uid.isNotEmpty && (value == 1 || value == -1)) {
        validVotes[uid] = value;
      }
    }

    return FoodMapItemEntity(
      restaurantId: resolvedId,
      restaurant: restaurant,
      addedByUid: (dto.addedByUid ?? '').trim(),
      addedByName: (dto.addedByName ?? '').trim(),
      note: (dto.note ?? '').trim(),
      addedAtMs: dto.addedAtMs ?? 0,
      votes: Map<String, int>.unmodifiable(validVotes),
    );
  }

  int get upvoteCount => votes.values.where((v) => v == 1).length;

  int get downvoteCount => votes.values.where((v) => v == -1).length;

  FoodMapVote voteOf(String uid) => FoodMapVote.fromRaw(votes[uid]);

  bool canModify(String uid, {required String mapOwnerUid}) =>
      uid.isNotEmpty && (uid == mapOwnerUid || uid == addedByUid);

  FoodMapItemEntity withVote(String uid, FoodMapVote vote) {
    final nextVotes = Map<String, int>.from(votes);
    if (vote == FoodMapVote.none) {
      nextVotes.remove(uid);
    } else {
      nextVotes[uid] = vote.rawValue;
    }
    return copyWith(votes: Map<String, int>.unmodifiable(nextVotes));
  }

  FoodMapItemEntity copyWith({
    String? restaurantId,
    RestaurantEntity? restaurant,
    String? addedByUid,
    String? addedByName,
    String? note,
    int? addedAtMs,
    Map<String, int>? votes,
  }) {
    return FoodMapItemEntity(
      restaurantId: restaurantId ?? this.restaurantId,
      restaurant: restaurant ?? this.restaurant,
      addedByUid: addedByUid ?? this.addedByUid,
      addedByName: addedByName ?? this.addedByName,
      note: note ?? this.note,
      addedAtMs: addedAtMs ?? this.addedAtMs,
      votes: votes ?? this.votes,
    );
  }

  @override
  List<Object?> get props => [
    restaurantId,
    restaurant,
    addedByUid,
    addedByName,
    note,
    addedAtMs,
    votes,
  ];
}
