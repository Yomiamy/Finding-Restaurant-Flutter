import 'package:flutter/services.dart';
import 'package:flutter_restaruant/data_layer/datasources/favor_data_source.dart';
import 'package:flutter_restaruant/data_layer/dto/account_dto.dart';
import 'package:flutter_restaruant/domain/entities/restaurant_entity.dart';
import 'package:flutter_restaruant/domain/entities/user_entity.dart';
import 'package:flutter_restaruant/manager/sign_in_manager.dart';
import 'package:flutter_restaruant/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Data {
  static const Map<String, Object> guestPrefs = {'guest_mode': true};
  static const Map<String, Object> emptyPrefs = {};

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
    const MethodChannel channel = MethodChannel('plugins.flutter.io/local_auth');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getAvailableBiometrics') {
        return <String>[];
      }
      return null;
    });
  });

  // SignInManager 是 singleton，每個測試都需重置，避免狀態互相污染。
  Future<void> resetManager(Map<String, Object> initialPrefs) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    SignInManager().accountDto = null;
    await SignInManager().clearGuestFlag();
    SharedPreferences.setMockInitialValues(initialPrefs);
  }

  group('Guest mode flag', () {
    test('markAsGuest sets isGuest and persists the flag', () async {
      await resetManager(_Data.emptyPrefs);

      await SignInManager().markAsGuest();

      expect(SignInManager().isGuest, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(Constants.prefKeyGuestMode), isTrue);
    });

    test('loadGuestFlag restores the flag on app restart', () async {
      await resetManager(_Data.guestPrefs);

      await SignInManager().loadGuestFlag();

      expect(SignInManager().isGuest, isTrue);
    });

    test('loadGuestFlag defaults to false on a fresh install', () async {
      await resetManager(_Data.emptyPrefs);

      await SignInManager().loadGuestFlag();

      expect(SignInManager().isGuest, isFalse);
    });

    test('clearGuestFlag removes both memory and stored flag', () async {
      await resetManager(_Data.guestPrefs);
      await SignInManager().loadGuestFlag();
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
    // 迴歸測試：訪客載入主列表時會呼叫 fetchFavorsMap()。少了空 uid 的
    // guard，Firestore 會拋 ArgumentError（繼承 Error 而非 Exception），
    // MainBloc 的 `on Exception` 接不住，畫面會卡在 loading。
    test('fetchFavorsMap returns empty without touching Firestore', () async {
      await resetManager(_Data.emptyPrefs);
      await SignInManager().markAsGuest();

      // 未初始化 Firebase：若 guard 失效，這裡會拋錯而非回傳空 map。
      expect(await FavorDataSource().fetchFavorsMap(), isEmpty);
    });

    test('fetchFavorEntities returns empty for a guest', () async {
      await resetManager(_Data.emptyPrefs);
      await SignInManager().markAsGuest();

      expect(await FavorDataSource().fetchFavorEntities(), isEmpty);
    });

    // 寫入路徑必須在 release build 也擋得住，因此用 throw 而非 assert。
    // 這個測試在 debug 與 release 下都成立。
    test('toggleFavor throws instead of writing to an empty doc id', () async {
      await resetManager(_Data.emptyPrefs);
      await SignInManager().markAsGuest();

      expect(
          () => FavorDataSource()
              .toggleFavor(const RestaurantEntity(id: 'any-id')),
          throwsStateError);
    });
  });
}
