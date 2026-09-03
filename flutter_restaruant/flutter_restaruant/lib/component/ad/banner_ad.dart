import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../features/foundation/style/style_barrel.dart';
import 'banner_ad_state.dart';

/// 底部常駐標準橫幅廣告元件 (Standard Banner AD, 320x50)。
///
/// 高度嚴格鎖定 50dp 以消滅版面突跳 (CLS)，並透過頂部邊界線區隔廣告與應用內容。
class BannerAD extends StatefulWidget {
  final BannerADState adState;

  const BannerAD({super.key, required this.adState});

  @override
  State<BannerAD> createState() => _BannerADState();
}

class _BannerADState extends State<BannerAD> {
  BannerAd? banner;
  static const AdSize adSize = AdSize.banner;
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

    final adUnitId = widget.adState.bannerAdUnitId;
    if (adUnitId == null) return;

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
    const height = ThemeSize.space50;

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
      child: banner != null
          ? SizedBox(
              width: adSize.width.toDouble(),
              height: height,
              child: AdWidget(ad: banner!),
            )
          : const SizedBox.shrink(),
    );
  }
}
