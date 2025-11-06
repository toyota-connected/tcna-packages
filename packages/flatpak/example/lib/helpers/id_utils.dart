class AppIdUtils {
  static String extractShortId(String fullId) {
    String workingId = fullId;
    if (workingId.startsWith('app/')) {
      workingId = workingId.substring(4);
    }

    final parts = workingId.split('/');
    final shortId = parts.first;
    return shortId;
  }

  /// Check if two app IDs match
  static bool idsMatch(String id1, String id2) {
    return extractShortId(id1) == extractShortId(id2);
  }

  /// Normalize ID to short form
  static String normalize(String id) {
    return extractShortId(id);
  }
}