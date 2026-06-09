import 'package:colmeia/core/refresh/auto_refresh_state_mixin.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_controller.dart';
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
    'classifyControllerReloadOutcome treats salesDataPending as cancelled',
    () {
      final refreshedAt = DateTime(2026, 5, 27, 18);
      final classified = coordinator.classifyControllerReloadOutcome(
        SalesLiveMapReloadOutcome.completed(
          SalesLiveMapLoadResult(
            points: const <SalesLiveMapPoint>[],
            branchOptions: const <SalesLiveMapBranchOption>[],
            totalRevenue: 0,
            totalSalesCount: 0,
            totalBranchCount: 27,
            mappedBranchCount: 0,
            mappedMunicipalityCount: 0,
            queriedAgentCount: 1,
            plannedAgentCount: 1,
            failedAgentCount: 0,
            missingClientTokenAgentCount: 0,
            skippedOfflineAgentCount: 0,
            rowCapReachedAgentCount: 0,
            salesDataPending: true,
            refreshedAt: refreshedAt,
          ),
        ),
      );

      expect(classified.isCancelled, isTrue);
      expect(classified.isSuccess, isFalse);
    },
  );

  test(
    'classifyControllerReloadOutcome records success when sales are loaded',
    () {
      final refreshedAt = DateTime(2026, 5, 27, 18);
      final classified = coordinator.classifyControllerReloadOutcome(
        SalesLiveMapReloadOutcome.completed(
          SalesLiveMapLoadResult(
            points: const <SalesLiveMapPoint>[],
            branchOptions: const <SalesLiveMapBranchOption>[],
            totalRevenue: 100,
            totalSalesCount: 1,
            totalBranchCount: 1,
            mappedBranchCount: 1,
            mappedMunicipalityCount: 1,
            queriedAgentCount: 1,
            plannedAgentCount: 1,
            failedAgentCount: 0,
            missingClientTokenAgentCount: 0,
            skippedOfflineAgentCount: 0,
            rowCapReachedAgentCount: 0,
            refreshedAt: refreshedAt,
          ),
        ),
      );

      expect(classified.isSuccess, isTrue);
      expect(classified.refreshedAt, refreshedAt);
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
    'requestInlineChartLifecycleRecovery bumps inline chart recovery id',
    () {
      expect(coordinator.inlineChartRecoveryRequestId, 0);
      coordinator.requestInlineChartLifecycleRecovery();
      expect(coordinator.inlineChartRecoveryRequestId, 1);
      coordinator.requestInlineChartLifecycleRecovery();
      expect(coordinator.inlineChartRecoveryRequestId, 2);
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
