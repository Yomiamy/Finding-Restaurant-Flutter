import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app_open_ad.dart';

abstract class AppOpenADEvent {
  void onAdDismissed();
  void onAdFailedToShow();
}

class AppOpenADState {
  String adUnitId = Platform.isAndroid
      ? 'ca-app-pub-7910179918263365/2058235863'
      : 'ca-app-pub-7910179918263365/5774119595';
  bool isShowingAd = false;

  /// Whether an ad is available to be shown.
  AppOpenAD? appOpenAd;
  bool get isAdAvailable => appOpenAd != null;
  late FullScreenContentCallback<AppOpenAd> adListener;
  final AppOpenADEvent appOpenADEventListener;

  AppOpenADState({required this.appOpenADEventListener}) {
    adListener = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        isShowingAd = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) async {
        isShowingAd = false;
        appOpenAd = null;

        // ignore: unawaited_futures
        ad.dispose();
        appOpenADEventListener.onAdFailedToShow();
      },
      onAdDismissedFullScreenContent: (ad) async {
        isShowingAd = false;
        appOpenAd = null;

        // ignore: unawaited_futures
        ad.dispose();
        appOpenADEventListener.onAdDismissed();
      },
    );
  }
}
