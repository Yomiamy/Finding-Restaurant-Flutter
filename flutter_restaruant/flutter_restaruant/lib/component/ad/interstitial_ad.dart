import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'interstitial_ad_state.dart';

class IntersitialAD {
  final InterstitialADState adState;

  const IntersitialAD({required this.adState});

  void load() => InterstitialAd.load(
      adUnitId: adState.interstitialAdUnitId!,
      request: const AdRequest(),
      adLoadCallback:
          InterstitialAdLoadCallback(onAdLoaded: (InterstitialAd ad) {
        // Keep a reference to the ad so you can show it later.
        ad.fullScreenContentCallback = adState.adListener;

        ad.show();
      }, onAdFailedToLoad: (LoadAdError error) {
        debugPrint('InterstitialAd failed to load: $error');
      }));
}
