import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_result.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_option.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_live_map_auto_refresh_observer.dart';
import 'package:colmeia/features/sales/presentation/coordinators/sales_live_map_session_coordinator.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SalesLiveMapSessionCoordinator coordinator;
  late List<DateTime> recordedReloads;
  late List<bool> scheduleNextCycleFlags;
  late int schedulingRefreshCount;
  late int closeFullscreenCount;
  late SalesLiveMapAutoRefreshObserver observer;

  final refreshedAt = DateTime(2026, 5, 27, 17, 50);
  final now = DateTime(2026, 5, 27, 17, 55);
  final nextDueAt = DateTime(2026, 5, 27, 17, 45);

  setUp(() {
    coordinator = SalesLiveMapSessionCoordinator();
    recordedReloads = <DateTime>[];
    scheduleNextCycleFlags = <bool>[];
    schedulingRefreshCount = 0;
    closeFullscreenCount = 0;
    observer = SalesLiveMapAutoRefreshObserver(
      coordinator: coordinator,
      readAutoRefreshOption: () => SalesLiveMapAutoRefreshOptions.fifteenMinutes,
      readAutoRefreshNextDueAt: () => nextDueAt,
      readCurrentAutoRefreshTime: () => now,
      readAutoRefreshReloadInProgress: () => false,
      refreshAutoRefreshScheduling: () => schedulingRefreshCount += 1,
      recordAutoRefreshSuccessfulReload: (refreshedAt, {required scheduleNextCycle}) {
        recordedReloads.add(refreshedAt);
        scheduleNextCycleFlags.add(scheduleNextCycle);
      },
      onCloseFullscreenRequested: () => closeFullscreenCount += 1,
    );
  });

  test('sets queued tick threshold when controller enters loading', () {
    observer.onControllerChanged(
      const SalesLiveMapPresentationState(),
    );

    expect(coordinator.wasControllerLoading, isTrue);
    expect(
      coordinator.controllerReloadQueuedTickThreshold,
      nextDueAt.add(SalesLiveMapAutoRefreshOptions.fifteenMinutes.duration),
    );
  });

  test('does not set queued tick threshold when auto-refresh reload is active', () {
    observer = SalesLiveMapAutoRefreshObserver(
      coordinator: coordinator,
      readAutoRefreshOption: () => SalesLiveMapAutoRefreshOptions.fifteenMinutes,
      readAutoRefreshNextDueAt: () => nextDueAt,
      readCurrentAutoRefreshTime: () => now,
      readAutoRefreshReloadInProgress: () => true,
      refreshAutoRefreshScheduling: () => schedulingRefreshCount += 1,
      recordAutoRefreshSuccessfulReload: (_, {required scheduleNextCycle}) {},
      onCloseFullscreenRequested: () {},
    )..onControllerChanged(
      const SalesLiveMapPresentationState(),
    );

    expect(coordinator.controllerReloadQueuedTickThreshold, isNull);
  });

  test('clears queued tick threshold when scheduling becomes unavailable', () {
    coordinator.controllerReloadQueuedTickThreshold = now;

    observer.onControllerChanged(
      const SalesLiveMapPresentationState(
        availableAgents: <DashboardAgentOption>[
          DashboardAgentOption(
            agentId: 'agent-1',
            name: 'Agent One',
            missingLocalClientToken: true,
          ),
        ],
        isLoading: false,
      ),
    );

    expect(coordinator.controllerReloadQueuedTickThreshold, isNull);
  });

  test('refreshes scheduling when scheduling slice changes', () {
    observer
      ..onControllerChanged(
        const SalesLiveMapPresentationState(),
      )
      ..onControllerChanged(
        const SalesLiveMapPresentationState(isLoading: false),
      );

    expect(schedulingRefreshCount, 2);
    expect(coordinator.lastSchedulingSlice?.isLoading, isFalse);
  });

  test('records successful reload and clears queued threshold', () {
    coordinator
      ..controllerReloadQueuedTickThreshold = now
      ..wasControllerLoading = true;

    observer.onControllerChanged(
      SalesLiveMapPresentationState(
        result: _loadedResult(refreshedAt: refreshedAt),
        isLoading: false,
      ),
    );

    expect(recordedReloads, <DateTime>[refreshedAt]);
    expect(scheduleNextCycleFlags, <bool>[true]);
    expect(coordinator.lastRecordedSuccessfulRefreshAt, refreshedAt);
    expect(coordinator.controllerReloadQueuedTickThreshold, isNull);
  });

  test(
    'defers next auto-refresh cycle when reload crossed queued tick threshold',
    () {
      coordinator
        ..controllerReloadQueuedTickThreshold = now.subtract(
          const Duration(minutes: 1),
        )
        ..wasControllerLoading = true;

      observer.onControllerChanged(
        SalesLiveMapPresentationState(
          availableAgents: const <DashboardAgentOption>[
            DashboardAgentOption(agentId: 'agent-1', name: 'Agent One'),
          ],
          result: _loadedResult(refreshedAt: refreshedAt),
          isLoading: false,
        ),
      );

      expect(scheduleNextCycleFlags, <bool>[false]);
    },
  );

  test('clears last recorded refresh while loading', () {
    coordinator.lastRecordedSuccessfulRefreshAt = refreshedAt;

    observer.onControllerChanged(
      const SalesLiveMapPresentationState(),
    );

    expect(coordinator.lastRecordedSuccessfulRefreshAt, isNull);
  });

  test('invokes close fullscreen when request id changes', () {
    observer.onControllerChanged(
      const SalesLiveMapPresentationState(closeFullscreenRequestId: 3),
    );

    expect(closeFullscreenCount, 1);
    expect(coordinator.lastCloseFullscreenRequestId, 3);
  });
}

SalesLiveMapLoadResult _loadedResult({required DateTime refreshedAt}) {
  return SalesLiveMapLoadResult(
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
  );
}
