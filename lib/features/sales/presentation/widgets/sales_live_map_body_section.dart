import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_diagnostic.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_error_panel_factory.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
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

    return Selector<SalesLiveMapController, _SalesLiveMapBodyShellSlice>(
      selector: (_, controller) =>
          _SalesLiveMapBodyShellSlice.fromState(controller.state),
      builder: (context, shell, _) {
        if (shell.showInitialSkeleton) {
          return const SalesLiveMapInitialSkeleton();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SalesLiveMapSessionExpiredSection(),
            _SalesLiveMapKpiSection(),
            _SalesLiveMapAttentionSection(onRetryReload: onRetryReload),
            _SalesLiveMapLoadErrorSection(onRetryReload: onRetryReload),
            _SalesLiveMapEmptyNoticeSection(onRetryReload: onRetryReload),
            if (shell.showInlineChartSlot) ...<Widget>[
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

class _SalesLiveMapSessionExpiredSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<SalesLiveMapController, bool>(
      selector: (_, controller) => controller.state.sessionExpired,
      builder: (context, sessionExpired, _) {
        if (!sessionExpired) {
          return const SizedBox.shrink();
        }
        final l10n = AppLocalizations.of(context);
        return _SalesLiveMapSessionExpiredPanel(
          l10n: l10n,
          onSignIn: () => context.goTo(AppRoute.login),
        );
      },
    );
  }
}

class _SalesLiveMapKpiSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<SalesLiveMapController, _SalesLiveMapKpiSlice>(
      selector: (_, controller) =>
          _SalesLiveMapKpiSlice.fromState(controller.state),
      builder: (context, slice, _) {
        final model = slice.model;
        if (model == null || slice.sessionExpired) {
          return const SizedBox.shrink();
        }
        return AppSkeleton(
          enabled: slice.salesDataPending,
          child: SalesLiveMapKpiGrid(model: model),
        );
      },
    );
  }
}

class _SalesLiveMapAttentionSection extends StatelessWidget {
  const _SalesLiveMapAttentionSection({required this.onRetryReload});

  final VoidCallback onRetryReload;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    return Selector<SalesLiveMapController, _SalesLiveMapAttentionSlice>(
      selector: (_, controller) => _SalesLiveMapAttentionSlice.from(
        state: controller.state,
        isOnRetryCooldown: controller.isOnRetryCooldown,
      ),
      builder: (context, slice, _) {
        final result = slice.result;
        if (result == null ||
            slice.sessionExpired ||
            result.salesDataPending ||
            !result.hasPartialIssue) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: EdgeInsets.only(top: tokens.gapMd),
          child: SalesLiveMapAttentionPanel(
            result: result,
            canRetry: slice.canReload,
            onRetry: onRetryReload,
            onConfigureToken: () => context.goTo(AppRoute.agents),
          ),
        );
      },
    );
  }
}

class _SalesLiveMapLoadErrorSection extends StatelessWidget {
  const _SalesLiveMapLoadErrorSection({required this.onRetryReload});

  final VoidCallback onRetryReload;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    return Selector<SalesLiveMapController, _SalesLiveMapLoadErrorSlice>(
      selector: (_, controller) =>
          _SalesLiveMapLoadErrorSlice.fromState(controller.state),
      builder: (context, slice, _) {
        if (slice.sessionExpired || !slice.loadFailed || slice.result == null) {
          return const SizedBox.shrink();
        }
        final l10n = AppLocalizations.of(context);
        final result = slice.result!;
        final controller = context.read<SalesLiveMapController>();
        final loadErrorMessage = SalesLiveMapViewModel.fromState(
          controller.state,
          l10n,
        ).loadErrorMessage;
        return Padding(
          padding: EdgeInsets.only(top: tokens.gapMd),
          child: result.loadFailure != null
              ? _SalesLiveMapRetryCountdownErrorPanel(
                  gate: controller.retryAfterGate,
                  baseCanReload: slice.baseCanReload,
                  onRetryReload: onRetryReload,
                  failure: result.loadFailure!,
                  l10n: l10n,
                )
              : AppInlineErrorPanel(
                  title: l10n.salesLiveMapLoadErrorTitle,
                  message: loadErrorMessage,
                  onRetry: slice.baseCanReload && !controller.isOnRetryCooldown
                      ? onRetryReload
                      : null,
                ),
        );
      },
    );
  }
}

/// Rebuilds only when [RetryAfterGate] ticks so KPI/attention stay idle during
/// the cooldown countdown.
class _SalesLiveMapRetryCountdownErrorPanel extends StatelessWidget {
  const _SalesLiveMapRetryCountdownErrorPanel({
    required this.gate,
    required this.baseCanReload,
    required this.onRetryReload,
    required this.failure,
    required this.l10n,
  });

  final RetryAfterGate gate;
  final bool baseCanReload;
  final VoidCallback onRetryReload;
  final AppFailure failure;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gate,
      builder: (context, _) {
        final seconds = gate.remaining?.inSeconds ?? 0;
        final onCooldown = seconds > 0;
        final allowRetry = baseCanReload && !onCooldown;
        return AgentQueryErrorPanelFactory.fromFailure(
          failure,
          l10n,
          detailsBody: agentQueryFailureTechnicalDetailsBody(
            failure,
            l10n: l10n,
          ),
          onRetry: allowRetry ? onRetryReload : null,
          retryCountdownLabel: onCooldown
              ? l10n.appInlineErrorRetryCountdown(seconds)
              : null,
        );
      },
    );
  }
}

class _SalesLiveMapEmptyNoticeSection extends StatelessWidget {
  const _SalesLiveMapEmptyNoticeSection({required this.onRetryReload});

  final VoidCallback onRetryReload;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    return Selector<SalesLiveMapController, _SalesLiveMapEmptyNoticeSlice>(
      selector: (_, controller) => _SalesLiveMapEmptyNoticeSlice.from(
        state: controller.state,
        isOnRetryCooldown: controller.isOnRetryCooldown,
      ),
      builder: (context, slice, _) {
        if (!slice.show || slice.result == null) {
          return const SizedBox.shrink();
        }
        final l10n = AppLocalizations.of(context);
        final controller = context.read<SalesLiveMapController>();
        return Padding(
          padding: EdgeInsets.only(top: tokens.gapMd),
          child: SalesLiveMapEmptyNotice(
            result: slice.result!,
            hasSelectedBranches: slice.hasSelectedBranchFilter,
            hasPartialIssue: slice.hasPartialIssue,
            onClearSelectedBranches: slice.canReload
                ? () => unawaited(controller.clearSelectedBranches())
                : null,
            l10n: l10n,
          ),
        );
      },
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
class _SalesLiveMapBodyShellSlice {
  const _SalesLiveMapBodyShellSlice({
    required this.showInitialSkeleton,
    required this.showInlineChartSlot,
  });

  factory _SalesLiveMapBodyShellSlice.fromState(
    SalesLiveMapPresentationState state,
  ) {
    return _SalesLiveMapBodyShellSlice(
      showInitialSkeleton: !state.hasVisualResult && state.isLoading,
      showInlineChartSlot:
          !state.sessionExpired &&
          (state.hasVisualResult ||
              SalesLiveMapViewModel.shouldShowChartFailurePlaceholder(state)),
    );
  }

  final bool showInitialSkeleton;
  final bool showInlineChartSlot;

  @override
  bool operator ==(Object other) {
    return other is _SalesLiveMapBodyShellSlice &&
        other.showInitialSkeleton == showInitialSkeleton &&
        other.showInlineChartSlot == showInlineChartSlot;
  }

  @override
  int get hashCode => Object.hash(showInitialSkeleton, showInlineChartSlot);
}

@immutable
class _SalesLiveMapKpiSlice {
  const _SalesLiveMapKpiSlice({
    required this.sessionExpired,
    required this.salesDataPending,
    required this.model,
    required this.fingerprint,
  });

  factory _SalesLiveMapKpiSlice.fromState(SalesLiveMapPresentationState state) {
    final kpiResult =
        SalesLiveMapViewModel.attentionPanelResult(state) ?? state.result;
    return _SalesLiveMapKpiSlice(
      sessionExpired: state.sessionExpired,
      salesDataPending: kpiResult?.salesDataPending ?? false,
      model: kpiResult == null
          ? null
          : SalesLiveMapKpiGridModel.fromLoadResult(kpiResult),
      fingerprint: SalesLiveMapOperationalFingerprint.from(kpiResult),
    );
  }

  final bool sessionExpired;
  final bool salesDataPending;
  final SalesLiveMapKpiGridModel? model;
  final SalesLiveMapOperationalFingerprint fingerprint;

  @override
  bool operator ==(Object other) {
    return other is _SalesLiveMapKpiSlice &&
        other.sessionExpired == sessionExpired &&
        other.salesDataPending == salesDataPending &&
        other.fingerprint == fingerprint;
  }

  @override
  int get hashCode => Object.hash(sessionExpired, salesDataPending, fingerprint);
}

@immutable
class _SalesLiveMapAttentionSlice {
  const _SalesLiveMapAttentionSlice({
    required this.sessionExpired,
    required this.canReload,
    required this.result,
    required this.fingerprint,
  });

  factory _SalesLiveMapAttentionSlice.from({
    required SalesLiveMapPresentationState state,
    required bool isOnRetryCooldown,
  }) {
    final result = SalesLiveMapViewModel.attentionPanelResult(state);
    return _SalesLiveMapAttentionSlice(
      sessionExpired: state.sessionExpired,
      canReload: state.canReload && !isOnRetryCooldown,
      result: result,
      fingerprint: SalesLiveMapOperationalFingerprint.from(result),
    );
  }

  final bool sessionExpired;
  final bool canReload;
  final SalesLiveMapLoadResult? result;
  final SalesLiveMapOperationalFingerprint fingerprint;

  @override
  bool operator ==(Object other) {
    return other is _SalesLiveMapAttentionSlice &&
        other.sessionExpired == sessionExpired &&
        other.canReload == canReload &&
        other.fingerprint == fingerprint;
  }

  @override
  int get hashCode => Object.hash(sessionExpired, canReload, fingerprint);
}

@immutable
class _SalesLiveMapLoadErrorSlice {
  const _SalesLiveMapLoadErrorSlice({
    required this.sessionExpired,
    required this.baseCanReload,
    required this.loadFailed,
    required this.result,
    required this.fingerprint,
  });

  factory _SalesLiveMapLoadErrorSlice.fromState(
    SalesLiveMapPresentationState state,
  ) {
    final result = state.result;
    return _SalesLiveMapLoadErrorSlice(
      sessionExpired: state.sessionExpired,
      baseCanReload: state.canReload,
      loadFailed: result?.loadFailed ?? false,
      result: result,
      fingerprint: SalesLiveMapOperationalFingerprint.from(result),
    );
  }

  final bool sessionExpired;
  final bool baseCanReload;
  final bool loadFailed;
  final SalesLiveMapLoadResult? result;
  final SalesLiveMapOperationalFingerprint fingerprint;

  @override
  bool operator ==(Object other) {
    return other is _SalesLiveMapLoadErrorSlice &&
        other.sessionExpired == sessionExpired &&
        other.baseCanReload == baseCanReload &&
        other.loadFailed == loadFailed &&
        other.fingerprint == fingerprint;
  }

  @override
  int get hashCode => Object.hash(
    sessionExpired,
    baseCanReload,
    loadFailed,
    fingerprint,
  );
}

@immutable
class _SalesLiveMapEmptyNoticeSlice {
  const _SalesLiveMapEmptyNoticeSlice({
    required this.show,
    required this.canReload,
    required this.hasSelectedBranchFilter,
    required this.hasPartialIssue,
    required this.result,
    required this.fingerprint,
  });

  factory _SalesLiveMapEmptyNoticeSlice.from({
    required SalesLiveMapPresentationState state,
    required bool isOnRetryCooldown,
  }) {
    final result = state.result;
    final attention = SalesLiveMapViewModel.attentionPanelResult(state);
    return _SalesLiveMapEmptyNoticeSlice(
      show:
          SalesLiveMapPresentationRules.shouldShowEmptyNotice(state) &&
          result != null &&
          !state.sessionExpired,
      canReload: state.canReload && !isOnRetryCooldown,
      hasSelectedBranchFilter: state.hasSelectedBranchFilter,
      hasPartialIssue: attention?.hasPartialIssue ?? false,
      result: result,
      fingerprint: SalesLiveMapOperationalFingerprint.from(result),
    );
  }

  final bool show;
  final bool canReload;
  final bool hasSelectedBranchFilter;
  final bool hasPartialIssue;
  final SalesLiveMapLoadResult? result;
  final SalesLiveMapOperationalFingerprint fingerprint;

  @override
  bool operator ==(Object other) {
    return other is _SalesLiveMapEmptyNoticeSlice &&
        other.show == show &&
        other.canReload == canReload &&
        other.hasSelectedBranchFilter == hasSelectedBranchFilter &&
        other.hasPartialIssue == hasPartialIssue &&
        other.fingerprint == fingerprint;
  }

  @override
  int get hashCode => Object.hash(
    show,
    canReload,
    hasSelectedBranchFilter,
    hasPartialIssue,
    fingerprint,
  );
}
