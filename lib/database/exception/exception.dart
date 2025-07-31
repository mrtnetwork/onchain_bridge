class IDatabaseException implements Exception {
  final String message;
  const IDatabaseException(this.message);
  @override
  String toString() {
    return message;
  }
}
