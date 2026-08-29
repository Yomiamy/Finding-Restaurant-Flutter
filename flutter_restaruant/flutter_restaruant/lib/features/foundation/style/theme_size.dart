/// 集中管理間距、圓角、圖片尺寸等數值，消除 UI 程式碼中的硬編碼數字。
///
/// 階梯取自實測既有值（5 的倍數），而非 Material 慣用的 4 的倍數 ——
/// 目的是讓既有使用點能一對一替換、零視覺變更。若日後要改走 4dp 階梯，
/// 那是一次獨立的視覺調整，需逐頁截圖比對。
///
/// 字級原始值不在此處，見 `theme_text_style.dart` 的 `ThemeFontSize`。
abstract final class ThemeSize {
  // ────────────────────────────────────────────
  // 間距 (Spacing)
  // ────────────────────────────────────────────
  static const double zero = 0;
  static const double space3 = 3;
  static const double space4 = 4;
  static const double space5 = 5;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space15 = 15;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space25 = 25;
  static const double space30 = 30;
  static const double space50 = 50;
  static const double space64 = 64;

  // ────────────────────────────────────────────
  // 圓角 (Radius)
  // ────────────────────────────────────────────
  static const double radius8 = 8;
  static const double radius12 = 12;
  static const double radiusTag = 15;

  // ────────────────────────────────────────────
  // 一般尺寸 (Size)
  // ────────────────────────────────────────────
  static const double size14 = 14;
  static const double size16 = 16;
  static const double size18 = 18;
  static const double size20 = 20;
  static const double size24 = 24;
  static const double size48 = 48;
  static const double size52 = 52;
  static const double size64 = 64;
  static const double size80 = 80;
  static const double size100 = 100;
  static const double size110 = 110;
  static const double size120 = 120;
  static const double size140 = 140;
  static const double size180 = 180;
  static const double size200 = 200;
  static const double size220 = 220;
  static const double size320 = 320;
}
