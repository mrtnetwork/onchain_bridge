class OnChainBridgeException implements Exception {
  final String message;
  const OnChainBridgeException(this.message);
  static OnChainBridgeException unsuported =
      const OnChainBridgeException("Unsuported feature.");

  @override
  String toString() {
    return "OnChainBridgeException{$message}";
  }
}
