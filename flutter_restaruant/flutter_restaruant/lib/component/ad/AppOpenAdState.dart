import 'dart:ffi';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'AppOpenAD.dart';

abstract class AppOpenADEvent {
  void onAdDismissed();
  void onAdFailedToShow();
}

class AppOpenADState {

  String adUnitId = Platform.isAndroid ? "ca-app-pub-7910179918263365/2058235863" : "ca-app-pub-7910179918263365/5774119595";
  bool isShowingAd = false;
  /// Whether an ad is available to be shown.
  AppOpenAD? appOpenAd;
  bool get isAdAvailable => appOpenAd != null;
  late FullScreenContentCallback<AppOpenAd> adListener;
  final AppOpenADEvent appOpenADEventListener;

   AppOpenADState({required this.appOpenADEventListener}) {
     this.adListener = FullScreenContentCallback (
       onAdShowedFullScreenContent: (ad){
         this.isShowingAd = true;
       },
       onAdFailedToShowFullScreenContent: (ad, error) async {
         this.isShowingAd = false;
         this.appOpenAd = null;

         ad.dispose();
         this.appOpenADEventListener.onAdFailedToShow();
       },
       onAdDismissedFullScreenContent: (ad) async {
         this.isShowingAd = false;
         this.appOpenAd = null;

         ad.dispose();
         this.appOpenADEventListener.onAdDismissed();
       }
     );
  }
}



