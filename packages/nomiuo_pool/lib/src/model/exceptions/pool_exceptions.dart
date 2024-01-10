class GetResourceFromPoolTimeout implements Exception {
  const GetResourceFromPoolTimeout(this.message);
  final String message;
}

class CreateResourceFailed implements Exception {
  const CreateResourceFailed(this.message);
  final String message;
}
