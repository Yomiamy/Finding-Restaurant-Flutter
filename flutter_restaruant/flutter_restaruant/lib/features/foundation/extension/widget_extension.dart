import 'dart:async';

import 'package:flutter/widgets.dart';

extension StateFrameCallbackExtension on State {
  /// 在本幀 build 結束後執行 [action]，且僅在 widget 仍掛載時執行。
  ///
  /// 包裝 `WidgetsBinding.instance.addPostFrameCallback` 與 `mounted` 檢查，
  /// 消除「排程 → 檢查 mounted」這組每次都要重寫的樣板。
  void runAfterFrame(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      action();
    });
  }

  /// 等待本幀 build 結束，可搭配 `await` 把 callback 拉平成直線程式碼。
  ///
  /// 若 widget 在該幀後已被 unmount，回傳 `false`；呼叫端據此提早返回：
  ///
  /// ```dart
  /// if (!await waitForFrame()) return;
  /// ```
  ///
  /// 注意：回傳 `true` 只保證「當下」仍掛載。之後每跨越一次 `await`，
  /// 都必須重新檢查 `mounted` 才可碰觸 `BuildContext`。
  Future<bool> waitForFrame() {
    // 已 unmount 就不會再有新的 frame，callback 永遠不觸發。
    // 必須在此提早返回，否則呼叫端會永久卡在 await。
    if (!mounted) return Future.value(false);

    final completer = Completer<bool>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      completer.complete(mounted);
    });
    return completer.future;
  }
}
