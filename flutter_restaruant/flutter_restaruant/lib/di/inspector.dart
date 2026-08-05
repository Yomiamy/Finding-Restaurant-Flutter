import 'package:flutter/foundation.dart';
import 'package:flutter_inspector_kit/flutter_inspector_kit.dart';

/// Debug-only 除錯工具實例。release build 中恆為 `null`，
/// 所有引用點因此成為 dead code 而被 tree-shaking 移除。
///
/// 以下參數皆為使用者明確要求開啟的 debug-only 行為，整個建構子都在
/// `kDebugMode` 分支內，release 恆為 `null`，不影響 AC-9：
/// - `showNetworkNotification`：debug 時網路請求跳系統通知
/// - `captureUncaughtErrors`：debug 時攔截未捕捉例外
/// - `captureLifecycleEvents`：debug 時記錄生命週期事件
/// - `redactSensitiveData: false`：debug 時 Network 分頁不遮蔽敏感欄位
final FlutterInspector? inspector = kDebugMode
    ? FlutterInspector(
        slowRequestThreshold: const Duration(seconds: 2),
        showNetworkNotification: true,
        captureUncaughtErrors: true,
        captureLifecycleEvents: true,
        redactSensitiveData: false,
      )
    : null;
