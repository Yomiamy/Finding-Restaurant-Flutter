import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'BannerADState.dart';

class BannerAD extends StatefulWidget {
  final BannerADState adState;

  const BannerAD({Key? key, required this.adState}) : super(key: key);

  @override
  _BannerADState createState() => _BannerADState();
}

class _BannerADState extends State<BannerAD> {
  BannerAd? banner;

  AnchoredAdaptiveBannerAdSize? size;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    widget.adState.initialization.then((value) async {
      size = await anchoredAdaptiveBannerAdSize(context);
      setState(() {
        if (widget.adState.bannerAdUnitId != null) {
          banner = BannerAd(
            listener: widget.adState.adListener,
            adUnitId: widget.adState.bannerAdUnitId!,
            request: AdRequest(),
            size: size!,
          )..load();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return banner ==
            null //banner is only null for a very less time //don't think that banner will be null if ads fails loads
        ? SizedBox()
        : Container(
            color: Colors.grey,
            width: size!.width.toDouble(),
            height: size!.height.toDouble(),
            child: AdWidget(
              ad: banner!,
            ),
          );
  }

  Future<AnchoredAdaptiveBannerAdSize?> anchoredAdaptiveBannerAdSize(
      BuildContext context) async {
    return await AdSize.getAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).orientation == Orientation.portrait
          ? Orientation.portrait
          : Orientation.landscape,
      MediaQuery.of(context).size.width.toInt(),
    );
  }
}
