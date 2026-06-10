import 'dart:async';

import 'package:colmeia/app/preferences/app_user_experience_preferences_controller.dart';
import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_controller.dart';
import 'package:colmeia/features/overview/presentation/localization/overview_failure_l10n.dart';
import 'package:colmeia/features/overview/presentation/localization/overview_load_labels_l10n.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_auto_loader.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_nav_grid.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_filter_bar.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_filter_period_chip.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_home_alerts_section.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_home_charts_below_kpis.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_kpi_bar.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OverviewHomePage extends StatelessWidget {
  const OverviewHomePage({super.key, this.storeScoped = false});

  /// True when this page is mounted under the `dashboardStore` route.
  /// Drives the back-to-dashboard chip in the page intro; the store id
  /// itself is intentionally ignored by the consolidated overview.
  final bool storeScoped;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = AppLocalizations.of(context);

    return Selector<AuthController, String?>(
      selector: (_, auth) => auth.session?.userId,
      builder: (context, sessionUserId, _) {
        return _OverviewHomeSession(
          sessionUserId: sessionUserId,
          tokens: tokens,
          l10n: l10n,
          storeScoped: storeScoped,
        );
      },
    );
  }
}

class _OverviewHomeSession extends StatelessWidget {
  const _OverviewHomeSession({
    required this.sessionUserId,
    required this.tokens,
    required this.l10n,
    required this.storeScoped,
  });

  final String? sessionUserId;
  final AppThemeTokens tokens;
  final AppLocalizations l10n;
  final bool storeScoped;

  @override
  Widget build(BuildContext context) {
    return Selector<CurrentUserContextController, bool>(
      selector: (_, userContext) =>
          sessionUserId != null &&
          !userContext.isLoadingInitial &&
          userContext.errorMessage == null &&
          userContext.hasResolvedData,
      builder: (context, isUserContextReady, _) {
        return Selector<
          AppUserExperiencePreferencesController?,
          OverviewLoadingMode
        >(
          selector: (_, prefs) =>
              prefs?.overviewLoadingMode ?? OverviewLoadingMode.progressive,
          builder: (context, loadingMode, _) {
            final overviewController = context.read<OverviewController>();
            return OverviewAutoLoader(
              controller: overviewController,
              loadingMode: loadingMode,
              userId: sessionUserId,
              isReady: isUserContextReady,
              rowLabels: l10n.overviewLoadLabels,
              failureMessageBuilder: (failure) =>
                  overviewFailureUserMessage(failure, l10n),
              child: RefreshIndicator(
                semanticsLabel: l10n.overviewHomeRefreshSemanticsLabel,
                onRefresh: () async {
                  final session = context.read<AuthController>().session;
                  if (session == null) return;
                  await overviewController.refreshOverview(
                    userId: session.userId,
                    loadingMode: loadingMode,
                    rowLabels: l10n.overviewLoadLabels,
                    failureMessageBuilder: (failure) =>
                        overviewFailureUserMessage(failure, l10n),
                  );
                },
                child: _OverviewHomeScrollableContent(
                  sessionUserId: sessionUserId,
                  tokens: tokens,
                  l10n: l10n,
                  overviewController: overviewController,
                  loadingMode: loadingMode,
                  storeScoped: storeScoped,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OverviewHomeScrollableContent extends StatelessWidget {
  const _OverviewHomeScrollableContent({
    required this.sessionUserId,
    required this.tokens,
    required this.l10n,
    required this.overviewController,
    required this.loadingMode,
    required this.storeScoped,
  });

  final String? sessionUserId;
  final AppThemeTokens tokens;
  final AppLocalizations l10n;
  final OverviewController overviewController;
  final OverviewLoadingMode loadingMode;
  final bool storeScoped;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: context.pageScrollPadding(
        tokens,
        horizontalAdjustment:
            AppPageSpacingPresets.dashboardHorizontalAdjustment,
      ),
      children: <Widget>[
        _OverviewHomeIntro(l10n: l10n, storeScoped: storeScoped),
        SizedBox(height: tokens.gapMd),
        _OverviewFilterSection(
          l10n: l10n,
          sessionUserId: sessionUserId,
          overviewController: overviewController,
          loadingMode: loadingMode,
        ),
        _OverviewAlertsSection(
          l10n: l10n,
          sessionUserId: sessionUserId,
          overviewController: overviewController,
          loadingMode: loadingMode,
        ),
        _OverviewMetricsSection(tokens: tokens, l10n: l10n),
      ],
    );
  }
}

class _OverviewFilterSection extends StatelessWidget {
  const _OverviewFilterSection({
    required this.l10n,
    required this.sessionUserId,
    required this.overviewController,
    required this.loadingMode,
  });

  final AppLocalizations l10n;
  final String? sessionUserId;
  final OverviewController overviewController;
  final OverviewLoadingMode loadingMode;

  @override
  Widget build(BuildContext context) {
    return Selector<OverviewController, _FilterSlice>(
      selector: (_, c) => _FilterSlice(
        filter: c.activeFilter,
        agents: c.availableAgents,
        // Keep filters interactive after the first successful agent list; only
        // block edits on the true cold start before branch options exist.
        isLoading: c.isLoadingInitial && c.availableAgents.isEmpty,
        isOnRetryCooldown: c.isOnRetryCooldown,
      ),
      builder: (context, slice, _) {
        return OverviewFilterBar(
          l10n: l10n,
          filter: slice.filter,
          availableAgents: slice.agents,
          isLoading: slice.isLoading || slice.isOnRetryCooldown,
          onFilterChanged: sessionUserId == null
              ? null
              : (filter) => unawaited(
                  overviewController.applyFilter(
                    userId: sessionUserId!,
                    filter: filter,
                    loadingMode: loadingMode,
                    rowLabels: l10n.overviewLoadLabels,
                    failureMessageBuilder: (failure) =>
                        overviewFailureUserMessage(failure, l10n),
                  ),
                ),
        );
      },
    );
  }
}

class _OverviewAlertsSection extends StatelessWidget {
  const _OverviewAlertsSection({
    required this.l10n,
    required this.sessionUserId,
    required this.overviewController,
    required this.loadingMode,
  });

  final AppLocalizations l10n;
  final String? sessionUserId;
  final OverviewController overviewController;
  final OverviewLoadingMode loadingMode;

  @override
  Widget build(BuildContext context) {
    return Selector<OverviewController, _AlertsSlice>(
      selector: (_, c) => _AlertsSlice(
        errorMessage: c.errorMessage,
        errorDiagnosticBody: c.errorDiagnosticBody,
        loadFailure: c.loadFailure,
        overview: c.overview,
        missingTokenNames: c.missingTokenAgentNamesNormalized,
        partialFailureNames: c.partialQueryFailureAgentNamesNormalized,
        skippedDueToHubPresenceNames:
            c.skippedDueToHubPresenceAgentNamesNormalized,
        retryRemainingSeconds: c.retryAfterGate.remaining?.inSeconds ?? 0,
      ),
      builder: (context, slice, _) {
        final remaining = slice.retryRemainingSeconds;
        final retryCountdown = remaining > 0
            ? l10n.appInlineErrorRetryCountdown(remaining)
            : null;
        return OverviewHomeAlertsSection(
          l10n: l10n,
          errorMessage: slice.errorMessage,
          overview: slice.overview,
          missingTokenAgentNamesNormalized: slice.missingTokenNames,
          partialFailureAgentNamesNormalized: slice.partialFailureNames,
          onOpenAgents: () => context.goTo(AppRoute.agents),
          errorDiagnosticBody: slice.errorDiagnosticBody,
          loadFailure: slice.loadFailure,
          skippedDueToHubPresenceAgentNamesNormalized:
              slice.skippedDueToHubPresenceNames,
          retryCountdownLabel: retryCountdown,
          onRetryOverview: sessionUserId == null
              ? null
              : () => unawaited(
                  overviewController.retryOverview(
                    userId: sessionUserId!,
                    loadingMode: loadingMode,
                    rowLabels: l10n.overviewLoadLabels,
                    failureMessageBuilder: (failure) =>
                        overviewFailureUserMessage(failure, l10n),
                  ),
                ),
        );
      },
    );
  }
}

class _OverviewMetricsSection extends StatelessWidget {
  const _OverviewMetricsSection({
    required this.tokens,
    required this.l10n,
  });

  final AppThemeTokens tokens;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Selector<OverviewController, _MetricsSlice>(
      selector: (_, c) => _MetricsSlice(
        isLoadingInitial: c.isLoadingInitial,
        overview: c.overview,
        completedSections: c.completedOverviewSections,
      ),
      builder: (context, slice, _) {
        final overview = slice.overview;
        final showSkeleton = slice.isLoadingInitial && overview == null;
        final displayOverview = showSkeleton ? _skeletonOverview : overview;

        if (displayOverview == null) {
          return const SizedBox.shrink();
        }

        return RepaintBoundary(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: tokens.sectionSpacing),
              AppSkeleton(
                enabled: showSkeleton,
                loadingSemanticsLabel: l10n.overviewLoadingPaymentKpisSemantics,
                child: OverviewKpiBar(
                  l10n: l10n,
                  kpis: displayOverview.kpis,
                ),
              ),
              SizedBox(height: tokens.sectionSpacing),
              const OverviewChartNavGrid(),
              SizedBox(height: tokens.sectionSpacing),
              OverviewHomeChartsBelowKpis(
                tokens: tokens,
                l10n: l10n,
                showSkeleton: showSkeleton,
                displayOverview: displayOverview,
                completedSections: slice.completedSections,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Cached skeleton placeholder so identity-based rebuild checks in child
/// widgets (`OverviewHomeStagedBelowKpis`) don't see a fresh instance on
/// every metrics rebuild while the real overview is still loading.
final Overview _skeletonOverview = Overview.empty();

class _OverviewHomeIntro extends StatelessWidget {
  const _OverviewHomeIntro({required this.l10n, required this.storeScoped});

  final AppLocalizations l10n;
  final bool storeScoped;

  static String _greetingFirstName(String fullName, AppLocalizations l10n) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      return l10n.overviewDefaultGreetingName;
    }
    return trimmed.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    return Selector2<
      CurrentUserContextController,
      OverviewController,
      _IntroSlice
    >(
      selector: (_, userContext, overviewController) {
        final overview = overviewController.overview;
        final showSkeleton =
            overviewController.isLoadingInitial && overview == null;
        return _IntroSlice(
          fullName: userContext.userScope.name,
          period: showSkeleton || overview == null
              ? null
              : OverviewFilterPeriodChipData.fromOverview(
                  overview: overview,
                  filter: overviewController.activeFilter,
                ),
        );
      },
      builder: (context, slice, _) {
        final greetingName = _greetingFirstName(slice.fullName, l10n);
        return AppShellPageIntro(
          eyebrow: l10n.overviewGreetingEyebrow(greetingName),
          sectionLabel: storeScoped ? l10n.shellNavDashboardLabel : null,
          onSectionLabelTap: storeScoped
              ? () => context.goTo(AppRoute.dashboard)
              : null,
          subtitle: l10n.overviewHomeSubtitle,
          footer: OverviewFilterPeriodChip(data: slice.period),
        );
      },
    );
  }
}

@immutable
class _IntroSlice {
  const _IntroSlice({required this.fullName, required this.period});

  final String fullName;
  final OverviewFilterPeriodChipData? period;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _IntroSlice &&
          fullName == other.fullName &&
          period == other.period);

  @override
  int get hashCode => Object.hash(fullName, period);
}

@immutable
class _FilterSlice {
  const _FilterSlice({
    required this.filter,
    required this.agents,
    required this.isLoading,
    required this.isOnRetryCooldown,
  });

  final DashboardFilter filter;
  final List<DashboardAgentOption> agents;
  final bool isLoading;
  final bool isOnRetryCooldown;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _FilterSlice &&
        filter == other.filter &&
        isLoading == other.isLoading &&
        isOnRetryCooldown == other.isOnRetryCooldown &&
        listEquals(agents, other.agents);
  }

  @override
  int get hashCode =>
      Object.hash(filter, isLoading, isOnRetryCooldown, Object.hashAll(agents));
}

@immutable
class _AlertsSlice {
  const _AlertsSlice({
    required this.errorMessage,
    required this.errorDiagnosticBody,
    required this.loadFailure,
    required this.overview,
    required this.missingTokenNames,
    required this.partialFailureNames,
    required this.skippedDueToHubPresenceNames,
    required this.retryRemainingSeconds,
  });

  final String? errorMessage;
  final String? errorDiagnosticBody;
  final AppFailure? loadFailure;
  final Overview? overview;
  final List<String> missingTokenNames;
  final List<String> partialFailureNames;
  final List<String> skippedDueToHubPresenceNames;

  /// Snapshot of `OverviewController.retryAfterGate.remainingSeconds`.
  /// Zero (or negative) means the gate is open. We expose seconds, not a
  /// `Duration`, so the slice equality stays cheap and the per-tick
  /// rebuilds only happen when the displayed value actually changes.
  final int retryRemainingSeconds;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _AlertsSlice &&
        errorMessage == other.errorMessage &&
        errorDiagnosticBody == other.errorDiagnosticBody &&
        identical(loadFailure, other.loadFailure) &&
        identical(overview, other.overview) &&
        retryRemainingSeconds == other.retryRemainingSeconds &&
        listEquals(missingTokenNames, other.missingTokenNames) &&
        listEquals(partialFailureNames, other.partialFailureNames) &&
        listEquals(
          skippedDueToHubPresenceNames,
          other.skippedDueToHubPresenceNames,
        );
  }

  @override
  int get hashCode => Object.hash(
    errorMessage,
    errorDiagnosticBody,
    loadFailure,
    overview,
    retryRemainingSeconds,
    Object.hashAll(missingTokenNames),
    Object.hashAll(partialFailureNames),
    Object.hashAll(skippedDueToHubPresenceNames),
  );
}

@immutable
class _MetricsSlice {
  const _MetricsSlice({
    required this.isLoadingInitial,
    required this.overview,
    required this.completedSections,
  });

  final bool isLoadingInitial;
  final Overview? overview;
  final Set<OverviewProgressiveSection> completedSections;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _MetricsSlice &&
          isLoadingInitial == other.isLoadingInitial &&
          identical(overview, other.overview) &&
          setEquals(completedSections, other.completedSections));

  @override
  int get hashCode => Object.hash(
    isLoadingInitial,
    overview,
    Object.hashAllUnordered(completedSections),
  );
}
