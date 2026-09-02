import 'package:flutter/material.dart';

/// 專案色票。
///
/// 一律遵循 `color` + 16 進位小寫色碼命名（如 `colorffffff`），
/// 編譯期靜態常數，業務元件直接引用，不再透過 ThemeData 查表。
abstract final class ThemeColor {
  /// 品牌主橘色 (#D84A20)。
  static const Color colord84a20 = Color(0xFFD84A20);

  /// 品牌主色相容過渡別名（後續批次全面替換後將刪除）。
  static const Color appPrimary = colord84a20;

  /// 奶油白主背景色 (#FFFBF7，原 T-6 決策)。
  static const Color colorfffbf7 = Color(0xFFFFFBF7);

  /// 純白色 (#FFFFFF)。
  static const Color colorffffff = Color(0xFFFFFFFF);

  /// 完全透明色 (#00000000)。
  static const Color color00000000 = Color(0x00000000);

  /// 灰色 (#9E9E9E)。
  static const Color color9e9e9e = Color(0xFF9E9E9E);

  /// 紅色 (#F44336)。
  static const Color colorf44336 = Color(0xFFF44336);

  /// 54% 半透明黑 (#8A000000)。
  static const Color color8a000000 = Color(0x8A000000);
}
