import 'package:colmeia/core/update/app_auto_update_support.dart';

enum WindowsAutoUpdateStatus {
  unavailable,
  idle,
  checking,
  updateAvailable,
  upToDate,
  feedWithoutReleases,
  readyToInstall,
  failed,
}

class WindowsAutoUpdateState {
  const WindowsAutoUpdateState({
    required this.availability,
    required this.status,
    required this.headline,
    required this.details,
    required this.feedUrl,
    required this.lastCheckedAt,
  });

  const WindowsAutoUpdateState.initial()
    : this(
        availability: AppAutoUpdateAvailability.unsupportedPlatform,
        status: WindowsAutoUpdateStatus.unavailable,
        headline: '',
        details: null,
        feedUrl: '',
        lastCheckedAt: null,
      );

  final AppAutoUpdateAvailability availability;
  final WindowsAutoUpdateStatus status;
  final String headline;
  final String? details;
  final String feedUrl;
  final DateTime? lastCheckedAt;

  bool get shouldShowInSettings =>
      availability != AppAutoUpdateAvailability.unsupportedPlatform;

  bool get canCheckForUpdates =>
      availability == AppAutoUpdateAvailability.supported &&
      status != WindowsAutoUpdateStatus.checking;

  bool get isChecking => status == WindowsAutoUpdateStatus.checking;

  WindowsAutoUpdateState copyWith({
    AppAutoUpdateAvailability? availability,
    WindowsAutoUpdateStatus? status,
    String? headline,
    String? details,
    String? feedUrl,
    DateTime? lastCheckedAt,
    bool clearDetails = false,
    bool keepLastCheckedAt = true,
  }) {
    return WindowsAutoUpdateState(
      availability: availability ?? this.availability,
      status: status ?? this.status,
      headline: headline ?? this.headline,
      details: clearDetails ? null : details ?? this.details,
      feedUrl: feedUrl ?? this.feedUrl,
      lastCheckedAt: keepLastCheckedAt
          ? (lastCheckedAt ?? this.lastCheckedAt)
          : lastCheckedAt,
    );
  }
}
