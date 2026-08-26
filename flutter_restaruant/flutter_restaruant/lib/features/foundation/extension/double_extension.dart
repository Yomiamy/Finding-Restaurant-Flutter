/// 針對 [double?] 數值的擴充方法。
extension DoubleExtension on double? {
  /// 將距離數值（單位：公尺）格式化為易讀字串。
  ///
  /// - 若為 `null`，回傳空字串 `''`。
  /// - 若小於 1000 公尺，回傳整數公尺字串（例：`583 m`）。
  /// - 若大於等於 1000 公尺，回傳取至小數點後一位的公里字串（例：`1.5 km`）。
  String formatDistance() {
    final distance = this;
    if (distance == null) return '';
    if (distance < 1000) {
      return '${distance.toInt()} m';
    }
    return '${(distance / 1000).toStringAsFixed(1)} km';
  }
}
