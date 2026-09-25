import 'dart:async';
import 'dart:ui';

import 'package:flutter_restaruant/generated/l10n.dart';

/// 所有測試共用：比照 `main()` 在 runApp 前載入 `S`，讓 `S.current` 永遠可用。
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await S.load(const Locale('zh', 'TW'));
  await testMain();
}
