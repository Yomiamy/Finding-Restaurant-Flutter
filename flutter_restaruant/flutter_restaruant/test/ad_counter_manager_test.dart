import 'package:flutter_restaruant/manager/ad_counter_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdCounterManager Tests', () {
    late AdCounterManager manager;

    setUp(() {
      manager = AdCounterManager();
      manager.reset();
    });

    test('Initial countdown value is 3', () {
      expect(manager.interstitialAdCountDown, equals(3));
    });

    test('Decrement behavior and triggers ad on 3rd call', () {
      // Call 1: 3 -> 2, should NOT show ad
      expect(manager.decrementAndCheckShouldShowAd(), isFalse);
      expect(manager.interstitialAdCountDown, equals(2));

      // Call 2: 2 -> 1, should NOT show ad
      expect(manager.decrementAndCheckShouldShowAd(), isFalse);
      expect(manager.interstitialAdCountDown, equals(1));

      // Call 3: 1 -> 0 -> resets to 3, SHOULD show ad
      expect(manager.decrementAndCheckShouldShowAd(), isTrue);
      expect(manager.interstitialAdCountDown, equals(3));
    });

    test('Reset restores countdown to 3', () {
      manager.decrementAndCheckShouldShowAd(); // down to 2
      expect(manager.interstitialAdCountDown, equals(2));

      manager.reset();
      expect(manager.interstitialAdCountDown, equals(3));
    });
  });
}
