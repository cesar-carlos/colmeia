import 'package:colmeia/core/refresh/auto_refresh_state_mixin.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';
import 'package:colmeia/features/sales/presentation/coordinators/sales_live_map_session_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SalesLiveMapSessionCoordinator coordinator;

  setUp(() {
    coordinator = SalesLiveMapSessionCoordinator();
  });

  test('consumePendingReload returns auto-refresh defaults when idle', () {
    final consumed = coordinator.consumePendingReload();
    expect(consumed.force, isFalse);
    expect(consumed.reason, SalesLiveMapReloadReason.autoRefresh);
  });

  test('markManualReload + consumePendingReload yields manual semantics', () {
    coordinator.markManualReload(force: true);

    final consumed = coordinator.consumePendingReload();
    expect(consumed.force, isTrue);
    expect(consumed.reason, SalesLiveMapReloadReason.manual);

    // Consuming a second time goes back to the auto-refresh default.
    final next = coordinator.consumePendingReload();
    expect(next.force, isFalse);
    expect(next.reason, SalesLiveMapReloadReason.autoRefresh);
  });

  test(
    'clearPendingReloadIfNotConsumed prevents a subsequent tick from '
    'inheriting manual semantics',
    () {
      coordinator.markManualReload(force: true);
      expect(coordinator.pendingReloadReason, SalesLiveMapReloadReason.manual);
      expect(coordinator.pendingReloadForceCount, 1);

      coordinator.clearPendingReloadIfNotConsumed();
      expect(coordinator.pendingReloadReason, isNull);
      expect(coordinator.pendingReloadForceCount, 0);

      // A subsequent tick that finds no pending entry must default to
      // auto-refresh semantics, not inherit the previously-queued manual
      // reason that was never actually executed.
      final consumed = coordinator.consumePendingReload();
      expect(consumed.force, isFalse);
      expect(consumed.reason, SalesLiveMapReloadReason.autoRefresh);
    },
  );

  test(
    'lastAutoRefreshReloadResult defaults to cancelled until set',
    () {
      expect(coordinator.lastAutoRefreshReloadResult.isCancelled, isTrue);
      coordinator.lastAutoRefreshReloadResult =
          AutoRefreshReloadResult.success(DateTime(2026, 5, 27, 17, 50));
      expect(coordinator.lastAutoRefreshReloadResult.isSuccess, isTrue);
    },
  );

  test(
    'resolveQueuedTickThreshold returns null when scheduling is paused',
    () {
      expect(
        coordinator.resolveQueuedTickThreshold(
          option: null,
          nextDueAt: DateTime(2026, 5, 27, 17, 55),
          now: DateTime(2026, 5, 27, 17, 50),
        ),
        isNull,
      );
      expect(
        coordinator.resolveQueuedTickThreshold(
          option: null,
          nextDueAt: null,
          now: DateTime(2026, 5, 27, 17, 50),
        ),
        isNull,
      );
    },
  );
}
