import 'package:colmeia/core/refresh/auto_refresh_ui_state.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/view_models/sales_live_map_view_model.dart';
import 'package:colmeia/l10n/app_localizations_pt.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  final l10n = AppLocalizationsPt();

  test(
    'agentsSummary uses totalBranchCount for implicit all, not partial '
    'branchOptions',
    () {
      final state = SalesLiveMapPresentationState(
        availableAgents: const <DashboardAgentOption>[
          DashboardAgentOption(agentId: 'a1', name: 'One'),
          DashboardAgentOption(agentId: 'a2', name: 'Two'),
        ],
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
          totalBranchCount: 27,
        ),
        isLoading: false,
      );

      final viewModel = SalesLiveMapViewModel.fromState(state, l10n);

      expect(viewModel.agentsSummary, 'Todas (27)');
    },
  );

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

      expect(SalesLiveMapViewModel.shouldShowEmptyNotice(state), isTrue);
    },
  );

  test('shouldShowEmptyNotice is false when load failed', () {
    final state = SalesLiveMapPresentationState(
      result: _resultWithBranches(
        branchOptions: const <SalesLiveMapBranchOption>[],
        totalBranchCount: 0,
        loadFailed: true,
      ),
      isLoading: false,
    );

    expect(SalesLiveMapViewModel.shouldShowEmptyNotice(state), isFalse);
  });

  test(
    'attentionPanelResult returns operational when geo is not regressed',
    () {
      final result = _resultWithBranches(
        branchOptions: const <SalesLiveMapBranchOption>[],
        totalBranchCount: 2,
        mappedBranchCount: 2,
      );
      final state = SalesLiveMapPresentationState(
        result: result,
        visualResult: result,
        isLoading: false,
      );

      expect(SalesLiveMapViewModel.attentionPanelResult(state), same(result));
    },
  );

  test(
    'attentionPanelResult preserves geo fields when operational regresses',
    () {
      final visual = _resultWithBranches(
        branchOptions: const <SalesLiveMapBranchOption>[],
        totalBranchCount: 2,
        mappedBranchCount: 2,
        points: const <SalesLiveMapPoint>[
          SalesLiveMapPoint(
            id: 'branch-1',
            name: 'Branch',
            latitude: -23.5,
            longitude: -46.6,
            uf: 'SP',
            salesAmount: 100,
            salesCount: 1,
          ),
          SalesLiveMapPoint(
            id: 'branch-2',
            name: 'Branch 2',
            latitude: -22.9,
            longitude: -47,
            uf: 'SP',
            salesAmount: 200,
            salesCount: 2,
          ),
        ],
      );
      final operational = SalesLiveMapLoadResult(
        points: const <SalesLiveMapPoint>[],
        branchOptions: visual.branchOptions,
        totalRevenue: visual.totalRevenue,
        totalSalesCount: visual.totalSalesCount,
        totalBranchCount: visual.totalBranchCount,
        mappedBranchCount: 0,
        mappedMunicipalityCount: 0,
        queriedAgentCount: visual.queriedAgentCount,
        plannedAgentCount: visual.plannedAgentCount,
        failedAgentCount: 1,
        missingClientTokenAgentCount: 0,
        skippedOfflineAgentCount: 0,
        rowCapReachedAgentCount: 0,
        refreshedAt: visual.refreshedAt,
      );
      final state = SalesLiveMapPresentationState(
        result: operational,
        visualResult: visual,
        isLoading: false,
      );

      final aligned = SalesLiveMapViewModel.attentionPanelResult(state);

      expect(aligned?.mappedBranchCount, 2);
      expect(aligned?.points, visual.points);
      expect(aligned?.failedAgentCount, 1);
    },
  );

  test(
    'resolveAutoRefreshPauseReason pauses while retry cooldown is active',
    () {
      const state = SalesLiveMapPresentationState(
        availableAgents: <DashboardAgentOption>[
          DashboardAgentOption(agentId: 'a1', name: 'One'),
        ],
        isLoading: false,
      );

      expect(
        SalesLiveMapViewModel.resolveAutoRefreshPauseReason(
          state,
          isOnRetryCooldown: true,
        ),
        AutoRefreshPauseReason.pageLoading,
      );
      expect(
        SalesLiveMapViewModel.resolveAutoRefreshPauseReason(state),
        isNull,
      );
    },
  );
}

SalesLiveMapLoadResult _resultWithBranches({
  required List<SalesLiveMapBranchOption> branchOptions,
  required int totalBranchCount,
  List<SalesLiveMapPoint> points = const <SalesLiveMapPoint>[],
  int mappedBranchCount = 0,
  int failedAgentCount = 0,
  bool loadFailed = false,
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
    loadFailed: loadFailed,
    refreshedAt: DateTime(2026, 5, 27),
  );
}
