import 'dart:async';
import 'dart:isolate';

import '../../../../nomiuo_pool_util.dart';
import '../../../model/exceptions/isolate_exceptions.dart';
import '../executor/_isolate_executor_impl.dart';
import '../executor/isolate_executor.dart';
import '../messages/cancellable_controller.dart';
import '../messages/controller_message.dart';
import '../messages/result_message.dart';

part '__closed_status.dart';
part '__idle_status.dart';
part '__paused_status.dart';
part '__running_status.dart';

sealed class ExecutorStatus implements IsolateExecutor {
  ExecutorStatus(IsolateExecutorContext isolateExecutorWithStatus)
      : _isolateExecutorContext = isolateExecutorWithStatus;

  final IsolateExecutorContext _isolateExecutorContext;

  @override
  bool get isClosed => _isolateExecutorContext.isClosed;

  @override
  bool get isFree => _isolateExecutorContext.isFree;

  @override
  bool get isPaused => _isolateExecutorContext.isPaused;

  @override
  bool get isRunning => _isolateExecutorContext.isRunning;

  void _updateStatusToRunning() {
    _isolateExecutorContext.currentStatus = ExecutorRunningStatus(
      _isolateExecutorContext,
    );
  }

  void _updateStatusToPaused(Capability resumeCapability) {
    _isolateExecutorContext.currentStatus = ExecutorPausedStatus(
        _isolateExecutorContext,
        resumeCapability: resumeCapability);
  }

  void _updateStatusToIdle() {
    _isolateExecutorContext.currentStatus = ExecutorIDLEStatus(
      _isolateExecutorContext,
    );
  }

  void _updateStatusToClosed() {
    _isolateExecutorContext.currentStatus = ExecutorClosedStatus(
      _isolateExecutorContext,
    );
  }
}
