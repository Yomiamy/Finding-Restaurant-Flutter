import 'dart:ui';

import 'package:flutter/material.dart';

/// 支援滑鼠、觸控、觸控板與手寫筆拖曳滾動的全域 [ScrollBehavior]。
///
/// 預設 Flutter 的 [MaterialScrollBehavior] 排除 [PointerDeviceKind.mouse]，
/// 導致桌面與 Web 環境下無法以滑鼠按住拖曳 [PageView]、[ListView] 等元件。
/// 本類別將 [PointerDeviceKind.mouse] 納入 [dragDevices]，改善桌面滾動體驗。
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
  };
}
