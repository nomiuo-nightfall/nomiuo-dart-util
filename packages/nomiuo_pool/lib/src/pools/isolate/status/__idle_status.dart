part of '_isolate_executor_status.dart';

class ExecutorIDLEStatus extends ExecutorStatus {
  ExecutorIDLEStatus(super.isolateExecutorWithStatus);

  @override
  void close() {
    _updateStatusToClosed();
    _isolateExecutorContext.isolate.kill(priority: Isolate.immediate);
  }

  @override
  CancellableController<T> execute<T>(FutureOr<T> Function() task,
      {Duration? timeout}) {
    _updateStatusToRunning();

    return _execute(task, timeout: timeout);
  }

  CancellableController<T> _execute<T>(FutureOr<T> Function() task,
      {Duration? timeout}) {
    _isolateExecutorContext.subSendPort
        .send(IsolateControllerStartMessage(task));

    final Completer<T> completer = Completer<T>();
    if (timeout == null) {
      _waitForResult<T>(completer);
    } else {
      _waitForResultWithTimeout<T>(timeout, completer);
    }

    return CancellableController<T>(
      completer,
      isolateExecutor: _isolateExecutorContext,
    );
  }

  void _waitForResultWithTimeout<T>(Duration timeout, Completer<T> completer) {
    runZonedGuarded(
        () => _isolateExecutorContext.subEventStream.firstWhereWithTimeout(
                (Object? element) => element is IsolateTaskResult,
                timeout: timeout, onTimeout: () {
              completer.completeError(IsolateTaskTimeoutException());
              close();
            }).then(
              (Object? result) => _handleTaskResult<T>(result, completer),
            ),
        (_, __) {});
  }

  void _waitForResult<T>(Completer<T> completer) {
    runZoned(() => _isolateExecutorContext.subEventStream
            .firstWhere((Object? element) => element is IsolateTaskResult)
            .then((Object? result) {
          _handleTaskResult<T>(result, completer);
        }));
  }

  void _handleTaskResult<T>(Object? result, Completer<T> completer) {
    try {
      final IsolateTaskResult<Object?> taskResult =
          result! as IsolateTaskResult<Object?>;
      if (taskResult.error != null) {
        completer.completeError(taskResult.error!);
        return;
      }
      if (taskResult.result == null) {
        completer.complete(null);
        return;
      }
      completer.complete(taskResult.result as T);
    } finally {
      if (isRunning) {
        _updateStatusToIdle();
      }
    }
  }

  @override
  Future<void> pauseInNextTick({Duration? timeout}) =>
      Future<void>.error(IsolateStatusNotValidException(
          'The status IDLE not support pause task in next tick.'));

  @override
  void resume() {
    throw IsolateStatusNotValidException(
        'The status IDLE not support resume task.');
  }
}
