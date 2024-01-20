import 'dart:async';

import '../model/exceptions/stream_exceptions.dart';

extension ReceivePortExtension on Stream<Object?> {
  Future<Object?> firstWithTimeout(Duration timeout,
      {void Function()? onTimeout}) async {
    final Completer<Object?> completer = Completer<Object?>();

    final StreamSubscription<Object?> subscription = listen(null);
    subscription
      ..onData((Object? value) {
        subscription.cancel();
        completer.complete(value);
      })
      ..onError((Object error) {
        subscription.cancel();
        completer.completeError(error);
      });
    Future<void>.delayed(timeout, () {
      if (completer.isCompleted) {
        return;
      }
      subscription.cancel();
      try {
        onTimeout?.call();
        completer.completeError(
            const StreamWaitTimeout('Wait for first value timeout.'));
      } on Object catch (e) {
        completer.completeError(e);
      }
    });

    return completer.future;
  }
}
