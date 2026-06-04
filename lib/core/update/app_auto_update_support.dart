enum AppAutoUpdateAvailability {
  supported,
  unsupportedPlatform,
  feedUrlMissing,
  feedUrlInvalid,
}

abstract final class AppAutoUpdateSupport {
  static AppAutoUpdateAvailability resolveAvailability({
    required bool supportsNativeUpdates,
    required String feedUrl,
  }) {
    if (!supportsNativeUpdates) {
      return AppAutoUpdateAvailability.unsupportedPlatform;
    }

    final normalizedFeedUrl = normalizeFeedUrl(feedUrl);
    if (normalizedFeedUrl.isEmpty) {
      return AppAutoUpdateAvailability.feedUrlMissing;
    }

    if (!isXmlFeedUrl(normalizedFeedUrl) || !isHttpsFeedUrl(normalizedFeedUrl)) {
      return AppAutoUpdateAvailability.feedUrlInvalid;
    }

    return AppAutoUpdateAvailability.supported;
  }

  static String normalizeFeedUrl(String raw) => raw.trim();

  static bool isHttpsFeedUrl(String raw) {
    final normalized = normalizeFeedUrl(raw);
    if (normalized.isEmpty) {
      return true;
    }

    final uri = Uri.tryParse(normalized);
    return uri?.scheme.toLowerCase() == 'https';
  }

  static bool isXmlFeedUrl(String raw) {
    final normalized = normalizeFeedUrl(raw);
    if (normalized.isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(normalized);
    final path = uri?.path.trim() ?? '';
    return path.toLowerCase().endsWith('.xml');
  }

  /// Local validation shared with the appcast probe client before network I/O.
  static bool isProbeableFeedUrl(String raw) {
    final normalized = normalizeFeedUrl(raw);
    if (normalized.isEmpty) {
      return false;
    }

    return isHttpsFeedUrl(normalized) && isXmlFeedUrl(normalized);
  }
}
