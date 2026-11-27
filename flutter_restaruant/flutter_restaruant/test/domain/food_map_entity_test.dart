import 'package:flutter_restaruant/api/dto/dto_barrel.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

class _Data {
  static const Map<String, dynamic> mapJson = {
    'title': '  台北深夜拉麵地圖  ',
    'description': '  下班必吃清單  ',
    'owner_uid': 'owner-1',
    'owner_name': 'Alice',
    'invite_code': ' abcd2345 ',
    'member_uids': ['member-2', 'owner-1', 'member-2'],
    'member_names': {'owner-1': 'Alice', 'member-2': 'Bob'},
    'item_count': 3,
    'created_at_ms': 1000,
    'updated_at_ms': 2000,
  };

  static const Map<String, dynamic> restaurantJson = {
    'id': 'rest-1',
    'name': '隱家拉麵',
    'image_url': 'https://example.com/ramen.jpg',
    'rating': 4.7,
    'review_count': 120,
    'price': r'$$',
    'coordinates': {'latitude': 25.052, 'longitude': 121.52},
  };

  static const Map<String, dynamic> itemJson = {
    'restaurant': restaurantJson,
    'added_by_uid': 'member-2',
    'added_by_name': 'Bob',
    'note': '  叉燒必加點  ',
    'added_at_ms': 1500,
    'votes': {'owner-1': 1, 'member-2': -1, 'invalid': 99},
  };
}

void main() {
  group('FoodMapVote', () {
    test('fromRaw maps 1, -1, and other values accurately', () {
      expect(FoodMapVote.fromRaw(1), FoodMapVote.up);
      expect(FoodMapVote.fromRaw(-1), FoodMapVote.down);
      expect(FoodMapVote.fromRaw(0), FoodMapVote.none);
      expect(FoodMapVote.fromRaw(null), FoodMapVote.none);
      expect(FoodMapVote.fromRaw(42), FoodMapVote.none);
    });
  });

  group('FoodMapDto & FoodMapEntity', () {
    test('FoodMapDto serializes and deserializes with snake_case keys', () {
      final dto = FoodMapDto.fromJson(_Data.mapJson);
      expect(dto.ownerUid, 'owner-1');
      expect(dto.ownerName, 'Alice');
      expect(dto.inviteCode, ' abcd2345 ');
      expect(dto.memberUids, ['member-2', 'owner-1', 'member-2']);
      expect(dto.itemCount, 3);
      expect(dto.createdAtMs, 1000);
      expect(dto.updatedAtMs, 2000);

      final out = dto.toJson();
      expect(out.containsKey('owner_uid'), isTrue);
      expect(out.containsKey('owner_name'), isTrue);
      expect(out.containsKey('invite_code'), isTrue);
      expect(out.containsKey('member_uids'), isTrue);
      expect(out.containsKey('member_names'), isTrue);
      expect(out.containsKey('item_count'), isTrue);
      expect(out.containsKey('created_at_ms'), isTrue);
      expect(out.containsKey('updated_at_ms'), isTrue);
    });

    test(
      'FoodMapEntity.fromDto normalizes fields and deduplicates members',
      () {
        final dto = FoodMapDto.fromJson(_Data.mapJson);
        final entity = FoodMapEntity.fromDto(dto, docId: 'map-1');

        expect(entity.id, 'map-1');
        expect(entity.title, '台北深夜拉麵地圖');
        expect(entity.description, '下班必吃清單');
        expect(entity.inviteCode, 'ABCD2345');
        expect(entity.memberUids, ['member-2', 'owner-1']);
        expect(entity.memberCount, 2);
        expect(entity.isOwner('owner-1'), isTrue);
        expect(entity.isOwner('member-2'), isFalse);
        expect(entity.memberDisplayName('member-2'), 'Bob');
        expect(entity.memberDisplayName('unknown-uid'), 'unknown-uid');
      },
    );

    test(
      'FoodMapEntity.fromDto inserts missing ownerUid and clamps negative itemCount',
      () {
        const dto = FoodMapDto(
          title: 'Test',
          ownerUid: 'owner-1',
          ownerName: 'Alice',
          memberUids: ['member-2'],
          itemCount: -5,
        );
        final entity = FoodMapEntity.fromDto(dto, docId: 'map-2');

        expect(entity.memberUids, ['owner-1', 'member-2']);
        expect(entity.memberDisplayName('owner-1'), 'Alice');
        expect(entity.itemCount, 0);
      },
    );
  });

  group('FoodMapItemDto & FoodMapItemEntity', () {
    test(
      'FoodMapItemDto defaults votes to empty non-null map and uses snake_case',
      () {
        final dto = FoodMapItemDto(
          restaurant: YelpRestaurantSummaryDto.fromJson(_Data.restaurantJson),
          addedByUid: 'owner-1',
          addedByName: 'Alice',
          note: '必吃',
          addedAtMs: 1234,
        );

        final out = dto.toJson();
        expect(out['added_by_uid'], 'owner-1');
        expect(out['added_by_name'], 'Alice');
        expect(out['added_at_ms'], 1234);
        expect(out['votes'], isA<Map<String, int>>());
        expect(out['votes'], isEmpty);
        expect(out['restaurant'], isA<Map<String, dynamic>>());
      },
    );

    test(
      'FoodMapItemEntity.fromDto filters invalid votes and computes counts and permissions',
      () {
        final dto = FoodMapItemDto.fromJson(_Data.itemJson);
        final item = FoodMapItemEntity.fromDto(dto, docId: 'rest-1');

        expect(item.restaurantId, 'rest-1');
        expect(item.restaurant.name, '隱家拉麵');
        expect(item.note, '叉燒必加點');
        expect(item.votes, {'owner-1': 1, 'member-2': -1});
        expect(item.upvoteCount, 1);
        expect(item.downvoteCount, 1);
        expect(item.voteOf('owner-1'), FoodMapVote.up);
        expect(item.voteOf('member-2'), FoodMapVote.down);
        expect(item.voteOf('other'), FoodMapVote.none);

        expect(item.canModify('owner-1', mapOwnerUid: 'owner-1'), isTrue);
        expect(item.canModify('member-2', mapOwnerUid: 'owner-1'), isTrue);
        expect(item.canModify('member-3', mapOwnerUid: 'owner-1'), isFalse);
        expect(item.canModify('', mapOwnerUid: 'owner-1'), isFalse);

        final updated = item.withVote('member-2', FoodMapVote.none);
        expect(updated.downvoteCount, 0);
        expect(updated.voteOf('member-2'), FoodMapVote.none);

        final upvoted = updated.withVote('member-3', FoodMapVote.up);
        expect(upvoted.upvoteCount, 2);
        expect(upvoted.voteOf('member-3'), FoodMapVote.up);
      },
    );

    test(
      'FoodMapItemEntity.fromDto throws FormatException when restaurant is null',
      () {
        const dto = FoodMapItemDto(
          restaurant: null,
          addedByUid: 'owner-1',
          addedByName: 'Alice',
        );
        expect(
          () => FoodMapItemEntity.fromDto(dto, docId: 'rest-1'),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test(
      'FoodMapItemEntity.fromDto falls back to docId when restaurant.id is missing',
      () {
        final dto = FoodMapItemDto(
          restaurant: YelpRestaurantSummaryDto(name: 'No ID Shop'),
          addedByUid: 'owner-1',
          addedByName: 'Alice',
        );
        final item = FoodMapItemEntity.fromDto(dto, docId: 'fallback-doc-id');
        expect(item.restaurantId, 'fallback-doc-id');
        expect(item.restaurant.id, 'fallback-doc-id');
      },
    );
  });

  group('FoodMapException', () {
    test('toString includes code name and optional debugMessage', () {
      const e1 = FoodMapException(FoodMapErrorCode.mapNotFound);
      const e2 = FoodMapException(
        FoodMapErrorCode.permissionDenied,
        'not owner',
      );
      expect(e1.toString(), 'FoodMapException(mapNotFound)');
      expect(e2.toString(), 'FoodMapException(permissionDenied: not owner)');
    });
  });
}
