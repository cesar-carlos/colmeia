import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_diagnostic.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_controller.dart';
import 'package:colmeia/features/sales/presentation/rules/sales_live_map_presentation_rules.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_operational_fingerprint.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/view_models/sales_live_map_view_model.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_attention_panel.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_empty_notice.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_initial_skeleton.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_inline_chart_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_kpi_grid.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/agent_query_error_panel.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesLiveMapBodySection extends StatelessWidget {
  const SalesLiveMapBodySection({
    required this.onRetryReload,
    required this.onOpenFullscreen,
    required this.hideInlineChart,
    required this.inlineChartRecoveryRequestId,
    this.onRequestShare,
    super.key,
  });

  final VoidCallback onRetryReload;
  final VoidCallback onOpenFullscreen;
  final AppChartShareRequestCallback? onRequestShare;
  final bool hideInlineChart;
  final int inlineChartRecoveryRequestId;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;

    return Selector<SalesLiveMapController, _SalesLiveMapBodyStatusSlice>(
      selector: (_, controller) => _SalesLiveMapBodyStatusSlice.from(
        state: controller.state,
        retryRemainingSeconds:
            controller.retryAfterGate.remaining?.inSeconds ?? 0,
      ),
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
            if (!slice.state.sessionExpired &&
                (slice.state.hasVisualResult ||
                    SalesLiveMapViewModel.shouldShowChartFailurePlaceholder(
                      slice.state,
                    ))) ...<Widget>[
              SizedBox(height: tokens.sectionSpacing),
              Offstage(
                offstage: hideInlineChart,
                child: SalesLiveMapInlineChartSection(
                  recoveryRequestId: inlineChartRecoveryRequestId,
                  suspendParentScrollLock: hideInlineChart,
                  onOpenFullscreen: onOpenFullscreen,
                  onRequestShare: onRequestShare,
                ),
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
    final kpiResult =
        SalesLiveMapViewModel.attentionPanelResult(state) ?? result;
    final attentionResult = SalesLiveMapViewModel.attentionPanelResult(state);
    final viewModel = SalesLiveMapViewModel.fromState(state, l10n);
    final retryCountdown = slice.retryCountdownLabel(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (state.sessionExpired)
          _SalesLiveMapSessionExpiredPanel(
            l10n: l10n,
            onSignIn: () => context.goTo(AppRoute.login),
          ),
        if (kpiResult != null && !state.sessionExpired)
          AppSkeleton(
            enabled: kpiResult.salesDataPending,
            child: SalesLiveMapKpiGrid(
              model: SalesLiveMapKpiGridModel.fromLoadResult(kpiResult),
            ),
          ),
        if (attentionResult != null &&
            !state.sessionExpired &&
            !attentionResult.salesDataPending &&
            attentionResult.hasPartialIssue)
          Padding(
            padding: EdgeInsets.only(top: tokens.gapMd),
            child: SalesLiveMapAttentionPanel(
              result: attentionResult,
              canRetry: slice.canReload,
              onRetry: onRetryReload,
              onConfigureToken: () => context.goTo(AppRoute.agents),
            ),
          ),
        if (!state.sessionExpired && (result?.loadFailed ?? false))
          Padding(
            padding: EdgeInsets.only(top: tokens.gapMd),
            child: result!.loadFailure != null
                ? AgentQueryErrorPanel.fromFailure(
                    result.loadFailure!,
                    l10n,
                    detailsBody: agentQueryFailureTechnicalDetailsBody(
                      result.loadFailure!,
                      l10n: l10n,
                    ),
                    onRetry: slice.canReload ? onRetryReload : null,
                    retryCountdownLabel: retryCountdown,
                  )
                : AppInlineErrorPanel(
                    title: l10n.salesLiveMapLoadErrorTitle,
                    message: viewModel.loadErrorMessage,
                    onRetry: slice.canReload ? onRetryReload : null,
                  ),
          ),
        if (SalesLiveMapPresentationRules.shouldShowEmptyNotice(state) &&
            result != null &&
            !state.sessionExpired)
          Padding(
            padding: EdgeInsets.only(top: tokens.gapMd),
            child: SalesLiveMapEmptyNotice(
              result: result,
              hasSelectedBranches: state.hasSelectedBranchFilter,
              hasPartialIssue: attentionResult?.hasPartialIssue ?? false,
              onClearSelectedBranches: slice.canReload
                  ? () => unawaited(controller.clearSelectedBranches())
                  : null,
              l10n: l10n,
            ),
          ),
      ],
    );
  }
}

class _SalesLiveMapSessionExpiredPanel extends StatelessWidget {
  const _SalesLiveMapSessionExpiredPanel({
    required this.l10n,
    required this.onSignIn,
  });

  final AppLocalizations l10n;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return AppInlineErrorPanel(
      title: l10n.salesLiveMapSessionExpiredTitle,
      message: l10n.salesLiveMapSessionExpiredMessage,
      actions: Align(
        alignment: Alignment.centerLeft,
        child: AppPrimaryButton(
          label: l10n.salesLiveMapSessionExpiredAction,
          icon: const Icon(Icons.login_rounded),
          onPressed: onSignIn,
        ),
      ),
    );
  }
}

@immutable
class _SalesLiveMapBodyStatusSlice {
  const _SalesLiveMapBodyStatusSlice({
    required this.state,
    required this.showInitialSkeleton,
    required this.canReload,
    required this.retryRemainingSeconds,
    required this.operational,
    required this.visualOperational,
  });

  factory _SalesLiveMapBodyStatusSlice.from({
    required SalesLiveMapPresentationState state,
    required int retryRemainingSeconds,
  }) {
    final onCooldown = retryRemainingSeconds > 0;
    return _SalesLiveMapBodyStatusSlice(
      state: state,
      showInitialSkeleton: !state.hasVisualResult && state.isLoading,
      canReload: state.canReload && !onCooldown,
      retryRemainingSeconds: retryRemainingSeconds,
      operational: SalesLiveMapOperationalFingerprint.from(state.result),
      visualOperational: SalesLiveMapOperationalFingerprint.from(
        state.visualResult,
      ),
    );
  }

  final SalesLiveMapPresentationState state;
  final bool showInitialSkeleton;
  final bool canReload;
  final int retryRemainingSeconds;
  final SalesLiveMapOperationalFingerprint operational;
  final SalesLiveMapOperationalFingerprint visualOperational;

  String? retryCountdownLabel(AppLocalizations l10n) {
    if (retryRemainingSeconds <= 0) {
      return null;
    }
    return l10n.appInlineErrorRetryCountdown(retryRemainingSeconds);
  }

  @override
  bool operator ==(Object other) {
    return other is _SalesLiveMapBodyStatusSlice &&
        other.state.hasVisualResult == state.hasVisualResult &&
        other.state.isLoading == state.isLoading &&
        other.state.sessionExpired == state.sessionExpired &&
        other.state.canReload == state.canReload &&
        other.state.hasSelectedBranchFilter == state.hasSelectedBranchFilter &&
        other.showInitialSkeleton == showInitialSkeleton &&
        other.canReload == canReload &&
        other.retryRemainingSeconds == retryRemainingSeconds &&
        other.operational == operational &&
        other.visualOperational == visualOperational;
  }

  @override
  int get hashCode => Object.hash(
    state.hasVisualResult,
    state.isLoading,
    state.sessionExpired,
    state.canReload,
    state.hasSelectedBranchFilter,
    showInitialSkeleton,
    canReload,
    retryRemainingSeconds,
    operational,
    visualOperational,
  );
}
