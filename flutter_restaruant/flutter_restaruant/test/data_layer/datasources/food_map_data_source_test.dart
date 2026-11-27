import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_restaruant/data_layer/datasources/datasources_barrel.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

class _FixedSequenceRandom implements Random {
  final List<int> _values;
  int _index = 0;

  _FixedSequenceRandom(this._values);

  @override
  int nextInt(int max) {
    final value = _values[_index % _values.length];
    _index++;
    return value % max;
  }

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() => 0.0;
}

class _Data {
  static const RestaurantEntity ramen = RestaurantEntity(
    id: 'rest-ramen',
    name: '隱家拉麵',
    imageUrl: 'https://example.com/ramen.jpg',
    rating: 4.8,
    reviewCount: 200,
    price: r'$$',
    coordinates: RestaurantCoordinatesEntity(
      latitude: 25.052,
      longitude: 121.52,
    ),
  );

  static const RestaurantEntity sushi = RestaurantEntity(
    id: 'rest-sushi',
    name: '初魚鮨',
    imageUrl: 'https://example.com/sushi.jpg',
    rating: 4.9,
    reviewCount: 150,
    price: r'$$$$',
    coordinates: RestaurantCoordinatesEntity(
      latitude: 25.033,
      longitude: 121.564,
    ),
  );

  static const RestaurantEntity cafe = RestaurantEntity(
    id: 'rest-cafe',
    name: '興波咖啡',
    rating: 4.6,
    reviewCount: 310,
  );
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late String currentUid;
  late String currentName;
  late int clockMs;
  late FoodMapDataSource dataSource;

  FoodMapDataSource createDataSource({Random? random}) {
    return FoodMapDataSource(
      firestore: fakeFirestore,
      uidProvider: () => currentUid,
      displayNameProvider: () => currentName,
      nowMsProvider: () => clockMs += 100,
      random: random,
      logger: Logger(level: Level.off),
    );
  }

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    currentUid = 'user-a';
    currentName = 'Alice';
    clockMs = 10000;
    dataSource = createDataSource(random: Random(42));
  });

  group('Guest / unauthenticated guards', () {
    test('fetchMyFoodMaps returns empty list when uid is empty', () async {
      currentUid = '';
      expect(await dataSource.fetchMyFoodMaps(), isEmpty);
    });

    test(
      'all write operations and detail fetch throw StateError when uid is empty',
      () async {
        currentUid = '';

        await expectLater(
          dataSource.fetchFoodMapDetail('m1'),
          throwsStateError,
        );
        await expectLater(
          dataSource.createFoodMap(title: 'Test'),
          throwsStateError,
        );
        await expectLater(
          dataSource.joinFoodMapByInviteCode('ABCD2345'),
          throwsStateError,
        );
        await expectLater(dataSource.deleteFoodMap('m1'), throwsStateError);
        await expectLater(dataSource.leaveFoodMap('m1'), throwsStateError);
        await expectLater(
          dataSource.addRestaurant(mapId: 'm1', restaurant: _Data.ramen),
          throwsStateError,
        );
        await expectLater(
          dataSource.importRestaurants(mapId: 'm1', restaurants: const []),
          throwsStateError,
        );
        await expectLater(
          dataSource.removeRestaurant(mapId: 'm1', restaurantId: 'r1'),
          throwsStateError,
        );
        await expectLater(
          dataSource.updateItemNote(
            mapId: 'm1',
            restaurantId: 'r1',
            note: 'hi',
          ),
          throwsStateError,
        );
        await expectLater(
          dataSource.setVote(
            mapId: 'm1',
            restaurantId: 'r1',
            vote: FoodMapVote.up,
          ),
          throwsStateError,
        );
      },
    );

    test('invalid doc IDs throw FoodMapException(invalidInput)', () async {
      await expectLater(
        dataSource.fetchFoodMapDetail('bad/id'),
        throwsA(
          isA<FoodMapException>().having(
            (e) => e.code,
            'code',
            FoodMapErrorCode.invalidInput,
          ),
        ),
      );
      await expectLater(
        dataSource.fetchFoodMapDetail('..'),
        throwsA(
          isA<FoodMapException>().having(
            (e) => e.code,
            'code',
            FoodMapErrorCode.invalidInput,
          ),
        ),
      );
      await expectLater(
        dataSource.fetchFoodMapDetail('.'),
        throwsA(
          isA<FoodMapException>().having(
            (e) => e.code,
            'code',
            FoodMapErrorCode.invalidInput,
          ),
        ),
      );
    });
  });

  group('createFoodMap & invite code collision', () {
    test(
      'creates food_maps doc with snake_case fields and invite index',
      () async {
        final created = await dataSource.createFoodMap(
          title: '  台北拉麵地圖  ',
          description: '  私房清單  ',
        );

        expect(created.title, '台北拉麵地圖');
        expect(created.description, '私房清單');
        expect(created.ownerUid, 'user-a');
        expect(created.ownerName, 'Alice');
        expect(created.memberUids, ['user-a']);
        expect(created.memberNames, {'user-a': 'Alice'});
        expect(created.itemCount, 0);
        expect(created.inviteCode.length, 8);

        final rawMap = await fakeFirestore
            .collection(FoodMapDataSource.mapsCollectionName)
            .doc(created.id)
            .get();
        expect(rawMap.data()?['owner_uid'], 'user-a');
        expect(rawMap.data()?['member_uids'], ['user-a']);
        expect(rawMap.data()?['item_count'], 0);

        final inviteDoc = await fakeFirestore
            .collection(FoodMapDataSource.invitesCollectionName)
            .doc(created.inviteCode)
            .get();
        expect(inviteDoc.exists, isTrue);
        expect(inviteDoc.data()?['map_id'], created.id);
        expect(inviteDoc.data()?['owner_uid'], 'user-a');
      },
    );

    test('retries invite code generation on collision and succeeds', () async {
      // First 8 draws -> 'AAAAAAAA'; next 8 draws -> 'BBBBBBBB'.
      final seeded = createDataSource(
        random: _FixedSequenceRandom([
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          1,
          1,
          1,
          1,
          1,
          1,
          1,
          1,
        ]),
      );
      await fakeFirestore
          .collection(FoodMapDataSource.invitesCollectionName)
          .doc('AAAAAAAA')
          .set({'map_id': 'existing-map', 'owner_uid': 'someone'});

      final created = await seeded.createFoodMap(title: 'Retry Map');
      expect(created.inviteCode, 'BBBBBBBB');
    });

    test(
      'throws invalidInput on blank or overly long title/description',
      () async {
        await expectLater(
          dataSource.createFoodMap(title: '   '),
          throwsA(
            isA<FoodMapException>().having(
              (e) => e.code,
              'code',
              FoodMapErrorCode.invalidInput,
            ),
          ),
        );
        await expectLater(
          dataSource.createFoodMap(title: 'a' * 41),
          throwsA(
            isA<FoodMapException>().having(
              (e) => e.code,
              'code',
              FoodMapErrorCode.invalidInput,
            ),
          ),
        );
        await expectLater(
          dataSource.createFoodMap(title: 'Valid', description: 'b' * 121),
          throwsA(
            isA<FoodMapException>().having(
              (e) => e.code,
              'code',
              FoodMapErrorCode.invalidInput,
            ),
          ),
        );
      },
    );
  });

  group('joinFoodMapByInviteCode & fetchMyFoodMaps', () {
    test(
      'normalizes code, joins new member, and handles duplicate join idempotently',
      () async {
        final created = await dataSource.createFoodMap(title: '週末聚餐');

        currentUid = 'user-b';
        currentName = 'Bob';

        final firstJoin = await dataSource.joinFoodMapByInviteCode(
          '  ${created.inviteCode.toLowerCase()}  ',
        );
        expect(firstJoin.alreadyMember, isFalse);
        expect(firstJoin.map.memberUids, ['user-a', 'user-b']);
        expect(firstJoin.map.memberNames['user-b'], 'Bob');

        final secondJoin = await dataSource.joinFoodMapByInviteCode(
          created.inviteCode,
        );
        expect(secondJoin.alreadyMember, isTrue);
        expect(secondJoin.map.memberUids, ['user-a', 'user-b']);

        final myMaps = await dataSource.fetchMyFoodMaps();
        expect(myMaps.map((m) => m.id), [created.id]);
      },
    );

    test(
      'throws invalidInviteCode for malformed codes and mapNotFound for missing codes',
      () async {
        await expectLater(
          dataSource.joinFoodMapByInviteCode('SHORT'),
          throwsA(
            isA<FoodMapException>().having(
              (e) => e.code,
              'code',
              FoodMapErrorCode.invalidInviteCode,
            ),
          ),
        );
        await expectLater(
          dataSource.joinFoodMapByInviteCode('ZZZZ9999'),
          throwsA(
            isA<FoodMapException>().having(
              (e) => e.code,
              'code',
              FoodMapErrorCode.mapNotFound,
            ),
          ),
        );
      },
    );
  });

  group('addRestaurant, importRestaurants, votes, note, and remove permissions', () {
    test(
      'addRestaurant stores non-null votes map, prevents duplicates, and keeps item_count accurate',
      () async {
        final map = await dataSource.createFoodMap(title: '拉麵巡禮');

        final first = await dataSource.addRestaurant(
          mapId: map.id,
          restaurant: _Data.ramen,
          note: '  濃湯必點  ',
        );
        expect(first.added, isTrue);
        expect(first.item.note, '濃湯必點');

        final rawItem = await fakeFirestore
            .collection(FoodMapDataSource.mapsCollectionName)
            .doc(map.id)
            .collection(FoodMapDataSource.itemsSubcollectionName)
            .doc(_Data.ramen.id)
            .get();
        expect(rawItem.data()?['votes'], isA<Map>());
        expect(rawItem.data()?['votes'], isEmpty);

        final duplicate = await dataSource.addRestaurant(
          mapId: map.id,
          restaurant: _Data.ramen,
          note: 'ignored',
        );
        expect(duplicate.added, isFalse);

        final detail = await dataSource.fetchFoodMapDetail(map.id);
        expect(detail.map.itemCount, 1);
        expect(detail.items.length, 1);

        // Non-member cannot add restaurant
        currentUid = 'outsider';
        currentName = 'Eve';
        await expectLater(
          dataSource.addRestaurant(mapId: map.id, restaurant: _Data.sushi),
          throwsA(
            isA<FoodMapException>().having(
              (e) => e.code,
              'code',
              FoodMapErrorCode.permissionDenied,
            ),
          ),
        );
      },
    );

    test(
      'importRestaurants skips existing, duplicate, and invalid IDs accurately',
      () async {
        final map = await dataSource.createFoodMap(title: '最愛匯入');
        await dataSource.addRestaurant(mapId: map.id, restaurant: _Data.ramen);

        final result = await dataSource.importRestaurants(
          mapId: map.id,
          restaurants: const [
            _Data.ramen, // already in map
            _Data.sushi, // new
            _Data.sushi, // duplicate in input
            RestaurantEntity(id: '', name: 'Invalid Empty'),
            RestaurantEntity(id: 'bad/id', name: 'Invalid Slash'),
            _Data.cafe, // new
          ],
        );

        expect(result.addedCount, 2);
        expect(result.skippedCount, 4);

        final detail = await dataSource.fetchFoodMapDetail(map.id);
        expect(detail.map.itemCount, 3);
        expect(detail.items.length, 3);

        // Non-member cannot import restaurants
        currentUid = 'outsider';
        currentName = 'Eve';
        await expectLater(
          dataSource.importRestaurants(
            mapId: map.id,
            restaurants: const [_Data.sushi],
          ),
          throwsA(
            isA<FoodMapException>().having(
              (e) => e.code,
              'code',
              FoodMapErrorCode.permissionDenied,
            ),
          ),
        );
      },
    );

    test(
      'concurrent multi-user voting does not overwrite each other and maps not-found to itemNotFound',
      () async {
        final map = await dataSource.createFoodMap(title: '投票測試');
        await dataSource.addRestaurant(mapId: map.id, restaurant: _Data.ramen);

        // User B joins
        currentUid = 'user-b';
        currentName = 'Bob';
        await dataSource.joinFoodMapByInviteCode(map.inviteCode);

        // User A upvotes
        currentUid = 'user-a';
        await dataSource.setVote(
          mapId: map.id,
          restaurantId: _Data.ramen.id!,
          vote: FoodMapVote.up,
        );

        // User B downvotes
        currentUid = 'user-b';
        await dataSource.setVote(
          mapId: map.id,
          restaurantId: _Data.ramen.id!,
          vote: FoodMapVote.down,
        );

        var detail = await dataSource.fetchFoodMapDetail(map.id);
        expect(detail.items.first.upvoteCount, 1);
        expect(detail.items.first.downvoteCount, 1);
        expect(detail.items.first.voteOf('user-a'), FoodMapVote.up);
        expect(detail.items.first.voteOf('user-b'), FoodMapVote.down);

        // User A clears vote; User B vote remains untouched
        currentUid = 'user-a';
        await dataSource.setVote(
          mapId: map.id,
          restaurantId: _Data.ramen.id!,
          vote: FoodMapVote.none,
        );
        detail = await dataSource.fetchFoodMapDetail(map.id);
        expect(detail.items.first.upvoteCount, 0);
        expect(detail.items.first.downvoteCount, 1);
        expect(detail.items.first.voteOf('user-b'), FoodMapVote.down);

        await expectLater(
          dataSource.setVote(
            mapId: map.id,
            restaurantId: 'missing-item',
            vote: FoodMapVote.up,
          ),
          throwsA(
            isA<FoodMapException>().having(
              (e) => e.code,
              'code',
              FoodMapErrorCode.itemNotFound,
            ),
          ),
        );
      },
    );

    test('enforces owner/adder permissions and blocks departed adder', () async {
      final map = await dataSource.createFoodMap(title: '權限驗證');
      await dataSource.addRestaurant(mapId: map.id, restaurant: _Data.ramen);

      // User B joins and adds sushi
      currentUid = 'user-b';
      currentName = 'Bob';
      await dataSource.joinFoodMapByInviteCode(map.inviteCode);
      await dataSource.addRestaurant(mapId: map.id, restaurant: _Data.sushi);

      // User B cannot edit/remove User A's ramen
      await expectLater(
        dataSource.updateItemNote(
          mapId: map.id,
          restaurantId: _Data.ramen.id!,
          note: 'hack',
        ),
        throwsA(
          isA<FoodMapException>().having(
            (e) => e.code,
            'code',
            FoodMapErrorCode.permissionDenied,
          ),
        ),
      );
      await expectLater(
        dataSource.removeRestaurant(
          mapId: map.id,
          restaurantId: _Data.ramen.id!,
        ),
        throwsA(
          isA<FoodMapException>().having(
            (e) => e.code,
            'code',
            FoodMapErrorCode.permissionDenied,
          ),
        ),
      );

      // User B can edit own sushi note
      final updated = await dataSource.updateItemNote(
        mapId: map.id,
        restaurantId: _Data.sushi.id!,
        note: '預約制',
      );
      expect(updated.note, '預約制');

      // User B leaves map -> member_uids & member_names are cleaned; departed adder can NO LONGER edit/remove sushi
      await dataSource.leaveFoodMap(map.id);
      final afterLeaveSnap = await fakeFirestore
          .collection(FoodMapDataSource.mapsCollectionName)
          .doc(map.id)
          .get();
      expect(afterLeaveSnap.data()?['member_uids'], ['user-a']);
      expect(
        (afterLeaveSnap.data()?['member_names'] as Map?)?.containsKey('user-b'),
        isFalse,
      );
      await expectLater(
        dataSource.updateItemNote(
          mapId: map.id,
          restaurantId: _Data.sushi.id!,
          note: 'after leave',
        ),
        throwsA(
          isA<FoodMapException>().having(
            (e) => e.code,
            'code',
            FoodMapErrorCode.permissionDenied,
          ),
        ),
      );
      await expectLater(
        dataSource.removeRestaurant(
          mapId: map.id,
          restaurantId: _Data.sushi.id!,
        ),
        throwsA(
          isA<FoodMapException>().having(
            (e) => e.code,
            'code',
            FoodMapErrorCode.permissionDenied,
          ),
        ),
      );

      // Owner CAN edit and remove User B's sushi
      currentUid = 'user-a';
      currentName = 'Alice';
      final ownerEdit = await dataSource.updateItemNote(
        mapId: map.id,
        restaurantId: _Data.sushi.id!,
        note: '建立者更新',
      );
      expect(ownerEdit.note, '建立者更新');

      await dataSource.removeRestaurant(
        mapId: map.id,
        restaurantId: _Data.sushi.id!,
      );
      final detail = await dataSource.fetchFoodMapDetail(map.id);
      expect(detail.map.itemCount, 1);
      expect(detail.items.map((e) => e.restaurantId), [_Data.ramen.id]);

      // Updating non-existent item throws itemNotFound
      await expectLater(
        dataSource.updateItemNote(
          mapId: map.id,
          restaurantId: 'missing-id',
          note: 'hi',
        ),
        throwsA(
          isA<FoodMapException>().having(
            (e) => e.code,
            'code',
            FoodMapErrorCode.itemNotFound,
          ),
        ),
      );
    });
  });

  group('deleteFoodMap, leaveFoodMap, and malformed doc tolerance', () {
    test(
      'owner deletes map with >500 items and missing invite doc cleanly',
      () async {
        final map = await dataSource.createFoodMap(title: '大清單刪除');
        final itemsCol = fakeFirestore
            .collection(FoodMapDataSource.mapsCollectionName)
            .doc(map.id)
            .collection(FoodMapDataSource.itemsSubcollectionName);

        // Seed 502 items to verify strict 500-op WriteBatch chunking + separate final batch
        for (int i = 0; i < 502; i++) {
          await itemsCol.doc('r-$i').set({
            'restaurant': {'id': 'r-$i', 'name': 'Shop $i'},
            'added_by_uid': 'user-a',
            'added_by_name': 'Alice',
            'note': '',
            'added_at_ms': i,
            'votes': <String, int>{},
          });
        }

        // Remove invite doc beforehand to ensure deletion does not fail when invite is missing
        await fakeFirestore
            .collection(FoodMapDataSource.invitesCollectionName)
            .doc(map.inviteCode)
            .delete();

        await dataSource.deleteFoodMap(map.id);

        final mapDoc = await fakeFirestore
            .collection(FoodMapDataSource.mapsCollectionName)
            .doc(map.id)
            .get();
        expect(mapDoc.exists, isFalse);

        final remainingItems = await itemsCol.get();
        expect(remainingItems.docs, isEmpty);
      },
    );

    test(
      'owner deletes map removing existing invite index and throws mapNotFound if missing',
      () async {
        final map = await dataSource.createFoodMap(title: '正常刪除');
        await dataSource.addRestaurant(mapId: map.id, restaurant: _Data.ramen);

        await dataSource.deleteFoodMap(map.id);

        final mapSnap = await fakeFirestore
            .collection(FoodMapDataSource.mapsCollectionName)
            .doc(map.id)
            .get();
        final inviteSnap = await fakeFirestore
            .collection(FoodMapDataSource.invitesCollectionName)
            .doc(map.inviteCode)
            .get();
        expect(mapSnap.exists, isFalse);
        expect(inviteSnap.exists, isFalse);

        await expectLater(
          dataSource.deleteFoodMap('missing-map-id'),
          throwsA(
            isA<FoodMapException>().having(
              (e) => e.code,
              'code',
              FoodMapErrorCode.mapNotFound,
            ),
          ),
        );
      },
    );

    test(
      'owner cannot leave own map and non-owner cannot delete map',
      () async {
        final map = await dataSource.createFoodMap(title: '建立者地圖');

        await expectLater(
          dataSource.leaveFoodMap(map.id),
          throwsA(
            isA<FoodMapException>().having(
              (e) => e.code,
              'code',
              FoodMapErrorCode.permissionDenied,
            ),
          ),
        );

        currentUid = 'user-b';
        currentName = 'Bob';
        await dataSource.joinFoodMapByInviteCode(map.inviteCode);

        await expectLater(
          dataSource.deleteFoodMap(map.id),
          throwsA(
            isA<FoodMapException>().having(
              (e) => e.code,
              'code',
              FoodMapErrorCode.permissionDenied,
            ),
          ),
        );
      },
    );

    test('skips malformed food_map and item documents gracefully', () async {
      final map = await dataSource.createFoodMap(title: '正常地圖');
      await dataSource.addRestaurant(mapId: map.id, restaurant: _Data.ramen);

      // Seed malformed map doc (updated_at_ms wrong type) & malformed item doc (missing restaurant)
      await fakeFirestore
          .collection(FoodMapDataSource.mapsCollectionName)
          .doc('bad-map')
          .set({
            'title': 12345,
            'member_uids': ['user-a'],
            'updated_at_ms': Timestamp.now(),
          });
      await fakeFirestore
          .collection(FoodMapDataSource.mapsCollectionName)
          .doc(map.id)
          .collection(FoodMapDataSource.itemsSubcollectionName)
          .doc('bad-item')
          .set({'added_by_uid': 'user-a', 'note': 'corrupted'});

      final maps = await dataSource.fetchMyFoodMaps();
      expect(maps.map((m) => m.id), [map.id]);

      final detail = await dataSource.fetchFoodMapDetail(map.id);
      expect(detail.items.map((i) => i.restaurantId), [_Data.ramen.id]);
    });
  });
}
