import 'package:flutter/foundation.dart';
import '../../utils/constants.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class InterstitialADState {
  String? get interstitialAdUnitId => Platform.isAndroid
      ? Constants.adAndroidInterstitialId
      : Constants.adIosInterstitialId;

  var adListener = FullScreenContentCallback(
    onAdShowedFullScreenContent: (InterstitialAd ad) =>
        debugPrint('%ad onAdShowedFullScreenContent.'),
    onAdDismissedFullScreenContent: (InterstitialAd ad) {
      debugPrint('$ad onAdDismissedFullScreenContent.');
      ad.dispose();
    },
    onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
      debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
      ad.dispose();
    },
    onAdImpression: (InterstitialAd ad) => debugPrint('$ad impression occurred.'),
  );
}
