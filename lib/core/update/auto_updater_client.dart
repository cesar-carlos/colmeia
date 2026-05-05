import 'package:auto_updater/auto_updater.dart';

abstract interface class AutoUpdaterClient {
  void addListener(UpdaterListener listener);
  void removeListener(UpdaterListener listener);
  Future<void> setFeedUrl(String feedUrl);
  Future<void> checkForUpdates({required bool inBackground});
  Future<void> setScheduledCheckInterval(int intervalInSeconds);
}

final class LeanAutoUpdaterClient implements AutoUpdaterClient {
  const LeanAutoUpdaterClient();

  @override
  void addListener(UpdaterListener listener) {
    autoUpdater.addListener(listener);
  }

  @override
  Future<void> checkForUpdates({required bool inBackground}) {
    return autoUpdater.checkForUpdates(inBackground: inBackground);
  }

  @override
  void removeListener(UpdaterListener listener) {
    autoUpdater.removeListener(listener);
  }

  @override
  Future<void> setFeedUrl(String feedUrl) {
    return autoUpdater.setFeedURL(feedUrl);
  }

  @override
  Future<void> setScheduledCheckInterval(int intervalInSeconds) {
    return autoUpdater.setScheduledCheckInterval(intervalInSeconds);
  }
}
