part of 'block.dart';

abstract class Observer {
  factory Observer() => _Observer();

  /// Wait for the notifier to wake up, then call callback.
  ///
  /// If the timeout is reached, then throw [WaitForNotifierTimeout].
  Future<void> wait(Notifier notifier,
      {Duration? timeout, FutureOr<void> Function(Object?)? callback});

  Future<void> _wakeUp({Object? obj});
}

class _Observer implements Observer {
  bool _hasWaited = false;

  final Completer<Object?> _completer = Completer<Object?>();

  @override
  Future<void> wait(Notifier notifier,
      {Duration? timeout, FutureOr<void> Function(Object?)? callback}) async {
    _checkWaited();

    await notifier._addObserver(this);

    if (timeout == null) {
      return _completer.future.then((Object? obj) async {
        await notifier._removeObserver(this);
        await callback?.call(obj);
      });
    }
    return _completer.future.timeout(timeout, onTimeout: () async {
      await notifier._removeObserver(this);
      throw const WaitForNotifierTimeout('Timeout waiting for notifier.');
    }).then((Object? obj) async {
      await notifier._removeObserver(this);
      await callback?.call(obj);
    });
  }

  @override
  Future<void> _wakeUp({Object? obj}) async {
    if (_completer.isCompleted) {
      return;
    }
    _completer.complete(obj);
  }

  void _checkWaited() {
    if (_hasWaited) {
      throw const ObserverHasWaited('Observer has waited.');
    }
    _hasWaited = true;
  }
}
