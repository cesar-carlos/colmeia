import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/features/sales/presentation/rules/sales_live_map_presentation_rules.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canScheduleAutoRefresh is false when no token-backed agents exist', () {
    const state = SalesLiveMapPresentationState(
      availableAgents: <DashboardAgentOption>[
        DashboardAgentOption(
          agentId: 'agent-1',
          name: 'Agent One',
          missingLocalClientToken: true,
        ),
      ],
      isLoading: false,
    );

    expect(
      SalesLiveMapPresentationRules.canScheduleAutoRefresh(state),
      isFalse,
    );
  });

  test(
    'shouldShowEmptyNotice is true when totalSalesCount is zero with partial issue',
    () {
      final state = SalesLiveMapPresentationState(
        result: _resultWithBranches(
          branchOptions: const <SalesLiveMapBranchOption>[
            SalesLiveMapBranchOption(
              id: 'b1',
              agentId: 'a1',
              agentName: 'One',
              codEmpresa: 1,
              codFilial: 1,
              registrationName: 'Filial 1',
              city: 'City',
              uf: 'SP',
            ),
          ],
          totalBranchCount: 1,
          failedAgentCount: 1,
        ),
        isLoading: false,
      );

      expect(
        SalesLiveMapPresentationRules.shouldShowEmptyNotice(state),
        isTrue,
      );
    },
  );

  test('effectiveDetailLevel downgrades branches when mapped count exceeds threshold', () {
    final state = SalesLiveMapPresentationState(
      result: _resultWithBranches(
        branchOptions: const <SalesLiveMapBranchOption>[],
        totalBranchCount: 250,
        mappedBranchCount: 250,
      ),
      isLoading: false,
    );

    expect(
      SalesLiveMapPresentationRules.effectiveDetailLevel(state),
      SalesLiveMapMapDetail.municipalities,
    );
  });

  test('visualSpec follows effectiveDetailLevel downgrade', () {
    final state = SalesLiveMapPresentationState(
      filter: const SalesLiveMapFilter(
        markerVisual: SalesLiveMapMarkerVisual.storeIcon,
      ),
      result: _resultWithBranches(
        branchOptions: const <SalesLiveMapBranchOption>[],
        totalBranchCount: 250,
        mappedBranchCount: 250,
      ),
      isLoading: false,
    );

    final spec = SalesLiveMapPresentationRules.visualSpec(state);

    expect(spec.detailLevel, SalesLiveMapMapDetail.municipalities);
    expect(spec.markerVisual, SalesLiveMapMarkerVisual.storeIcon);
  });
}

SalesLiveMapLoadResult _resultWithBranches({
  required List<SalesLiveMapBranchOption> branchOptions,
  required int totalBranchCount,
  List<SalesLiveMapPoint> points = const <SalesLiveMapPoint>[],
  int mappedBranchCount = 0,
  int failedAgentCount = 0,
}) {
  return SalesLiveMapLoadResult(
    points: points,
    branchOptions: branchOptions,
    totalRevenue: 0,
    totalSalesCount: 0,
    totalBranchCount: totalBranchCount,
    mappedBranchCount: mappedBranchCount,
    mappedMunicipalityCount: mappedBranchCount,
    queriedAgentCount: 5,
    plannedAgentCount: 27,
    failedAgentCount: failedAgentCount,
    missingClientTokenAgentCount: 0,
    skippedOfflineAgentCount: 0,
    rowCapReachedAgentCount: 0,
    refreshedAt: DateTime(2026, 5, 27),
  );
}
