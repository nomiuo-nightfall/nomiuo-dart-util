class GetResourceFromPoolTimeout implements Exception {
  const GetResourceFromPoolTimeout(this.message);
  final String message;
}

class GetResourceFromPoolFailed implements Exception {
  const GetResourceFromPoolFailed(this.message);
  final String message;
}

class CreateResourceFailed implements Exception {
  const CreateResourceFailed(this.message);
  final String message;
}

class WaitForNotifierTimeout implements Exception {
  const WaitForNotifierTimeout(this.message);
  final String message;
}

class ObserverHasWaited implements Exception {
  const ObserverHasWaited(this.message);
  final String message;
}

class NoSuchObserver implements Exception {
  const NoSuchObserver(this.message);
  final String message;
}
