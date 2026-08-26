import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_restaruant/data_layer/datasources/datasources_barrel.dart';
import 'package:flutter_restaruant/data_layer/dto/dto_barrel.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/manager/manager_barrel.dart';
import 'package:flutter_restaruant/features/foundation/constants/constants_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Data {
  static const Map<String, Object> guestPrefs = {'guest_mode': true};
  static const Map<String, Object> emptyPrefs = {};

  /// 含巢狀 categories / location / coordinates 的最小樣本，
  /// 用來驗證寫入 Firestore 的 payload 已深層攤平。
  static const String summaryJson = r'''
  {
    "id": "test-id",
    "name": "測試餐廳",
    "image_url": "https://example.com/a.png",
    "review_count": 10,
    "rating": 4.5,
    "price": "$$",
    "phone": "0912345678",
    "distance": 123.4,
    "categories": [{"alias": "ramen", "title": "拉麵"}],
    "location": {"address1": "中山路 1 號", "city": "台北"},
    "coordinates": {"latitude": 25.048036, "longitude": 121.517063}
  }
  ''';

  static AccountDto get signedInAccount =>
      AccountDto(uid: 'test-uid', type: AccountType.mail);
}

/// 涵蓋範圍說明
///
/// 本檔測試訪客旗標的讀寫、互斥與空 uid 的資料層 guard。
///
/// **未涵蓋**：`signIn()` / `signUp()` / `signOut()` 內的旗標清除點。三者都會
/// 觸及 `FirebaseAuth.instance`，在測試環境會同步拋出 `[core/no-app]`，無法在
/// 不 mock 六個 platform channel 的前提下驅動。AC-6 與 AC-7 由 Issue #55 的
/// 手動驗證步驟 5、6 涵蓋。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // 建構 SignInManager 會連帶建立 BiometricSignInManager，後者在
    // 建構式中就呼叫 local_auth 的 platform channel。測試環境沒有原生
    // 實作，需先掛上 mock handler，否則會噴 MissingPluginException。
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

  // SignInManager 是 singleton，每個測試都需重置，避免狀態互相污染。
  // 重設 mock prefs 後重新 loadPrefs()，讓 manager 取得新的 instance。
  Future<void> resetManager(Map<String, Object> initialPrefs) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    SignInManager().accountDto = null;
    await SignInManager().loadPrefs();
  }

  group('Guest mode flag', () {
    test('markAsGuest sets isGuest and persists the flag', () async {
      await resetManager(_Data.emptyPrefs);

      await SignInManager().markAsGuest();

      expect(SignInManager().isGuest, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(Constants.prefKeyGuestMode), isTrue);
    });

    test('a stored flag survives an app restart', () async {
      await resetManager(_Data.guestPrefs);

      expect(SignInManager().isGuest, isTrue);
    });

    test('isGuest is false on a fresh install', () async {
      await resetManager(_Data.emptyPrefs);

      expect(SignInManager().isGuest, isFalse);
    });

    test('clearGuestFlag removes the stored flag', () async {
      await resetManager(_Data.guestPrefs);
      expect(SignInManager().isGuest, isTrue);

      await SignInManager().clearGuestFlag();

      expect(SignInManager().isGuest, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(Constants.prefKeyGuestMode), isFalse);
    });

    test('isGuest is false once an account is present', () async {
      await resetManager(_Data.emptyPrefs);
      await SignInManager().markAsGuest();

      SignInManager().accountDto = _Data.signedInAccount;

      // 互斥性由 getter 的資料結構保證，不依賴呼叫端記得先清旗標。
      expect(SignInManager().isGuest, isFalse);
    });
  });

  group('Favor data source without a signed-in user', () {
    // 迴歸測試：訪客載入主列表時會呼叫 fetchFavorIds()。少了空 uid 的
    // guard，Firestore 會拋 ArgumentError（繼承 Error 而非 Exception），
    // MainBloc 的 `on Exception` 接不住，畫面會卡在 loading。
    test('fetchFavorIds returns empty without touching Firestore', () async {
      await resetManager(_Data.emptyPrefs);
      await SignInManager().markAsGuest();

      // 未初始化 Firebase：若 guard 失效，這裡會拋錯而非回傳空集合。
      expect(await FavorDataSource().fetchFavorIds(), isEmpty);
    });

    test('fetchFavorEntities returns empty for a guest', () async {
      await resetManager(_Data.emptyPrefs);
      await SignInManager().markAsGuest();

      expect(await FavorDataSource().fetchFavorEntities(), isEmpty);
    });

    // 寫入路徑必須在 release build 也擋得住，因此用 throw 而非 assert。
    // 這個測試在 debug 與 release 下都成立。
    //
    // 同時守住 AC-2 的一半：guard 必須是 toggleFavor 的第一件事。舊實作先
    // 呼叫 fetchFavorsMap() 再 guard，路徑上多一次全量讀取；若日後有人把
    // 任何讀取搬回 guard 之前，未初始化的 Firebase 會先拋 [core/no-app]，
    // 這個斷言就會失敗。已登入路徑無法在此環境驗證（需 fake_cloud_firestore
    // 新依賴），該半由 code review 把關。
    test('toggleFavor throws instead of writing to an empty doc id', () async {
      await resetManager(_Data.emptyPrefs);
      await SignInManager().markAsGuest();

      expect(
        () =>
            FavorDataSource().toggleFavor(const RestaurantEntity(id: 'any-id')),
        throwsStateError,
      );
    });
  });

  group('Favor item payload', () {
    // 迴歸測試：Firestore 只收純量／List／Map，遇到 DTO 物件會拋
    // ArgumentError（繼承 Error 而非 Exception，bloc 的 on Exception
    // 接不住）。toggleFavor 直接把 toDto.toJson() 寫進 Firestore，
    // 所以 toJson() 必須遞迴展開巢狀的 categories/location/coordinates
    // ——那正是 YelpRestaurantSummaryDto 上 explicitToJson 的作用。
    // 若有人拿掉那個 flag，產生碼會退回淺層 map，這個測試就會紅。
    //
    // 不需要 Firebase 也不需要 fake_cloud_firestore：用 Flutter 內建的
    // StandardMessageCodec 驗證，等價於 Firestore platform channel 的型別檢查。
    test('toggleFavor 寫入的 payload 可被 Firestore 的 codec 編碼', () {
      final RestaurantEntity entity = RestaurantEntity.fromDto(
        YelpRestaurantSummaryDto.fromJson(
          jsonDecode(_Data.summaryJson) as Map<String, dynamic>,
        ),
      );

      // 與 toggleFavor 寫入 Firestore 的是同一個運算式。
      final Map<String, dynamic> payload = entity.toDto.toJson();

      // 巢狀結構必須是 Map/List 而非 DTO 物件。
      expect(payload['categories'], isA<List<dynamic>>());
      expect(
        (payload['categories'] as List).first,
        isA<Map<String, dynamic>>(),
      );
      expect(payload['location'], isA<Map<String, dynamic>>());
      expect(payload['coordinates'], isA<Map<String, dynamic>>());

      // 真正的守門：未展開的 payload 會在這裡拋 ArgumentError。
      expect(
        () => const StandardMessageCodec().encodeMessage(payload),
        returnsNormally,
      );
    });
  });
}
