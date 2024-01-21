import 'dart:async';

import '../../../model/exceptions/isolate_exceptions.dart';
import '../executor/isolate_executor.dart';

class CancellableController<T> {
  CancellableController(this.result, {required IsolateExecutor isolateExecutor})
      : _executor = isolateExecutor;

  final Completer<T> result;

  final IsolateExecutor _executor;

  Future<T> get future => result.future;

  /// Cancels the task. After cancellation, the result will be completed with
  /// [IsolateTaskCancelledException]. If the task has already been
  /// completed, nothing happens.
  void cancel() {
    if (result.isCompleted) {
      return;
    }

    result.completeError(IsolateTaskCancelledException());
    _executor.close();
  }

  /// Pause the task in the next tick. If the task has already been completed,
  /// nothing happens. Otherwise, if the task has not yet been paused in the
  /// timeout, throw [PauseIsolateTaskTimeoutException].
  Future<void> pauseInNextTick({Duration? timeout}) async {
    if (result.isCompleted) {
      return;
    }

    return _executor.pauseInNextTick(timeout: timeout);
  }

  /// Resume the task. If the task has already been completed, nothing happens.
  void resume() {
    if (result.isCompleted) {
      return;
    }
    _executor.resume();
  }
}
