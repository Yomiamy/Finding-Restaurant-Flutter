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
  static const double radiusTag = 15;

  // ────────────────────────────────────────────
  // 圖片/圖示尺寸 (Image / Icon)
  // ────────────────────────────────────────────
  static const double ratingImageW = 100;
  static const double ratingImageH = 20;
  static const double favorImageW = 20;
  static const double favorImageH = 20;
  static const double ratingStarSize = 16;
  static const double restaurantItemImageSize = 110;

  // ────────────────────────────────────────────
  // 骨架圖預設尺寸 (Skeleton)
  // ────────────────────────────────────────────
  static const double skeletonTextHeightLg = 16;
  static const double skeletonTextHeightMd = 14;
  static const double skeletonTextWidthLg = 120;
  static const double skeletonTextWidthMd = 80;
}
