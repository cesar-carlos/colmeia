import 'dart:async';

import 'package:colmeia/app/preferences/app_user_experience_preferences_controller.dart';
import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_controller.dart';
import 'package:colmeia/features/overview/presentation/localization/overview_failure_l10n.dart';
import 'package:colmeia/features/overview/presentation/localization/overview_load_labels_l10n.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_auto_loader.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_filter_bar.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_home_alerts_section.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_home_staged_below_kpis.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_kpi_bar.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class OverviewHomePage extends StatelessWidget {
  const OverviewHomePage({super.key});

  static final Overview _neutralSkeletonOverview = Overview(
    periodStart: DateTime(1970),
    periodEnd: DateTime(1970),
    kpis: const OverviewPaymentKpis(
      totalSalesCount: 0,
      totalAmount: 0,
      averageTicket: 0,
      paymentMethodCount: 0,
    ),
    paymentMethods: const <OverviewPaymentMethodBreakdown>[],
    agentRankings: const <OverviewAgentRanking>[],
    userRankings: const <OverviewUserRanking>[],
  );

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
  });

  final String? sessionUserId;
  final AppThemeTokens tokens;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Selector<CurrentUserContextController, bool>(
      selector: (_, userContext) =>
          sessionUserId != null &&
          !userContext.isLoadingInitial &&
          userContext.errorMessage == null &&
          userContext.hasResolvedData,
      builder: (context, isUserContextReady, _) {
        final overviewController = context.read<OverviewController>();
        final loadingMode =
            context
                .watch<AppUserExperiencePreferencesController?>()
                ?.overviewLoadingMode ??
            OverviewLoadingMode.progressive;

        return OverviewAutoLoader(
          controller: overviewController,
          loadingMode: loadingMode,
          userId: sessionUserId,
          isReady: isUserContextReady,
          rowLabels: l10n.overviewLoadLabels,
          failureMessageBuilder: (failure) =>
              overviewFailureUserMessage(failure, l10n),
          child: RefreshIndicator(
            onRefresh: () async {
              final session = context.read<AuthController>().session;
              if (session == null) return;
              await context.read<OverviewController>().refreshOverview(
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
            ),
          ),
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
  });

  final String? sessionUserId;
  final AppThemeTokens tokens;
  final AppLocalizations l10n;
  final OverviewController overviewController;
  final OverviewLoadingMode loadingMode;

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
        _OverviewHomeIntro(l10n: l10n),
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
        isLoading: c.isLoading,
      ),
      builder: (context, slice, _) {
        return OverviewFilterBar(
          l10n: l10n,
          filter: slice.filter,
          availableAgents: slice.agents,
          isLoading: slice.isLoading,
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
    required this.loadingMode,
  });

  final AppLocalizations l10n;
  final String? sessionUserId;
  final OverviewLoadingMode loadingMode;

  @override
  Widget build(BuildContext context) {
    return Selector<OverviewController, _AlertsSlice>(
      selector: (_, c) => _AlertsSlice(
        errorMessage: c.errorMessage,
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
          skippedDueToHubPresenceAgentNamesNormalized:
              slice.skippedDueToHubPresenceNames,
          retryCountdownLabel: retryCountdown,
          onOpenAgents: () => context.goTo(AppRoute.agents),
          onRetryOverview: sessionUserId == null
              ? null
              : () {
                  final uid = sessionUserId!;
                  unawaited(
                    context.read<OverviewController>().retryOverview(
                      userId: uid,
                      loadingMode: loadingMode,
                      rowLabels: l10n.overviewLoadLabels,
                      failureMessageBuilder: (failure) =>
                          overviewFailureUserMessage(failure, l10n),
                    ),
                  );
                },
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
        final displayOverview = showSkeleton
            ? OverviewHomePage._neutralSkeletonOverview
            : overview;

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
              OverviewHomeStagedBelowKpis(
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

class _OverviewHomeIntro extends StatelessWidget {
  const _OverviewHomeIntro({required this.l10n});

  final AppLocalizations l10n;

  static String _greetingFirstName(String fullName, AppLocalizations l10n) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      return l10n.overviewDefaultGreetingName;
    }
    return trimmed.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    return Selector<CurrentUserContextController, String>(
      selector: (_, c) => c.userScope.name,
      builder: (context, fullName, _) {
        final greetingName = _greetingFirstName(fullName, l10n);
        return Selector<OverviewController, _PeriodTagSlice?>(
          selector: (_, c) => _PeriodTagSlice.fromController(c),
          builder: (context, slice, _) {
            final periodLabel = slice?.label(l10n);
            final router = GoRouter.maybeOf(context);
            final route = router == null
                ? AppRoute.dashboard
                : AppRoute.fromLocation(
                    GoRouterState.of(context).matchedLocation,
                  );
            final storeScoped = route == AppRoute.dashboardStore;
            return AppShellPageIntro(
              eyebrow: l10n.overviewGreetingEyebrow(greetingName),
              sectionLabel:
                  storeScoped ? l10n.shellNavDashboardLabel : null,
              onSectionLabelTap:
                  storeScoped ? () => context.goTo(AppRoute.dashboard) : null,
              subtitle: l10n.overviewHomeSubtitle,
              footer: periodLabel != null
                  ? AppTagChip(
                      label: periodLabel,
                      icon: Icons.calendar_today_outlined,
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}

@immutable
class _PeriodTagSlice {
  const _PeriodTagSlice({
    required this.startYmd,
    required this.endYmd,
    required this.hasCustomRange,
  });

  final int startYmd;
  final int endYmd;
  final bool hasCustomRange;

  static int _packYmd(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  static _PeriodTagSlice? fromController(OverviewController c) {
    final overview = c.overview;
    final showSkeleton = c.isLoadingInitial && overview == null;
    if (overview == null || showSkeleton) {
      return null;
    }
    return _PeriodTagSlice(
      startYmd: _packYmd(overview.periodStart),
      endYmd: _packYmd(overview.periodEnd),
      hasCustomRange: c.activeFilter.referenceRange != null,
    );
  }

  String label(AppLocalizations l10n) {
    final start = DateTime(
      startYmd ~/ 10000,
      (startYmd % 10000) ~/ 100,
      startYmd % 100,
    );
    final end = DateTime(
      endYmd ~/ 10000,
      (endYmd % 10000) ~/ 100,
      endYmd % 100,
    );
    final dates =
        '${AppBrFormatters.shortDate(start)} – ${AppBrFormatters.shortDate(end)}';
    if (hasCustomRange) {
      return '${l10n.overviewPeriodTagCustomRangePrefix}: $dates';
    }
    return dates;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _PeriodTagSlice &&
          startYmd == other.startYmd &&
          endYmd == other.endYmd &&
          hasCustomRange == other.hasCustomRange);

  @override
  int get hashCode => Object.hash(startYmd, endYmd, hasCustomRange);
}

@immutable
class _FilterSlice {
  const _FilterSlice({
    required this.filter,
    required this.agents,
    required this.isLoading,
  });

  final OverviewFilter filter;
  final List<OverviewAgentOption> agents;
  final bool isLoading;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _FilterSlice &&
        filter == other.filter &&
        isLoading == other.isLoading &&
        listEquals(agents, other.agents);
  }

  @override
  int get hashCode => Object.hash(filter, isLoading, Object.hashAll(agents));
}

@immutable
class _AlertsSlice {
  const _AlertsSlice({
    required this.errorMessage,
    required this.overview,
    required this.missingTokenNames,
    required this.partialFailureNames,
    required this.skippedDueToHubPresenceNames,
    required this.retryRemainingSeconds,
  });

  final String? errorMessage;
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
    Object.hashAll(completedSections),
  );
}
