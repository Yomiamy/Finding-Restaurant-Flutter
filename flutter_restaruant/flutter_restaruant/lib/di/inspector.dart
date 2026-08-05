import 'package:flutter/foundation.dart';
import 'package:flutter_inspector_kit/flutter_inspector_kit.dart';

/// Debug-only 除錯工具實例。release build 中恆為 `null`，
/// 所有引用點因此成為 dead code 而被 tree-shaking 移除。
final FlutterInspector? inspector = kDebugMode
    ? FlutterInspector(slowRequestThreshold: const Duration(seconds: 2))
    : null;
