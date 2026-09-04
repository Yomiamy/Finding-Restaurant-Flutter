import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../features/foundation/constants/constants_barrel.dart';

class BannerADState {
  Future<InitializationStatus> initialization;
  BannerADState(this.initialization);

  String? get bannerAdUnitId => Platform.isAndroid
      ? Constants.adAndroidBannerId
      : Constants.adIosBannerId;

  BannerAdListener createAdListener({
    void Function(Ad ad)? onAdLoaded,
    void Function(Ad ad, LoadAdError error)? onAdFailedToLoad,
  }) {
    return BannerAdListener(
      onAdLoaded: (ad) {
        debugPrint('Ad loaded.');
        onAdLoaded?.call(ad);
      },
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
        debugPrint('Ad failed to load: $error');
        onAdFailedToLoad?.call(ad, error);
      },
      onAdOpened: (ad) => debugPrint('Ad opened.'),
      onAdClosed: (ad) => debugPrint('Ad closed.'),
      onAdImpression: (ad) => debugPrint('Ad impression.'),
      onAdClicked: (ad) => debugPrint('Ad clicked.'),
      onPaidEvent: (ad, valueMicros, precision, currencyCode) => debugPrint(
        'Paid event : ${ad.adUnitId}, $valueMicros, $precision, $currencyCode.',
      ),
    );
  }

  AdManagerBannerAdListener get adListener => _adListener;

  final AdManagerBannerAdListener _adListener = AdManagerBannerAdListener(
    // Called when an ad is successfully received.
    onAdLoaded: (Ad ad) => debugPrint('Ad loaded.'),
    // Called when an ad request failed.
    onAdFailedToLoad: (Ad ad, LoadAdError error) {
      // Dispose the ad here to free resources.
      ad.dispose();
      debugPrint('Ad failed to load: $error');
    },
    // Called when an ad opens an overlay that covers the screen.
    onAdOpened: (Ad ad) => debugPrint('Ad opened.'),
    // Called when an ad removes an overlay that covers the screen.
    onAdClosed: (Ad ad) => debugPrint('Ad closed.'),
    // Called when an impression occurs on the ad.
    onAdImpression: (Ad ad) => debugPrint('Ad impression.'),
    onAppEvent: (ad, name, data) =>
        debugPrint('App event : ${ad.adUnitId}, $name, $data.'),
  );
}
