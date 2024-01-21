import 'dart:async';

import '../../../model/exceptions/isolate_exceptions.dart';
import '../messages/cancellable_controller.dart';
import '_isolate_executor_impl.dart';

abstract class IsolateExecutor {
  static Future<IsolateExecutor> create() async => createIsolateExecutor();

  /// Execute the task with the given timeout. If the timeout reached and the
  /// task has not been completed, stop the task and the result of
  /// [CancellableController] will be completed with
  /// [IsolateTaskTimeoutException].
  CancellableController<T> execute<T>(FutureOr<T> Function() task,
      {Duration? timeout});

  /// Closes the executor and stops all the tasks.
  void close();

  /// Pause the executor in the next tick. If the executor does not have a task,
  /// nothing happens. Otherwise, if the task has not yet been paused in the
  /// timeout, throw [PauseIsolateTaskTimeoutException].
  Future<void> pauseInNextTick({Duration? timeout});

  /// Resume the executor.
  void resume();

  bool get isRunning;

  bool get isClosed;

  bool get isPaused;

  bool get isFree;
}
