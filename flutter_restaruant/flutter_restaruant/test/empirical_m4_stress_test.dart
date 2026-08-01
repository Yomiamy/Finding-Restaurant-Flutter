import 'package:flutter_restaruant/manager/ad_counter_manager.dart';
import 'package:flutter_restaruant/features/foundation/constants/app_constants.dart';
import 'package:flutter_restaruant/features/foundation/style/style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Empirical Stress Tests - Milestone 4 Constants & AdCounterManager',
      () {
    late AdCounterManager manager;

    setUp(() {
      manager = AdCounterManager();
      manager.reset();
    });

    test('1. AdCounterManager singleton identity check', () {
      final manager1 = AdCounterManager();
      final manager2 = AdCounterManager();
      expect(identical(manager1, manager2), isTrue);
    });

    test(
        '2. AdCounterManager 100-cycle stress test decrement and trigger frequency',
        () {
      int adTriggerCount = 0;
      for (int i = 1; i <= 99; i++) {
        final shouldShow = manager.decrementAndCheckShouldShowAd();
        if (shouldShow) {
          adTriggerCount++;
          // Counter must reset to 3 upon trigger
          expect(manager.interstitialAdCountDown, equals(3));
        } else {
          // Counter must be 2 or 1
          expect(manager.interstitialAdCountDown, isIn([1, 2]));
        }
      }
      // Out of 99 calls, ad should trigger exactly 99 / 3 = 33 times
      expect(adTriggerCount, equals(33));
      // End state should be count down 3
      expect(manager.interstitialAdCountDown, equals(3));
    });

    test('3. AdCounterManager reset mid-cycle behavior', () {
      // Step 1: 3 -> 2
      expect(manager.decrementAndCheckShouldShowAd(), isFalse);
      expect(manager.interstitialAdCountDown, equals(2));

      // Reset
      manager.reset();
      expect(manager.interstitialAdCountDown, equals(3));

      // Step 1 again: 3 -> 2
      expect(manager.decrementAndCheckShouldShowAd(), isFalse);
      expect(manager.interstitialAdCountDown, equals(2));

      // Step 2: 2 -> 1
      expect(manager.decrementAndCheckShouldShowAd(), isFalse);
      expect(manager.interstitialAdCountDown, equals(1));

      // Reset again
      manager.reset();
      expect(manager.interstitialAdCountDown, equals(3));
    });

    test(
        '4. Constants & UIConstants runtime integrity and camelCase verification',
        () {
      // Verify Constants values
      expect(Constants.baseUrl, equals('https://api.yelp.com'));
      expect(Constants.connectionTimeout, equals(30000));
      expect(Constants.receiveTimeout, equals(30000));
      expect(Constants.pageItemCount, equals(50));
      expect(Constants.locale, equals('zh_TW'));

      // Verify UIConstants values
      expect(UIConstants.appTitle, equals('尋找餐廳'));
      expect(UIConstants.loginTitle, equals('登入'));
      expect(UIConstants.favorTitle, equals('我喜好的店家'));
      expect(Sizes.ratingImageW, equals(100.0));
      expect(Sizes.ratingImageH, equals(20.0));
    });
  });
}
