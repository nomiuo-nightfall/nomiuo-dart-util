part of '_isolate_executor_status.dart';

class ExecutorClosedStatus extends ExecutorStatus {
  ExecutorClosedStatus(super.isolateExecutorWithStatus);

  @override
  void close() {
    return;
  }

  @override
  CancellableController<T> execute<T>(FutureOr<T> Function() task,
      {Duration? timeout}) {
    throw IsolateStatusNotValidException(
      'The status CLOSED not support execute task.',
    );
  }

  @override
  Future<void> pauseInNextTick({Duration? timeout}) {
    throw IsolateStatusNotValidException(
      'The status CLOSED not support pause task in next tick.',
    );
  }

  @override
  void resume() {
    throw IsolateStatusNotValidException(
      'The status CLOSED not support resume task.',
    );
  }
}
