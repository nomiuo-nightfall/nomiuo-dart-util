part of '_isolate_executor_status.dart';

class ExecutorRunningStatus extends ExecutorStatus {
  ExecutorRunningStatus(super.isolateExecutorWithStatus);

  final Capability resumeCapability = Capability();

  @override
  void close() {
    _updateStatusToClosed();
    _isolateExecutorContext.isolate.kill(priority: Isolate.immediate);
  }

  @override
  Future<void> pauseInNextTick({Duration? timeout}) async {
    _updateStatusToPaused(resumeCapability);

    _sendPausingRequest();

    final Completer<void> completer = Completer<void>();
    if (timeout == null) {
      _handlePausingSuccessfullyMessage(completer);
      return completer.future;
    }
    _handlePausingSuccessfullyMessageWithTimeout(timeout, completer);
    return completer.future;
  }

  @override
  void resume() {
    throw IsolateStatusNotValidException(
      'The status RUNNING not support resume task.',
    );
  }

  @override
  CancellableController<T> execute<T>(FutureOr<T> Function() task,
      {Duration? timeout}) {
    throw IsolateStatusNotValidException(
        'The executor has already has a task.');
  }

  void _handlePausingSuccessfullyMessageWithTimeout(
      Duration timeout, Completer<void> completer) {
    runZonedGuarded(
        () => _isolateExecutorContext.subEventStream
                .firstWhereWithTimeout(
                    (Object? element) => element is IsolatePausedSuccessfully,
                    timeout: timeout)
                .then((_) {
              completer.complete(null);
            }), (_, __) {
      completer.completeError(PauseIsolateTaskTimeoutException());
      if (isPaused) {
        _updateStatusToRunning();
      }
    });
  }

  void _handlePausingSuccessfullyMessage(Completer<void> completer) {
    runZoned(() => _isolateExecutorContext.subEventStream
        .firstWhere((Object? element) => element is IsolatePausedSuccessfully)
        .then((_) => completer.complete(null)));
  }

  void _sendPausingRequest() {
    _isolateExecutorContext.subSendPort
        .send(IsolateControllerPauseMessage(resumeCapability));
  }
}
