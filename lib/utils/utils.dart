class OnChainBridgeUtils {
  static String joinPathWithRoot(
    List<String> parts, {
    String separator = '/',
  }) {
    if (parts.isEmpty) return '';

    final isAbsolute = RegExp(r'^[\\/]').hasMatch(parts.first);

    final normalized = parts
        .where((e) => e.trim().isNotEmpty)
        .map((e) => e.replaceAll(RegExp(r'[\\/]'), separator).replaceAll(
              RegExp(
                  '^${RegExp.escape(separator)}+|${RegExp.escape(separator)}+\$'),
              '',
            ))
        .join(separator);

    return isAbsolute ? '$separator$normalized' : normalized;
  }
}
