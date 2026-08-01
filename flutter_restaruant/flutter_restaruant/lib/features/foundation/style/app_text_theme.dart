import 'package:flutter/material.dart';

import 'sizes.dart';

/// App 字級定義。
///
/// 只覆寫實測有使用的 5 個 Material 3 角色，其餘沿用 M3 預設。
/// 舊 `UIConstants` 字級常數的對照見
/// `docs/plans/2026-07-31-design-system-foundation.md` §2.1。
abstract final class AppTextTheme {
  static const TextTheme textTheme = TextTheme(
    titleLarge: TextStyle(fontSize: Sizes.textXXL),
    titleMedium: TextStyle(fontSize: Sizes.textXL),
    bodyLarge: TextStyle(fontSize: Sizes.textL),
    bodyMedium: TextStyle(fontSize: Sizes.textM),
    labelSmall: TextStyle(fontSize: Sizes.textS),
  );
}
