import 'package:flutter/material.dart';

import 'theme_size.dart';

/// App 字級定義。
///
/// 只覆寫實測有使用的 5 個 Material 3 角色，其餘沿用 M3 預設。
/// 舊 `UIConstants` 字級常數的對照見
/// `docs/plans/2026-07-31-design-system-foundation.md` §2.1。
abstract final class ThemeTextStyle {
  static const TextTheme textTheme = TextTheme(
    titleLarge: TextStyle(fontSize: ThemeSize.textXXL),
    titleMedium: TextStyle(fontSize: ThemeSize.textXL),
    bodyLarge: TextStyle(fontSize: ThemeSize.textL),
    bodyMedium: TextStyle(fontSize: ThemeSize.textM),
    labelSmall: TextStyle(fontSize: ThemeSize.textS),
  );
}
