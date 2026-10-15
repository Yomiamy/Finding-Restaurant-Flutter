import 'package:flutter/material.dart';

/// 提供安全且一致的全域 SnackBar 呼叫擴充方法。
extension BuildContextSnackBarX on BuildContext {
  /// 顯示一則 Material 3 風格的 [SnackBar]。
  ///
  /// 會先清除當前顯示中的 SnackBar（[ScaffoldMessengerState.hideCurrentSnackBar]），
  /// 避免使用者連續操作時訊息堆疊等待。若查無 [ScaffoldMessenger] 則安全略過不崩潰。
  void showAppSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(this);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          action: action,
        ),
      );
  }
}
