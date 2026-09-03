import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../features/foundation/style/style_barrel.dart';
import 'banner_ad_state.dart';

/// 底部常駐橫幅廣告元件 (Anchored Banner AD)。
///
/// 預留固定高度佔位容器以消滅版面突跳 (CLS)，並透過頂部邊界線區隔廣告與應用內容。
class BannerAD extends StatefulWidget {
  final BannerADState adState;

  const BannerAD({super.key, required this.adState});

  @override
  State<BannerAD> createState() => _BannerADState();
}

class _BannerADState extends State<BannerAD> {
  BannerAd? banner;
  AnchoredAdaptiveBannerAdSize? size;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _loadBannerAd();
    }
  }

  Future<void> _loadBannerAd() async {
    await widget.adState.initialization;
    if (!mounted) return;

    final adSize = await anchoredAdaptiveBannerAdSize(context);
    if (!mounted) return;

    final adUnitId = widget.adState.bannerAdUnitId;
    if (adSize == null || adUnitId == null) return;

    final newBanner = BannerAd(
      listener: widget.adState.adListener,
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: adSize,
    );

    await newBanner.load();
    if (!mounted) {
      await newBanner.dispose();
      return;
    }

    setState(() {
      size = adSize;
      banner = newBanner;
    });
  }

  @override
  void dispose() {
    banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loadedBanner = banner;
    final loadedSize = size;
    final height = loadedSize?.height.toDouble() ?? ThemeSize.space50;

    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        color: ThemeColor.colorfffbf7,
        border: Border(
          top: BorderSide(
            color: ThemeColor.color9e9e9e,
            width: 0.5,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: loadedBanner != null && loadedSize != null
          ? SizedBox(
              width: loadedSize.width.toDouble(),
              height: height,
              child: AdWidget(ad: loadedBanner),
            )
          : const SizedBox.shrink(),
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
