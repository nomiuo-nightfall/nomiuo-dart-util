class IsolateTaskCancelledException implements Exception {
  IsolateTaskCancelledException();
}

class IsolateTaskTimeoutException implements Exception {
  IsolateTaskTimeoutException();
}

class IsolateStatusNotValidException implements Exception {
  IsolateStatusNotValidException(this.message);

  final String message;
}

class PauseIsolateTaskTimeoutException implements Exception {
  PauseIsolateTaskTimeoutException();
}
