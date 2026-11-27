/// 共編美食地圖餐廳項目的投票狀態。
enum FoodMapVote {
  up(1),
  down(-1),
  none(0);

  final int rawValue;

  const FoodMapVote(this.rawValue);

  static FoodMapVote fromRaw(int? raw) => switch (raw) {
    1 => FoodMapVote.up,
    -1 => FoodMapVote.down,
    _ => FoodMapVote.none,
  };
}
