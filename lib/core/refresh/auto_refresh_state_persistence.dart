import 'package:colmeia/core/refresh/auto_refresh_snapshot.dart';

abstract interface class AutoRefreshStatePersistence {
  AutoRefreshSnapshot restoreAutoRefreshSnapshot();

  Future<void> persistAutoRefreshSnapshot(AutoRefreshSnapshot snapshot);
}
