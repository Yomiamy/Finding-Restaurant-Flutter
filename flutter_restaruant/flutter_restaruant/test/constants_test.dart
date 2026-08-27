import 'package:flutter_restaruant/features/foundation/constants/constants_barrel.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Constants & UIConstants Milestone 4 Verification Tests', () {
    test('Constants corrected typo fields and camelCase naming', () {
      expect(Constants.connectionTimeout, equals(30000));
      expect(Constants.receiveTimeout, equals(30000));
      expect(Constants.emailSubject, equals('subject'));
      expect(Constants.adAndroidInterstitialId, isNotEmpty);
      expect(Constants.adIosInterstitialId, isNotEmpty);
      expect(Constants.baseUrl, equals('https://api.yelp.com'));
      expect(
        Constants.fcmNotificationChannelId,
        equals('fcm_notification_channel_id'),
      );
    });

    test('UIConstants camelCase naming and immutability', () {
      expect(UIConstants.noImage, equals('images/empty.png'));
      expect(ThemeSize.size100, equals(100.0));
      expect(ThemeSize.size20, equals(20.0));
      expect(UIConstants.mapDefaultLocation.latitude, equals(25.048036));
      expect(UIConstants.mapDefaultLocation.longitude, equals(121.517063));
    });
  });
}
