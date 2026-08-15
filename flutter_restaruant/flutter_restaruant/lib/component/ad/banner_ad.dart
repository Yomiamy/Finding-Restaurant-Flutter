import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'banner_ad_state.dart';

class BannerAD extends StatefulWidget {
  final BannerADState adState;

  const BannerAD({super.key, required this.adState});

  @override
  State<BannerAD> createState() => _BannerADState();
}

class _BannerADState extends State<BannerAD> {
  BannerAd? banner;

  AnchoredAdaptiveBannerAdSize? size;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    widget.adState.initialization.then((value) async {
      if (!mounted) return;
      final adSize = await anchoredAdaptiveBannerAdSize(context);
      if (!mounted) return;
      // The SDK returns null when it cannot work out a size (e.g. no screen
      // metrics yet); without a size there is no ad to build.
      if (adSize == null || widget.adState.bannerAdUnitId == null) return;
      setState(() {
        size = adSize;
        banner = BannerAd(
          listener: widget.adState.adListener,
          adUnitId: widget.adState.bannerAdUnitId!,
          request: const AdRequest(),
          size: adSize,
        )..load();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final loadedBanner = banner;
    final loadedSize = size;
    // Both stay null until an ad size resolves and the banner is built.
    if (loadedBanner == null || loadedSize == null) {
      return const SizedBox();
    }

    return Container(
      color: Colors.grey,
      width: loadedSize.width.toDouble(),
      height: loadedSize.height.toDouble(),
      child: AdWidget(ad: loadedBanner),
    );
  }

  Future<AnchoredAdaptiveBannerAdSize?> anchoredAdaptiveBannerAdSize(
    BuildContext context,
  ) async {
    return await AdSize.getLargeAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).size.width.toInt(),
    );
  }
}
