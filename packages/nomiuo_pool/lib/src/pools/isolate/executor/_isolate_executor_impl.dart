import 'dart:async';
import 'dart:isolate';

import '../messages/cancellable_controller.dart';
import '../messages/controller_message.dart';
import '../messages/result_message.dart';
import '../status/_isolate_executor_status.dart';
import 'isolate_executor.dart';

Future<IsolateExecutor> createIsolateExecutor() async {
  final ReceivePort receivePort = ReceivePort();
  final Stream<Object?> subEventStream = receivePort.asBroadcastStream();
  final Isolate isolate =
      await Isolate.spawn<SendPort>(_executor, receivePort.sendPort);
  final SendPort subSendPort = (await subEventStream.first)! as SendPort;
  final IsolateExecutorContext isolateExecutor = IsolateExecutorContextImpl(
      isolate: isolate,
      subEventStream: subEventStream,
      subSendPort: subSendPort);
  isolateExecutor._currentStatus = ExecutorIDLEStatus(isolateExecutor);
  return isolateExecutor;
}

void _executor(SendPort parentSendPort) {
  final ReceivePort receivePort = ReceivePort();
  parentSendPort.send(receivePort.sendPort);

  receivePort.listen((Object? isolateTask) async {
    if (isolateTask is IsolateControllerMessage) {
      switch (isolateTask) {
        case IsolateControllerStartMessage():
          try {
            final Object? result = await isolateTask.task();
            parentSendPort.send(IsolateTaskResult<Object?>(result: result));
          } on Object catch (e) {
            parentSendPort.send(IsolateTaskResult<void>(error: e));
          }
          break;
        case IsolateControllerPauseMessage():
          parentSendPort.send(IsolatePausedSuccessfully());
          Isolate.current.pause(isolateTask.resumeCapability);
          break;
      }
    }
  });
}

abstract class IsolateExecutorContext implements IsolateExecutor {
  IsolateExecutorContext(
      {required Isolate isolate,
      required Stream<Object?> subEventStream,
      required SendPort subSendPort})
      : _isolate = isolate,
        _subEventStream = subEventStream,
        _subSendPort = subSendPort;

  late ExecutorStatus _currentStatus;

  final Isolate _isolate;

  final Stream<Object?> _subEventStream;

  final SendPort _subSendPort;

  Stream<Object?> get subEventStream => _subEventStream;

  SendPort get subSendPort => _subSendPort;

  Isolate get isolate => _isolate;

  set currentStatus(ExecutorStatus status) {
    _currentStatus = status;
  }
}

class IsolateExecutorContextImpl extends IsolateExecutorContext {
  IsolateExecutorContextImpl(
      {required super.isolate,
      required super.subEventStream,
      required super.subSendPort});

  @override
  void close() {
    _currentStatus.close();
  }

  @override
  Future<void> pauseInNextTick({Duration? timeout}) =>
      _currentStatus.pauseInNextTick(timeout: timeout);

  @override
  CancellableController<T> execute<T>(FutureOr<T> Function() task,
          {Duration? timeout}) =>
      _currentStatus.execute(task, timeout: timeout);

  @override
  void resume() {
    _currentStatus.resume();
  }

  @override
  bool get isClosed => _currentStatus is ExecutorClosedStatus;

  @override
  bool get isFree => _currentStatus is ExecutorIDLEStatus;

  @override
  bool get isPaused => _currentStatus is ExecutorPausedStatus;

  @override
  bool get isRunning => _currentStatus is ExecutorRunningStatus;
}
