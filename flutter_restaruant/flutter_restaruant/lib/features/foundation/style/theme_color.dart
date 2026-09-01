import 'package:flutter/material.dart';

/// 品牌色票。
///
/// 原本由 FlutterGen 從 `assets/colors.xml` 生成（`ColorName`），改為手寫
/// 常數 —— 只有兩個顏色，卻要為它維持 xml 來源、生成檔與 build_runner
/// 一整套工具鏈，且 xml 還會被打包進 app bundle 卻從不在 runtime 讀取。
///
/// 語意化的色彩角色請走 `Theme.of(context).colorScheme`；此處只放
/// `ColorScheme` 推導不出、必須明寫的品牌原始值。
abstract final class ThemeColor {
  /// 品牌主色，`ColorScheme.fromSeed` 的種子。
  static const Color appPrimary = Color(0xFFD84A20);

  /// 純白色。
  static const Color colorffffff = Color(0xFFFFFFFF);
}
