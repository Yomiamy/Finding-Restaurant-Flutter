import 'dart:async';

extension FutureExtension on Future {
  get stream => Stream.fromFuture(this);
}