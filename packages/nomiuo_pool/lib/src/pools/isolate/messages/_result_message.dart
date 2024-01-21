sealed class IsolateResultMessage {}

class IsolateTaskResult<T> extends IsolateResultMessage {
  IsolateTaskResult({this.result, this.error});

  final T? result;

  final Object? error;
}

class IsolatePausedSuccessfully extends IsolateResultMessage {
  IsolatePausedSuccessfully();
}
