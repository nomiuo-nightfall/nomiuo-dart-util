import 'dart:async';
import 'dart:isolate';

sealed class IsolateControllerMessage {}

class IsolateControllerStartMessage extends IsolateControllerMessage {
  IsolateControllerStartMessage(this.task);

  final FutureOr<Object?> Function() task;
}

class IsolateControllerPauseMessage extends IsolateControllerMessage {
  IsolateControllerPauseMessage(this.resumeCapability);
  final Capability resumeCapability;
}
