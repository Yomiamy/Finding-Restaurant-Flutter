import 'package:flutter/material.dart';

import '../../../features/foundation/style/style_barrel.dart';

/// 啟動頁的圓形主視覺。
///
/// 對應 Stitch handoff spec「Splash Screen」：200dp 的圓形餐點illustration，
/// 右下角疊一顆 48dp 的品牌色圓形徽章。
///
/// 徽章刻意溢出圓形邊界（`Stack` 不裁切），與設計稿的 `-bottom-4 -right-4`
/// 一致，因此外層須預留溢出空間。
class SplashHeroWidget extends StatelessWidget {
  const SplashHeroWidget({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: ThemeSize.size200 + ThemeSize.space16,
    height: ThemeSize.size200 + ThemeSize.space16,
    child: Stack(
      children: <Widget>[
        ClipOval(
          child: Image.asset(
            'images/launch_image.png',
            width: ThemeSize.size200,
            height: ThemeSize.size200,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: ThemeSize.zero,
          bottom: ThemeSize.zero,
          child: Container(
            width: ThemeSize.size48,
            height: ThemeSize.size48,
            decoration: const BoxDecoration(
              color: ThemeColor.colord84a20,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant,
              color: ThemeColor.colorffffff,
              size: ThemeSize.size24,
            ),
          ),
        ),
      ],
    ),
  );
}
