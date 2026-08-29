import 'package:flutter/material.dart';

import '../../../features/foundation/style/style_barrel.dart';

/// 設定頁頁首圖形。
///
/// 對應 Stitch handoff spec「Settings」的 Header Image Section：
/// 200×200dp 的圓形齒輪圖。
///
/// 圖檔本身是不透明白底的方形 JPEG，因此用 `ClipOval` 裁成圓形、`BoxFit.cover`
/// 填滿——不留內距，否則白底方圖與圓形容器之間會露出一圈邊。
class SettingsHeaderWidget extends StatelessWidget {
  const SettingsHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) => ClipOval(
    child: Image.asset(
      'images/icon_setting_icon.jpg',
      // 設計稿（Stitch handoff）標註 Settings Graphic: 200.0 × 200.0dp。
      width: ThemeSize.size200,
      height: ThemeSize.size200,
      fit: BoxFit.cover,
    ),
  );
}
