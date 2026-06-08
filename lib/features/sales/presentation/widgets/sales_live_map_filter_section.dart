import 'dart:async';

import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_controller.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/view_models/sales_live_map_view_model.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_retry_cooldown_snackbar.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesLiveMapFilterSection extends StatelessWidget {
  const SalesLiveMapFilterSection({
    required this.onOpenFilters,
    super.key,
  });

  final Future<void> Function() onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;

    return Selector<SalesLiveMapController, _SalesLiveMapFilterSectionSlice>(
      selector: (_, controller) => _SalesLiveMapFilterSectionSlice.fromState(
        controller.state,
        l10n,
        isOnRetryCooldown: controller.isOnRetryCooldown,
      ),
      builder: (context, slice, _) {
        final controller = context.read<SalesLiveMapController>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SalesCardFilterTrigger(
              onTap: () => unawaited(onOpenFilters()),
              buttonSemanticsLabel: l10n.reportFiltersButton,
              summaryItems: <SalesCardFilterSummaryItem>[
                SalesCardFilterSummaryItem(
                  label: l10n.salesLiveMapAgentsLabel,
                  value: slice.agentsSummary,
                ),
                SalesCardFilterSummaryItem(
                  label: l10n.salesLiveMapPeriodLabel,
                  value: slice.periodSummary,
                ),
                SalesCardFilterSummaryItem(
                  label: l10n.salesLiveMapDetailLabel,
                  value: slice.detailSummary,
                ),
                SalesCardFilterSummaryItem(
                  label: slice.usesMapLabel
                      ? l10n.salesLiveMapMapLabel
                      : l10n.salesLiveMapVisualLabel,
                  value: slice.visualSummary,
                ),
              ],
              enabled: !slice.isLoading && !slice.isOnRetryCooldown,
            ),
            if (slice.hasSelectedBranchFilter ||
                slice.hasNonBranchNonDefaultFilter) ...<Widget>[
              SizedBox(height: tokens.gapSm),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: tokens.gapSm,
                  runSpacing: tokens.gapXs,
                  children: <Widget>[
                    if (slice.hasSelectedBranchFilter)
                      OutlinedButton.icon(
                        onPressed: slice.isLoading || slice.isOnRetryCooldown
                            ? null
                            : () => unawaited(
                                _clearSelectedBranchesWithFeedback(
                                  context,
                                  controller,
                                ),
                              ),
                        icon: const Icon(Icons.storefront_outlined),
                        label: Text(
                          l10n.salesLiveMapClearBranchSelectionAction,
                        ),
                      ),
                    if (slice.hasNonBranchNonDefaultFilter)
                      OutlinedButton.icon(
                        onPressed: slice.isLoading || slice.isOnRetryCooldown
                            ? null
                            : () => unawaited(
                                _clearSavedFiltersWithFeedback(
                                  context,
                                  controller,
                                ),
                              ),
                        icon: const Icon(Icons.filter_alt_off_rounded),
                        label: Text(l10n.salesLiveMapClearSavedFiltersAction),
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _clearSelectedBranchesWithFeedback(
    BuildContext context,
    SalesLiveMapController controller,
  ) async {
    final outcome = await controller.clearSelectedBranches();
    if (!context.mounted) {
      return;
    }
    if (outcome == SalesLiveMapFilterMutationOutcome.blockedByCooldown) {
      showSalesLiveMapRetryCooldownSnackbar(
        context,
        controller.retryAfterGate,
      );
    }
  }

  Future<void> _clearSavedFiltersWithFeedback(
    BuildContext context,
    SalesLiveMapController controller,
  ) async {
    final outcome = await controller.clearSavedFilters();
    if (!context.mounted) {
      return;
    }
    if (outcome == SalesLiveMapFilterMutationOutcome.blockedByCooldown) {
      showSalesLiveMapRetryCooldownSnackbar(
        context,
        controller.retryAfterGate,
      );
    }
  }
}

@immutable
class _SalesLiveMapFilterSectionSlice {
  const _SalesLiveMapFilterSectionSlice({
    required this.agentsSummary,
    required this.periodSummary,
    required this.detailSummary,
    required this.visualSummary,
    required this.usesMapLabel,
    required this.isLoading,
    required this.isOnRetryCooldown,
    required this.hasSelectedBranchFilter,
    required this.hasNonBranchNonDefaultFilter,
  });

  factory _SalesLiveMapFilterSectionSlice.fromState(
    SalesLiveMapPresentationState state,
    AppLocalizations l10n, {
    required bool isOnRetryCooldown,
  }) {
    final viewModel = SalesLiveMapViewModel.fromState(state, l10n);
    return _SalesLiveMapFilterSectionSlice(
      agentsSummary: viewModel.agentsSummary,
      periodSummary: viewModel.periodSummary,
      detailSummary: viewModel.detailSummary,
      visualSummary: viewModel.visualSummary,
      usesMapLabel: viewModel.usesMapLabel,
      isLoading: state.isLoading,
      isOnRetryCooldown: isOnRetryCooldown,
      hasSelectedBranchFilter: state.hasSelectedBranchFilter,
      hasNonBranchNonDefaultFilter: state.hasNonBranchNonDefaultFilter,
    );
  }

  final String agentsSummary;
  final String periodSummary;
  final String detailSummary;
  final String visualSummary;
  final bool usesMapLabel;
  final bool isLoading;
  final bool isOnRetryCooldown;
  final bool hasSelectedBranchFilter;
  final bool hasNonBranchNonDefaultFilter;

  @override
  bool operator ==(Object other) {
    return other is _SalesLiveMapFilterSectionSlice &&
        other.agentsSummary == agentsSummary &&
        other.periodSummary == periodSummary &&
        other.detailSummary == detailSummary &&
        other.visualSummary == visualSummary &&
        other.usesMapLabel == usesMapLabel &&
        other.isLoading == isLoading &&
        other.isOnRetryCooldown == isOnRetryCooldown &&
        other.hasSelectedBranchFilter == hasSelectedBranchFilter &&
        other.hasNonBranchNonDefaultFilter == hasNonBranchNonDefaultFilter;
  }

  @override
  int get hashCode => Object.hash(
    agentsSummary,
    periodSummary,
    detailSummary,
    visualSummary,
    usesMapLabel,
    isLoading,
    isOnRetryCooldown,
    hasSelectedBranchFilter,
    hasNonBranchNonDefaultFilter,
  );
}
