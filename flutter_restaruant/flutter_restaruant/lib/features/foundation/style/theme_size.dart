/// 集中管理間距、圓角、圖片尺寸等數值，消除 UI 程式碼中的硬編碼數字。
///
/// 階梯取自實測既有值（5 的倍數），而非 Material 慣用的 4 的倍數 ——
/// 目的是讓既有使用點能一對一替換、零視覺變更。若日後要改走 4dp 階梯，
/// 那是一次獨立的視覺調整，需逐頁截圖比對。
///
/// 字級不在此定義語意角色，僅提供 `ThemeTextStyle` 取用的原始數值；
/// 呼叫端一律走 `Theme.of(context).textTheme`。
abstract final class ThemeSize {
  // ────────────────────────────────────────────
  // 間距 (Spacing)
  // ────────────────────────────────────────────
  static const double zero = 0;
  static const double space3 = 3;
  static const double space4 = 4;
  static const double space5 = 5;
  static const double space10 = 10;
  static const double space15 = 15;
  static const double space20 = 20;
  static const double space25 = 25;
  static const double space30 = 30;
  static const double space50 = 50;

  // ────────────────────────────────────────────
  // 圓角 (Radius)
  // ────────────────────────────────────────────
  static const double radiusTag = 15;

  // ────────────────────────────────────────────
  // 圖片尺寸 (Image)
  // ────────────────────────────────────────────
  static const double ratingImageW = 100;
  static const double ratingImageH = 20;
  static const double favorImageW = 20;
  static const double favorImageH = 20;

  // ────────────────────────────────────────────
  // 字級原始值 (Font size)
  //
  // 僅供 `ThemeTextStyle` 組裝 `TextTheme` 使用。UI 端請勿直接引用 ——
  // 字級的語意來源是 `Theme.of(context).textTheme`。
  // ────────────────────────────────────────────
  static const double textS = 12;
  static const double textM = 14;
  static const double textL = 16;
  static const double textXL = 18;
  static const double textXXL = 22;
}
