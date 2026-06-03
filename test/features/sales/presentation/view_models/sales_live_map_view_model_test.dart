import 'package:colmeia/core/refresh/auto_refresh_ui_state.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
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
}) {
  return SalesLiveMapLoadResult(
    points: const [],
    branchOptions: branchOptions,
    totalRevenue: 0,
    totalSalesCount: 0,
    totalBranchCount: totalBranchCount,
    mappedBranchCount: 0,
    mappedMunicipalityCount: 0,
    queriedAgentCount: 5,
    plannedAgentCount: 27,
    failedAgentCount: 0,
    missingClientTokenAgentCount: 0,
    skippedOfflineAgentCount: 0,
    rowCapReachedAgentCount: 0,
    refreshedAt: DateTime(2026, 5, 27),
  );
}
