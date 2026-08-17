import 'package:flutter/material.dart';

/// App 字級定義。
///
/// 只覆寫實測有使用的 5 個 Material 3 角色，其餘沿用 M3 預設。
/// 舊 `UIConstants` 字級常數的對照見
/// `docs/plans/2026-07-31-design-system-foundation.md` §2.1。
abstract final class ThemeTextStyle {
  static const TextTheme textTheme = TextTheme(
    titleLarge: TextStyle(fontSize: ThemeFontSize.fontSize22),
    titleMedium: TextStyle(fontSize: ThemeFontSize.fontSize18),
    bodyLarge: TextStyle(fontSize: ThemeFontSize.fontSize16),
    bodyMedium: TextStyle(fontSize: ThemeFontSize.fontSize14),
    labelSmall: TextStyle(fontSize: ThemeFontSize.fontSize12),
  );
}

/// 字級原始值。
///
/// 僅供 `ThemeTextStyle` 組裝 `TextTheme` 使用。UI 端請勿直接引用 ——
/// 字級的語意來源是 `Theme.of(context).textTheme`。
abstract final class ThemeFontSize {
  static const double fontSize10 = 10;
  static const double fontSize12 = 12;
  static const double fontSize14 = 14;
  static const double fontSize16 = 16;
  static const double fontSize18 = 18;
  static const double fontSize20 = 20;
  static const double fontSize22 = 22;
  static const double fontSize24 = 24;
  static const double fontSize26 = 26;
  static const double fontSize28 = 28;
}
