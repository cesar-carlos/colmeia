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
import 'package:colmeia/features/overview/presentation/widgets/overview_kpi_bar.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_payment_bar_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_payment_mix_card.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_rankings_section.dart';
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
                      ),
                      builder: (context, slice, _) {
                        return OverviewHomeAlertsSection(
                          l10n: l10n,
                          errorMessage: slice.errorMessage,
                          overview: slice.overview,
                          missingTokenAgentNamesNormalized:
                              slice.missingTokenNames,
                          partialFailureAgentNamesNormalized:
                              slice.partialFailureNames,
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
                              AppSkeleton(
                                enabled: showSkeleton,
                                showDelay: Duration.zero,
                                loadingSemanticsLabel:
                                    l10n.overviewLoadingPaymentMixSemantics,
                                child: OverviewPaymentMixCard(
                                  l10n: l10n,
                                  methods: displayOverview.paymentMethods,
                                ),
                              ),
                              SizedBox(height: tokens.sectionSpacing),
                              AppSkeleton(
                                enabled: showSkeleton,
                                showDelay: const Duration(milliseconds: 80),
                                loadingSemanticsLabel:
                                    l10n.overviewLoadingPaymentBarSemantics,
                                child: OverviewPaymentBarChart(
                                  l10n: l10n,
                                  methods: displayOverview.paymentMethods,
                                ),
                              ),
                              SizedBox(height: tokens.sectionSpacing),
                              AppSkeleton(
                                enabled: showSkeleton,
                                showDelay: const Duration(milliseconds: 120),
                                loadingSemanticsLabel:
                                    l10n.overviewLoadingRankingsSemantics,
                                child: OverviewRankingsSection(
                                  l10n: l10n,
                                  agentRankings: displayOverview.agentRankings,
                                  userRankings: displayOverview.userRankings,
                                ),
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
        return Selector<OverviewController, String?>(
          selector: (_, c) => _periodTagLabel(c),
          builder: (context, periodLabel, _) {
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

String? _periodTagLabel(OverviewController c) {
  final overview = c.overview;
  final showSkeleton = c.isLoadingInitial && overview == null;
  if (overview == null || showSkeleton) {
    return null;
  }
  return '${AppBrFormatters.shortDate(overview.periodStart)}'
      ' – '
      '${AppBrFormatters.shortDate(overview.periodEnd)}';
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
  });

  final String? errorMessage;
  final Overview? overview;
  final List<String> missingTokenNames;
  final List<String> partialFailureNames;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _AlertsSlice &&
        errorMessage == other.errorMessage &&
        identical(overview, other.overview) &&
        listEquals(missingTokenNames, other.missingTokenNames) &&
        listEquals(partialFailureNames, other.partialFailureNames);
  }

  @override
  int get hashCode => Object.hash(
    errorMessage,
    overview,
    Object.hashAll(missingTokenNames),
    Object.hashAll(partialFailureNames),
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
