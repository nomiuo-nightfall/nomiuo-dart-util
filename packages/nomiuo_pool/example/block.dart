import 'dart:async';

import 'package:nomiuo_pool/util.dart';

Future<void> main() async {
  final Notifier notifier = Notifier();
  final Observer observer = Observer();
  // observer will wait for notifier. If the timeout is reached, it will
  // throw [WaitForNotifierTimeout].
  unawaited(observer.wait(notifier, timeout: const Duration(seconds: 1),
      callback: (Object? obj) {
    // Here the value of obj is 'value'.
  }));
  // Notify with a value, then the callback of observer will be called.
  await notifier.notifyOne(obj: 'value');
}
