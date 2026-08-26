import 'dart:convert';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_restaruant/data_layer/datasources/datasources_barrel.dart';
import 'package:flutter_restaruant/data_layer/dto/dto_barrel.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/manager/manager_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;
  late FavorDataSource favorDataSource;

  setUpAll(() {
    const MethodChannel channel = MethodChannel(
      'plugins.flutter.io/local_auth',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getAvailableBiometrics') {
            return <String>[];
          }
          return null;
        });
  });

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    favorDataSource = FavorDataSource(firestore: fakeFirestore);
  });

  test(
    'FavorDataSource migration maintains correct UID boundary when account changes',
    () async {
      final legacyDataA = {
        'restaurant1': jsonEncode({'id': 'restaurant1', 'name': 'A'}),
        'restaurant2': jsonEncode({'id': 'restaurant2', 'name': 'B'}),
      };
      await fakeFirestore.collection('favors').doc('user_A').set(legacyDataA);

      SignInManager().accountDto = AccountDto(
        type: AccountType.mail,
        uid: 'user_A',
      );

      final future = favorDataSource.fetchFavorIds();
      SignInManager().accountDto = AccountDto(
        type: AccountType.mail,
        uid: 'user_B',
      );
      await future;

      final docA = await fakeFirestore.collection('favors').doc('user_A').get();
      expect(docA.data()?['_migratedAt'], isNotNull);

      final itemsA = await fakeFirestore
          .collection('favors')
          .doc('user_A')
          .collection('items')
          .get();
      expect(itemsA.docs.length, 2);

      final docB = await fakeFirestore.collection('favors').doc('user_B').get();
      expect(docB.exists, false);

      final itemsB = await fakeFirestore
          .collection('favors')
          .doc('user_B')
          .collection('items')
          .get();
      expect(itemsB.docs.length, 0);
    },
  );
}
