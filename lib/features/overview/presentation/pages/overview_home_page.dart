import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_controller.dart';
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
import 'package:provider/provider.dart';

class OverviewHomePage extends StatefulWidget {
  const OverviewHomePage({super.key});

  @override
  State<OverviewHomePage> createState() => _OverviewHomePageState();
}

class _OverviewHomePageState extends State<OverviewHomePage> {
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = AppLocalizations.of(context);
    final controller = context.read<OverviewController>();
    final prev = controller.activeLocalizations;
    if (prev == null || prev.localeName != next.localeName) {
      controller.activeLocalizations = next;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = AppLocalizations.of(context);

    return Selector<AuthController, String?>(
      selector: (_, auth) => auth.session?.userId,
      builder: (context, sessionUserId, _) {
        return Selector<CurrentUserContextController, bool>(
          selector: (_, userContext) =>
              sessionUserId != null &&
              !userContext.isLoadingInitial &&
              userContext.errorMessage == null &&
              userContext.hasResolvedData,
          builder: (context, isUserContextReady, _) {
            final overviewController = context.read<OverviewController>();

            return OverviewAutoLoader(
              controller: overviewController,
              userId: sessionUserId,
              isReady: isUserContextReady,
              child: RefreshIndicator(
                onRefresh: () async {
                  final session = context.read<AuthController>().session;
                  if (session == null) return;
                  await context.read<OverviewController>().refreshOverview(
                    userId: session.userId,
                  );
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: context.pageScrollPadding(tokens),
                  children: <Widget>[
                    _OverviewHomeIntro(l10n: l10n),
                    SizedBox(height: tokens.gapMd),
                    Selector<OverviewController, _FilterSlice>(
                      selector: (_, c) =>
                          _FilterSlice(c.activeFilter, c.availableAgents),
                      builder: (context, slice, _) {
                        return OverviewFilterBar(
                          l10n: l10n,
                          filter: slice.filter,
                          availableAgents: slice.agents,
                          onFilterChanged: sessionUserId == null
                              ? null
                              : (f) => unawaited(
                                  overviewController.applyFilter(
                                    userId: sessionUserId,
                                    filter: f,
                                  ),
                                ),
                        );
                      },
                    ),
                    Selector<OverviewController, _AlertsSlice>(
                      selector: (_, c) => _AlertsSlice(
                        errorMessage: c.errorMessage,
                        overview: c.overview,
                        missingTokenNames: c.missingTokenAgentNamesNormalized,
                        partialFailureNames:
                            c.partialQueryFailureAgentNamesNormalized,
                        skippedDueToHubPresenceNames:
                            c.skippedDueToHubPresenceAgentNamesNormalized,
                        retryRemainingSeconds:
                            c.retryAfterGate.remaining?.inSeconds ?? 0,
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
                          missingTokenAgentNamesNormalized:
                              slice.missingTokenNames,
                          partialFailureAgentNamesNormalized:
                              slice.partialFailureNames,
                          skippedDueToHubPresenceAgentNamesNormalized:
                              slice.skippedDueToHubPresenceNames,
                          retryCountdownLabel: retryCountdown,
                          onOpenAgents: () => context.goTo(AppRoute.agents),
                          onRetryOverview: sessionUserId == null
                              ? null
                              : () {
                                  final uid = sessionUserId;
                                  unawaited(
                                    context
                                        .read<OverviewController>()
                                        .retryOverview(userId: uid),
                                  );
                                },
                        );
                      },
                    ),
                    Selector<OverviewController, _MetricsSlice>(
                      selector: (_, c) => _MetricsSlice(
                        isLoadingInitial: c.isLoadingInitial,
                        overview: c.overview,
                      ),
                      builder: (context, slice, _) {
                        final overview = slice.overview;
                        final showSkeleton =
                            slice.isLoadingInitial && overview == null;
                        final displayOverview = showSkeleton
                            ? _neutralSkeletonOverview
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
                                loadingSemanticsLabel:
                                    l10n.overviewLoadingPaymentKpisSemantics,
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
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
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
            return AppShellPageIntro(
              eyebrow: l10n.overviewGreetingEyebrow(greetingName),
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
  const _FilterSlice(this.filter, this.agents);

  final OverviewFilter filter;
  final List<OverviewAgentOption> agents;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _FilterSlice &&
        filter == other.filter &&
        listEquals(agents, other.agents);
  }

  @override
  int get hashCode => Object.hash(filter, Object.hashAll(agents));
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
  });

  final bool isLoadingInitial;
  final Overview? overview;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _MetricsSlice &&
          isLoadingInitial == other.isLoadingInitial &&
          identical(overview, other.overview));

  @override
  int get hashCode => Object.hash(isLoadingInitial, overview);
}
