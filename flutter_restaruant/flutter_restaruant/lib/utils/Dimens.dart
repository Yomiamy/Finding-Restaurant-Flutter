/// 間距與圓角 token。
///
/// 數值採 4 的倍數階梯（Material 慣例）。呼叫端自行組合 `EdgeInsets`，
/// 刻意不預組 `EdgeInsets.all(space16)` 這類便利常數 —— 實際需要的組合
/// （`only` / `symmetric` / `fromLTRB`）太雜，預組會變成猜測遊戲。
abstract final class Dimens {
  // Spacing
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;

  // Corner radius
  static const double radiusCard = 16;
  static const double radiusChip = 20;
  static const double radiusImage = 12;
}
