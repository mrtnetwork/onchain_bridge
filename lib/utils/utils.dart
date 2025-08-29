class OnChainBridgeUtils {
  static String joinPathWithRoot(List<String> parts) {
    bool isAbsolute =
        parts.isNotEmpty && parts.first.startsWith(RegExp(r'^[/\\]'));
    final joined = parts
        .where((p) => p.trim().isNotEmpty)
        .map((p) => p.replaceAll(RegExp(r'^[/\\]+|[/\\]+$'), ''))
        .join('/');
    return isAbsolute ? '/$joined' : joined;
  }
}
