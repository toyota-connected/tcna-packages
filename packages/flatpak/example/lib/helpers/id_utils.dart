class AppIdUtils {
  static String extractShortId(String fullId) {
    if (fullId.startsWith('app/')) {
      final parts = fullId.split('/');
      if (parts.length >= 2) {
        return parts[1];
      }
    }
    return fullId;
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