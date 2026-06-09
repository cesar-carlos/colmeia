import 'dart:async';

import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_option.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_progressive_stream_handler.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const handler = SalesLiveMapProgressiveStreamHandler();

  test(
    'returns cancelled outcome and clears loading when stream emits cancelled',
    () async {
      final cancelToken = SalesLiveMapLoadCancelToken();
      var state = const SalesLiveMapPresentationState();
      var clearedCancelToken = false;

      final outcome = await handler.handle(
        stream: Stream<SalesLiveMapLoadResult>.value(
          SalesLiveMapLoadResult(
            points: const <SalesLiveMapPoint>[],
            branchOptions: const <SalesLiveMapBranchOption>[],
            totalRevenue: 0,
            totalSalesCount: 0,
            totalBranchCount: 0,
            mappedBranchCount: 0,
            mappedMunicipalityCount: 0,
            queriedAgentCount: 0,
            plannedAgentCount: 0,
            failedAgentCount: 0,
            missingClientTokenAgentCount: 0,
            skippedOfflineAgentCount: 0,
            rowCapReachedAgentCount: 0,
            cancelled: true,
            refreshedAt: DateTime(2026, 5, 9, 12),
          ),
        ),
        session: SalesLiveMapProgressiveStreamSession(
          preservedVisualResult: null,
          cancelToken: cancelToken,
          isGenerationStale: () => false,
          readState: () => state,
          applyState: (nextState) => state = nextState,
          clearActiveCancelTokenIfMatching: () => clearedCancelToken = true,
          onLoadResultReceived: (_) {},
          rehydrateAvailableAgents: (_) => null,
        ),
      );

      expect(outcome.isCancelled, isTrue);
      expect(state.isLoading, isFalse);
      expect(clearedCancelToken, isTrue);
    },
  );

  test(
    'returns superseded outcome when generation becomes stale mid-stream',
    () async {
      final stream = StreamController<SalesLiveMapLoadResult>();
      addTearDown(stream.close);
      var stale = false;
      var state = const SalesLiveMapPresentationState();

      final outcomeFuture = handler.handle(
        stream: stream.stream,
        session: SalesLiveMapProgressiveStreamSession(
          preservedVisualResult: null,
          cancelToken: SalesLiveMapLoadCancelToken(),
          isGenerationStale: () => stale,
          readState: () => state,
          applyState: (nextState) => state = nextState,
          clearActiveCancelTokenIfMatching: () {},
          onLoadResultReceived: (_) {},
          rehydrateAvailableAgents: (_) => null,
        ),
      );

      stale = true;
      stream.add(_resultForRevenue(10));
      await stream.close();

      expect((await outcomeFuture).isSuperseded, isTrue);
    },
  );

  test(
    'clears loading when stream completes without emissions',
    () async {
      var state = const SalesLiveMapPresentationState();
      var clearedCancelToken = false;

      final outcome = await handler.handle(
        stream: const Stream<SalesLiveMapLoadResult>.empty(),
        session: SalesLiveMapProgressiveStreamSession(
          preservedVisualResult: null,
          cancelToken: SalesLiveMapLoadCancelToken(),
          isGenerationStale: () => false,
          readState: () => state,
          applyState: (nextState) => state = nextState,
          clearActiveCancelTokenIfMatching: () => clearedCancelToken = true,
          onLoadResultReceived: (_) {},
          rehydrateAvailableAgents: (_) => null,
        ),
      );

      expect(outcome.isCompleted, isTrue);
      expect(state.isLoading, isFalse);
      expect(clearedCancelToken, isTrue);
    },
  );
}

SalesLiveMapLoadResult _resultForRevenue(double revenue) {
  return SalesLiveMapLoadResult(
    points: <SalesLiveMapPoint>[
      SalesLiveMapPoint(
        id: 'agent-1-1-1',
        name: 'Branch One',
        uf: 'MT',
        latitude: -15.60,
        longitude: -56.10,
        salesAmount: revenue,
        salesCount: revenue.round(),
        city: 'Cuiaba',
      ),
    ],
    branchOptions: const <SalesLiveMapBranchOption>[],
    totalRevenue: revenue,
    totalSalesCount: revenue.round(),
    totalBranchCount: 1,
    mappedBranchCount: 1,
    mappedMunicipalityCount: 1,
    queriedAgentCount: 1,
    plannedAgentCount: 1,
    failedAgentCount: 0,
    missingClientTokenAgentCount: 0,
    skippedOfflineAgentCount: 0,
    rowCapReachedAgentCount: 0,
    refreshedAt: DateTime(2026, 5, 9, 12),
  );
}
