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
