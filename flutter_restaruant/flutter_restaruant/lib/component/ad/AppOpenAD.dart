import 'AppOpenAdState.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppOpenAD {

  final AppOpenADState adState;

  const AppOpenAD({required this.adState});

  /// Load an AppOpenAd.
  void loadAd() {
    AppOpenAd.load(
        adUnitId: adState.adUnitId,
        orientation: AppOpenAd.orientationPortrait,
        request: AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
            onAdLoaded: (ad) {
              // adState.appOpenAd = ad;
              this.adState.appOpenAd = this;
              ad.fullScreenContentCallback = this.adState.adListener;

              ad.show();
            },
            onAdFailedToLoad: (error) {
              // Handle the error.
              print('AppOpenAd failed to load: $error');
            }
        )
    );
  }
}