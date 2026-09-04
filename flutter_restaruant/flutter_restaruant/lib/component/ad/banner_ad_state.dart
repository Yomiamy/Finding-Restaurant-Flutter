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
}
