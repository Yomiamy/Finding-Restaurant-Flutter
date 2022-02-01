import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'AppOpenAD.dart';

class AppLifecycleReactor {
  final AppOpenAD appOpenAd;

  AppLifecycleReactor({required this.appOpenAd});

  void listenToAppStateChanges() {
    AppStateEventNotifier.startListening();
    AppStateEventNotifier.appStateStream
        .forEach((state) => _onAppStateChanged(state));
  }

  void _onAppStateChanged(AppState appState) {
    // Try to show an app open ad if the app is being resumed and
    // we're not already showing an app open ad.
    if (appState != AppState.foreground) {
      return;
    }
    appOpenAd.loadAd();
  }
}