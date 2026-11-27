import 'dart:math';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_restaruant/data_layer/datasources/datasources_barrel.dart';
import 'package:flutter_restaruant/data_layer/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

void main() {
  test(
    'FoodMapRepo delegates end-to-end collaborative map lifecycle to FoodMapDataSource',
    () async {
      final firestore = FakeFirebaseFirestore();
      String uid = 'owner-1';
      String name = 'Alice';
      int clock = 1000;

      final repo = FoodMapRepo(
        dataSource: FoodMapDataSource(
          firestore: firestore,
          uidProvider: () => uid,
          displayNameProvider: () => name,
          nowMsProvider: () => clock += 10,
          random: Random(7),
          logger: Logger(level: Level.off),
        ),
      );

      expect(repo.currentUid, 'owner-1');

      final created = await repo.createFoodMap(
        title: 'Repo Test Map',
        description: 'Desc',
      );
      expect((await repo.fetchMyFoodMaps()).length, 1);

      const shop = RestaurantEntity(id: 'shop-1', name: 'Test Shop');
      final addRes = await repo.addRestaurant(
        mapId: created.id,
        restaurant: shop,
        note: 'Great!',
      );
      expect(addRes.added, isTrue);

      await repo.setVote(
        mapId: created.id,
        restaurantId: 'shop-1',
        vote: FoodMapVote.up,
      );
      final updatedItem = await repo.updateItemNote(
        mapId: created.id,
        restaurantId: 'shop-1',
        note: 'Updated note',
      );
      expect(updatedItem.note, 'Updated note');

      uid = 'member-2';
      name = 'Bob';
      final joined = await repo.joinFoodMapByInviteCode(created.inviteCode);
      expect(joined.alreadyMember, isFalse);

      final imported = await repo.importRestaurants(
        mapId: created.id,
        restaurants: const [
          shop,
          RestaurantEntity(id: 'shop-2', name: 'Second Shop'),
        ],
      );
      expect(imported.addedCount, 1);
      expect(imported.skippedCount, 1);

      await repo.leaveFoodMap(created.id);

      uid = 'owner-1';
      name = 'Alice';
      await repo.removeRestaurant(mapId: created.id, restaurantId: 'shop-2');
      final detail = await repo.fetchFoodMapDetail(created.id);
      expect(detail.items.map((e) => e.restaurantId), ['shop-1']);

      await repo.deleteFoodMap(created.id);
      expect(await repo.fetchMyFoodMaps(), isEmpty);
    },
  );
}
