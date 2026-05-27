import 'dart:async';

import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_controller.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/view_models/sales_live_map_view_model.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
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

    return Selector<SalesLiveMapController, SalesLiveMapPresentationState>(
      selector: (_, controller) => controller.state,
      builder: (context, state, _) {
        final controller = context.read<SalesLiveMapController>();
        final viewModel = SalesLiveMapViewModel.fromState(state, l10n);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SalesCardFilterTrigger(
              onTap: () => unawaited(onOpenFilters()),
              buttonSemanticsLabel: l10n.reportFiltersButton,
              summaryItems: <SalesCardFilterSummaryItem>[
                SalesCardFilterSummaryItem(
                  label: l10n.salesLiveMapAgentsLabel,
                  value: viewModel.agentsSummary,
                ),
                SalesCardFilterSummaryItem(
                  label: l10n.salesLiveMapPeriodLabel,
                  value: viewModel.periodSummary,
                ),
                SalesCardFilterSummaryItem(
                  label: l10n.salesLiveMapDetailLabel,
                  value: viewModel.detailSummary,
                ),
                SalesCardFilterSummaryItem(
                  label: viewModel.usesMapLabel
                      ? l10n.salesLiveMapMapLabel
                      : l10n.salesLiveMapVisualLabel,
                  value: viewModel.visualSummary,
                ),
              ],
              enabled: !state.isLoading,
            ),
            if (state.hasSelectedBranchFilter ||
                state.hasNonBranchNonDefaultFilter) ...<Widget>[
              SizedBox(height: tokens.gapSm),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: tokens.gapSm,
                  runSpacing: tokens.gapXs,
                  children: <Widget>[
                    if (state.hasSelectedBranchFilter)
                      OutlinedButton.icon(
                        onPressed: state.isLoading
                            ? null
                            : () => unawaited(
                                controller.clearSelectedBranches(),
                              ),
                        icon: const Icon(Icons.storefront_outlined),
                        label: Text(
                          l10n.salesLiveMapClearBranchSelectionAction,
                        ),
                      ),
                    if (state.hasNonBranchNonDefaultFilter)
                      OutlinedButton.icon(
                        onPressed: state.isLoading
                            ? null
                            : () => unawaited(controller.clearSavedFilters()),
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
}
