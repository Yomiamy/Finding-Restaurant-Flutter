import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'theme_color.dart';
import 'theme_text_style.dart';

/// App 的 Material 3 主題。
///
/// 於 S3 階段將原先 UI 中寫死的 `Colors.*` 統一收斂至此：
/// 透過 `copyWith` 將特定的語意角色 (primary, outline, error, onPrimary, surface)
/// 對應至 `ThemeColor` 裡定義的實體色，確保所有引用 `Theme.of(context).colorScheme`
/// 的元件都能呈現精準的設計稿顏色，並解決 S1/S2 遺留的 M3 tonal palette 色差問題。
abstract final class AppThemeData {
  static final ThemeData materialLight = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: ThemeColor.appPrimary).copyWith(
      primary: ThemeColor.appPrimary, // 強制覆寫避免 M3 fromSeed 變濁
      outline: ThemeColor.outline,
      error: ThemeColor.error,
      onPrimary: ThemeColor.onPrimary,
      surface: ThemeColor.surface, // 奶油白
    ),
    textTheme: ThemeTextStyle.textTheme,
  );

  static const CupertinoThemeData cupertinoLight = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: ThemeColor.appPrimary,
  );
}
