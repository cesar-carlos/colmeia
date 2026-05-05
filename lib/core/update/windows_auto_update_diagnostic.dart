import 'package:colmeia/core/update/windows_auto_update_state.dart';

class WindowsAutoUpdateDiagnostic {
  const WindowsAutoUpdateDiagnostic({
    required this.status,
    required this.headline,
    required this.details,
    required this.feedUrl,
    required this.lastCheckedAt,
  });

  final WindowsAutoUpdateStatus status;
  final String headline;
  final String? details;
  final String feedUrl;
  final DateTime? lastCheckedAt;
}
