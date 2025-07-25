import 'package:flutter_restaruant/utils/Constants.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class BannerADState {
  Future<InitializationStatus> initialization;
  BannerADState(this.initialization);

  String? get bannerAdUnitId => Platform.isAndroid
      ? Constants.AD_ANDROID_BANNER_ID
      : Constants.AD_IOS_BANNER_ID;

  AdManagerBannerAdListener get adListener => _adListener;

  AdManagerBannerAdListener _adListener = AdManagerBannerAdListener(
    // Called when an ad is successfully received.
    onAdLoaded: (Ad ad) => print('Ad loaded.'),
    // Called when an ad request failed.
    onAdFailedToLoad: (Ad ad, LoadAdError error) {
      // Dispose the ad here to free resources.
      ad.dispose();
      print('Ad failed to load: $error');
    },
    // Called when an ad opens an overlay that covers the screen.
    onAdOpened: (Ad ad) => print('Ad opened.'),
    // Called when an ad removes an overlay that covers the screen.
    onAdClosed: (Ad ad) => print('Ad closed.'),
    // Called when an impression occurs on the ad.
    onAdImpression: (Ad ad) => print('Ad impression.'),
    onAppEvent: (ad, name, data) =>
        print('App event : ${ad.adUnitId}, $name, $data.'),
  );
}
