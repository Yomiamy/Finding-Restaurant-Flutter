import 'package:flutter_restaruant/utils/Constants.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class InterstitialADState {
  String? get interstitialAdUnitId => Platform.isAndroid
      ? Constants.AD_ANDROID_INTERSTITAL_ID
      : Constants.AD_IOS_INTERSTITAL_ID;

  var adListener = FullScreenContentCallback(
    onAdShowedFullScreenContent: (InterstitialAd ad) =>
        print('%ad onAdShowedFullScreenContent.'),
    onAdDismissedFullScreenContent: (InterstitialAd ad) {
      print('$ad onAdDismissedFullScreenContent.');
      ad.dispose();
    },
    onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
      print('$ad onAdFailedToShowFullScreenContent: $error');
      ad.dispose();
    },
    onAdImpression: (InterstitialAd ad) => print('$ad impression occurred.'),
  );
}
