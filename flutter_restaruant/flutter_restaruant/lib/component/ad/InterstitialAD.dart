import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'InterstitialADState.dart';

class IntersitialAD {

  final InterstitialADState adState;

  const IntersitialAD({required this.adState});

  void load() => InterstitialAd.load(
      adUnitId: adState.interstitialAdUnitId!,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            // Keep a reference to the ad so you can show it later.
            ad.fullScreenContentCallback = this.adState.adListener;

            ad.show();
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('InterstitialAd failed to load: $error');
          }
      ));
}