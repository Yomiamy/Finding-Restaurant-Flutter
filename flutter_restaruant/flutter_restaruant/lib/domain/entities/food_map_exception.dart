/// 共編美食地圖領域錯誤碼。
enum FoodMapErrorCode {
  invalidInput,
  invalidInviteCode,
  mapNotFound,
  itemNotFound,
  permissionDenied,
  inviteCodeGenerationFailed,
  unknown,
}

/// 共編美食地圖領域例外，供表現層依 [code] 對應多國語系訊息。
class FoodMapException implements Exception {
  final FoodMapErrorCode code;
  final String? debugMessage;

  const FoodMapException(this.code, [this.debugMessage]);

  @override
  String toString() =>
      'FoodMapException(${code.name}${debugMessage == null ? '' : ': $debugMessage'})';
}
