import 'package:flutter/material.dart';

/// 提供安全且一致的全域 SnackBar 呼叫擴充方法。
extension SnackBarExtension on BuildContext {
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

    final callerInset = MediaQuery.maybeViewInsetsOf(this)?.bottom ?? 0.0;
    final messengerInset =
        MediaQuery.maybeViewInsetsOf(messenger.context)?.bottom ?? 0.0;
    final bottomInset = callerInset > messengerInset
        ? callerInset
        : messengerInset;
    final keyboardIsOpen = bottomInset > 0.0;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          action: action,
          behavior: keyboardIsOpen ? SnackBarBehavior.floating : null,
          margin: keyboardIsOpen ? EdgeInsets.only(bottom: bottomInset) : null,
        ),
      );
  }
}
