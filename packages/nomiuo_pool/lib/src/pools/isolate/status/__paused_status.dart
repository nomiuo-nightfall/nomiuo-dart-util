part of '_isolate_executor_status.dart';

class ExecutorPausedStatus extends ExecutorStatus {
  ExecutorPausedStatus(super.isolateExecutorWithStatus,
      {required this.resumeCapability});

  final Capability resumeCapability;

  @override
  void close() {
    _updateStatusToClosed();
    _isolateExecutorContext.isolate.kill(priority: Isolate.immediate);
  }

  @override
  CancellableController<T> execute<T>(FutureOr<T> Function() task,
      {Duration? timeout}) {
    throw IsolateStatusNotValidException(
      'The status PAUSED not support execute task.',
    );
  }

  @override
  Future<void> pauseInNextTick({Duration? timeout}) {
    throw IsolateStatusNotValidException(
      'The status PAUSED not support pause task in next tick.',
    );
  }

  @override
  void resume() {
    if (isPaused) {
      _updateStatusToRunning();
      _isolateExecutorContext.isolate.resume(resumeCapability);
    }
  }
}
