import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app_open_ad_state.dart';

class AppOpenAD {
  final AppOpenADState adState;

  const AppOpenAD({required this.adState});

  /// Load an AppOpenAd.
  void loadAd() {
    AppOpenAd.load(
      adUnitId: adState.adUnitId,
      // orientation: AppOpenAd.orientationPortrait,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          // adState.appOpenAd = ad;
          adState.appOpenAd = this;
          ad.fullScreenContentCallback = adState.adListener;

          ad.show();
        },
        onAdFailedToLoad: (error) {
          // Handle the error.
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }
}
