import 'package:flutter/material.dart';

import '../gen/colors.gen.dart';
import 'app_typography.dart';

/// App 的 Material 3 主題。
///
/// S1 定案：色票只做 `ColorScheme.fromSeed`，零 `copyWith` 覆寫
/// （見 `docs/features/2026-07-31-design-system-foundation.md` §4.4）。
/// 奶油白 surface 延到 S2；深色模式不做，`darkTheme` 留空。
///
/// ⚠️ 已知色差（S2 待處理）：`fromSeed` 會將品牌色 `#D84A20` 依 M3 tonal
/// palette 映射為 `#8F4B38`（較濁的棕橘），與仍硬編 `ColorName.appPrimaryColor`
/// 的 18 處 AppBar 並存時有可見色差。此為零 `copyWith` 的既定後果，非缺陷。
abstract final class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ColorName.appPrimaryColor,
    ),
    textTheme: AppTypography.textTheme,
  );
}
