// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/widgets.dart';

class $ImagesGen {
  const $ImagesGen();

  /// File path: images/Star_rating_0.5_of_5.png
  AssetGenImage get starRating05Of5 =>
      const AssetGenImage('images/Star_rating_0.5_of_5.png');

  /// File path: images/Star_rating_0_of_5.png
  AssetGenImage get starRating0Of5 =>
      const AssetGenImage('images/Star_rating_0_of_5.png');

  /// File path: images/Star_rating_1.5_of_5.png
  AssetGenImage get starRating15Of5 =>
      const AssetGenImage('images/Star_rating_1.5_of_5.png');

  /// File path: images/Star_rating_1_of_5.png
  AssetGenImage get starRating1Of5 =>
      const AssetGenImage('images/Star_rating_1_of_5.png');

  /// File path: images/Star_rating_2.5_of_5.png
  AssetGenImage get starRating25Of5 =>
      const AssetGenImage('images/Star_rating_2.5_of_5.png');

  /// File path: images/Star_rating_2_of_5.png
  AssetGenImage get starRating2Of5 =>
      const AssetGenImage('images/Star_rating_2_of_5.png');

  /// File path: images/Star_rating_3.5_of_5.png
  AssetGenImage get starRating35Of5 =>
      const AssetGenImage('images/Star_rating_3.5_of_5.png');

  /// File path: images/Star_rating_3_of_5.png
  AssetGenImage get starRating3Of5 =>
      const AssetGenImage('images/Star_rating_3_of_5.png');

  /// File path: images/Star_rating_4.5_of_5.png
  AssetGenImage get starRating45Of5 =>
      const AssetGenImage('images/Star_rating_4.5_of_5.png');

  /// File path: images/Star_rating_4_of_5.png
  AssetGenImage get starRating4Of5 =>
      const AssetGenImage('images/Star_rating_4_of_5.png');

  /// File path: images/Star_rating_5_of_5.png
  AssetGenImage get starRating5Of5 =>
      const AssetGenImage('images/Star_rating_5_of_5.png');

  /// File path: images/empty.png
  AssetGenImage get empty => const AssetGenImage('images/empty.png');

  /// File path: images/ic_favor_empty.png
  AssetGenImage get icFavorEmpty =>
      const AssetGenImage('images/ic_favor_empty.png');

  /// File path: images/ic_favor_fill.png
  AssetGenImage get icFavorFill =>
      const AssetGenImage('images/ic_favor_fill.png');

  /// File path: images/icon_setting_icon.gif
  AssetGenImage get iconSettingIcon =>
      const AssetGenImage('images/icon_setting_icon.gif');

  /// File path: images/icon_signinup_icon.gif
  AssetGenImage get iconSigninupIcon =>
      const AssetGenImage('images/icon_signinup_icon.gif');

  /// File path: images/launch_image.png
  AssetGenImage get launchImage =>
      const AssetGenImage('images/launch_image.png');

  /// List of all assets
  List<AssetGenImage> get values => [
        starRating05Of5,
        starRating0Of5,
        starRating15Of5,
        starRating1Of5,
        starRating25Of5,
        starRating2Of5,
        starRating35Of5,
        starRating3Of5,
        starRating45Of5,
        starRating4Of5,
        starRating5Of5,
        empty,
        icFavorEmpty,
        icFavorFill,
        iconSettingIcon,
        iconSigninupIcon,
        launchImage
      ];
}

abstract final class Assets {
  static const String colors = 'assets/colors.xml';
  static const $ImagesGen images = $ImagesGen();

  /// List of all assets
  static List<String> get values => [colors];
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({
    AssetBundle? bundle,
    String? package,
  }) {
    return AssetImage(
      _assetName,
      bundle: bundle,
      package: package,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}
