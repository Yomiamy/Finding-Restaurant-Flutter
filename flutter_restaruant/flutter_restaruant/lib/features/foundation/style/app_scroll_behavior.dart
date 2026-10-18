import 'dart:ui';

import 'package:flutter/material.dart';

/// 在預設拖曳裝置之外加入滑鼠的全域 [ScrollBehavior]。
///
/// 預設 Flutter 的 [MaterialScrollBehavior] 排除 [PointerDeviceKind.mouse]，
/// 導致桌面與 Web 環境下無法以滑鼠按住拖曳 [PageView]、[ListView] 等元件。
/// 本類別將 [PointerDeviceKind.mouse] 納入 [dragDevices]，改善桌面滾動體驗。
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  // 沿用預設集合再加 mouse：預設含 Android Voice Access 送出的 unknown，整組重寫會漏掉
  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };
}
