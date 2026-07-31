import 'package:flutter/material.dart';

/// App 字級定義。
///
/// 只覆寫實測有使用的 5 個 Material 3 角色，其餘沿用 M3 預設。
/// 舊 `UIConstants` 字級常數的對照見
/// `docs/plans/2026-07-31-design-system-foundation.md` §2.1。
abstract final class AppTypography {
  static const TextTheme textTheme = TextTheme(
    titleLarge: TextStyle(fontSize: 22),
    titleMedium: TextStyle(fontSize: 18),
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14),
    labelSmall: TextStyle(fontSize: 12),
  );
}
