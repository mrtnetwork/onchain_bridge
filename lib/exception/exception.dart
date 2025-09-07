class OnChainBridgeException implements Exception {
  final String message;
  const OnChainBridgeException(this.message);
  static OnChainBridgeException unsuported =
      const OnChainBridgeException("Unsuported feature.");
  static OnChainBridgeException invalidFileData =
      const OnChainBridgeException("Invalid file content.");
  static OnChainBridgeException failedToReadFileContent =
      const OnChainBridgeException("Failed to read file content.");

  @override
  String toString() {
    return "OnChainBridgeException{$message}";
  }
}
