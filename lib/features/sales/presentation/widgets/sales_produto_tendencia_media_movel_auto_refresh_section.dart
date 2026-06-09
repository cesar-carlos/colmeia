import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:colmeia/core/refresh/auto_refresh_ui_state.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_produto_tendencia_media_movel_controller.dart';
import 'package:colmeia/features/sales/presentation/state/sales_produto_tendencia_media_movel_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_auto_refresh_actions_row.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesProdutoTendenciaMediaMovelAutoRefreshSection extends StatelessWidget {
  const SalesProdutoTendenciaMediaMovelAutoRefreshSection({
    required this.onOptionChanged,
    required this.onRefreshNow,
    required this.stateListenable,
    super.key,
  });

  final ValueChanged<AutoRefreshOption?> onOptionChanged;
  final VoidCallback onRefreshNow;
  final ValueListenable<AutoRefreshUiState> stateListenable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final autoRefreshSupported = salesAutoRefreshIsAvailableForViewport(context);

    return ValueListenableBuilder<AutoRefreshUiState>(
      valueListenable: stateListenable,
      builder: (context, refreshState, _) {
        return Selector<SalesProdutoTendenciaMediaMovelController,
            _SalesProdutoTendenciaMediaMovelAutoRefreshSlice>(
          selector: (_, controller) =>
              _SalesProdutoTendenciaMediaMovelAutoRefreshSlice.from(
                controller.state,
              ),
          builder: (context, slice, _) {
            return SalesAutoRefreshActionsRow(
              value: refreshState.option,
              onChanged: onOptionChanged,
              onRefreshNow: onRefreshNow,
              enabled: slice.canScheduleAutoRefresh,
              lastUpdatedAt: refreshState.lastUpdatedAt,
              nextDueAt: autoRefreshSupported ? refreshState.nextDueAt : null,
              isBackingOff: refreshState.isBackingOff,
              isPaused: refreshState.isPaused,
              pauseReason: refreshState.pauseReason,
              l10n: l10n,
            );
          },
        );
      },
    );
  }
}

@immutable
class _SalesProdutoTendenciaMediaMovelAutoRefreshSlice {
  const _SalesProdutoTendenciaMediaMovelAutoRefreshSlice({
    required this.canScheduleAutoRefresh,
  });

  factory _SalesProdutoTendenciaMediaMovelAutoRefreshSlice.from(
    SalesProdutoTendenciaMediaMovelPresentationState state,
  ) {
    return _SalesProdutoTendenciaMediaMovelAutoRefreshSlice(
      canScheduleAutoRefresh: _canScheduleAutoRefresh(state),
    );
  }

  final bool canScheduleAutoRefresh;

  static bool _canScheduleAutoRefresh(
    SalesProdutoTendenciaMediaMovelPresentationState state,
  ) {
    if (state.loading) {
      return false;
    }
    final selectedAgentId = state.selectedAgentId?.trim();
    if (selectedAgentId == null || selectedAgentId.isEmpty) {
      return false;
    }
    DashboardAgentOption? selectedAgent;
    for (final agent in state.availableAgents) {
      if (agent.agentId == selectedAgentId) {
        selectedAgent = agent;
        break;
      }
    }
    if (selectedAgent == null) {
      return false;
    }
    return !selectedAgent.missingLocalClientToken;
  }

  @override
  bool operator ==(Object other) {
    return other is _SalesProdutoTendenciaMediaMovelAutoRefreshSlice &&
        other.canScheduleAutoRefresh == canScheduleAutoRefresh;
  }

  @override
  int get hashCode => canScheduleAutoRefresh.hashCode;
}
