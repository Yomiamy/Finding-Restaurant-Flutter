class AdCounterManager {
  static final AdCounterManager _singleton = AdCounterManager._internal();

  AdCounterManager._internal();

  factory AdCounterManager() => _singleton;

  int _interstitialAdCountDown = 3;

  int get interstitialAdCountDown => _interstitialAdCountDown;

  /// Decrements the interstitial AD counter.
  /// Returns true if an interstitial AD should be loaded/shown.
  bool decrementAndCheckShouldShowAd() {
    _interstitialAdCountDown--;
    if (_interstitialAdCountDown <= 0) {
      _interstitialAdCountDown = 3;
      return true;
    }
    return false;
  }

  void reset() {
    _interstitialAdCountDown = 3;
  }
}
