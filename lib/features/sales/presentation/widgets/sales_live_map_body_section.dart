import 'dart:async';

import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_controller.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/view_models/sales_live_map_view_model.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_attention_panel.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_empty_notice.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_initial_skeleton.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_inline_chart_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_kpi_grid.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesLiveMapBodySection extends StatelessWidget {
  const SalesLiveMapBodySection({
    required this.onRetryReload,
    required this.onOpenFullscreen,
    required this.showInlineChart,
    super.key,
  });

  final VoidCallback onRetryReload;
  final VoidCallback onOpenFullscreen;
  final bool showInlineChart;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;

    return Selector<SalesLiveMapController, _SalesLiveMapBodyStatusSlice>(
      selector: (_, controller) =>
          _SalesLiveMapBodyStatusSlice.fromState(controller.state),
      builder: (context, slice, _) {
        if (slice.showInitialSkeleton) {
          return const SalesLiveMapInitialSkeleton();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SalesLiveMapBodyStatusContent(
              slice: slice,
              onRetryReload: onRetryReload,
            ),
            if (showInlineChart) ...<Widget>[
              SizedBox(height: tokens.sectionSpacing),
              SalesLiveMapInlineChartSection(
                onOpenFullscreen: onOpenFullscreen,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SalesLiveMapBodyStatusContent extends StatelessWidget {
  const _SalesLiveMapBodyStatusContent({
    required this.slice,
    required this.onRetryReload,
  });

  final _SalesLiveMapBodyStatusSlice slice;
  final VoidCallback onRetryReload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;
    final controller = context.read<SalesLiveMapController>();
    final state = slice.state;
    final result = state.result;
    final viewModel = SalesLiveMapViewModel.fromState(state, l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (result != null)
          AppSkeleton(
            enabled: result.salesDataPending,
            child: SalesLiveMapKpiGrid(result: result),
          ),
        if (result != null &&
            !result.salesDataPending &&
            result.hasPartialIssue)
          Padding(
            padding: EdgeInsets.only(top: tokens.gapMd),
            child: SalesLiveMapAttentionPanel(result: result),
          ),
        if (result?.loadFailed ?? false)
          Padding(
            padding: EdgeInsets.only(top: tokens.gapMd),
            child: AppInlineErrorPanel(
              title: l10n.salesLiveMapLoadErrorTitle,
              message: viewModel.loadErrorMessage,
              onRetry: state.canReload ? onRetryReload : null,
            ),
          ),
        if (state.shouldShowEmptyNotice && result != null)
          Padding(
            padding: EdgeInsets.only(top: tokens.gapMd),
            child: SalesLiveMapEmptyNotice(
              result: result,
              hasSelectedBranches: state.hasSelectedBranchFilter,
              onClearSelectedBranches: () => unawaited(
                controller.clearSelectedBranches(),
              ),
              l10n: l10n,
            ),
          ),
      ],
    );
  }
}

@immutable
class _SalesLiveMapBodyStatusSlice {
  const _SalesLiveMapBodyStatusSlice({
    required this.state,
    required this.showInitialSkeleton,
  });

  factory _SalesLiveMapBodyStatusSlice.fromState(
    SalesLiveMapPresentationState state,
  ) {
    return _SalesLiveMapBodyStatusSlice(
      state: state,
      showInitialSkeleton: !state.hasVisualResult && state.isLoading,
    );
  }

  final SalesLiveMapPresentationState state;
  final bool showInitialSkeleton;

  @override
  bool operator ==(Object other) {
    return other is _SalesLiveMapBodyStatusSlice &&
        identical(other.state.result, state.result) &&
        other.state.isLoading == state.isLoading &&
        other.state.sessionExpired == state.sessionExpired &&
        other.state.canReload == state.canReload &&
        other.state.hasSelectedBranchFilter == state.hasSelectedBranchFilter &&
        other.showInitialSkeleton == showInitialSkeleton;
  }

  @override
  int get hashCode => Object.hash(
    identityHashCode(state.result),
    state.isLoading,
    state.sessionExpired,
    state.canReload,
    state.hasSelectedBranchFilter,
    showInitialSkeleton,
  );
}
