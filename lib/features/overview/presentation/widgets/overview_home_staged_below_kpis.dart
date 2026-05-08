import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_daily_sales_trend_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_lucratividade_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_monthly_parcels_combo_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_payment_mix_card.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_rankings_section.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_weekday_sales_trend_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_weekday_user_sales_trend_chart.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fade_in.dart';
import 'package:flutter/material.dart';

/// Stages daily sales (ResumoTotalDiarioVendas) first, then the last-12-months combo
/// chart, then the payment mix donut and each remaining Syncfusion-heavy chart on
/// separate frames after the skeleton→data transition so the UI thread is not saturated
/// in a single frame. Rankings mount in steps (agent chart, then user chart, then period
/// lucratividade) to avoid heavy bar charts in one burst.
class OverviewHomeStagedBelowKpis extends StatefulWidget {
  const OverviewHomeStagedBelowKpis({
    required this.tokens,
    required this.l10n,
    required this.showSkeleton,
    required this.displayOverview,
    required this.completedSections,
    super.key,
  });

  final AppThemeTokens tokens;
  final AppLocalizations l10n;
  final bool showSkeleton;
  final Overview displayOverview;
  final Set<OverviewProgressiveSection> completedSections;

  @override
  State<OverviewHomeStagedBelowKpis> createState() =>
      _OverviewHomeStagedBelowKpisState();
}

class _OverviewHomeStagedBelowKpisState
    extends State<OverviewHomeStagedBelowKpis> {
  /// 0 = placeholders only. 1 = daily sales trend, 2 = monthly parcels,
  /// 3 = payment mix, 4 = weekday sales, 5 = weekday-by-user, 6 = agent ranking,
  /// 7 = user ranking, 8 = lucratividade (period).
  int _belowKpisStage = 0;

  /// Bumped when a new staged pipeline starts, skeleton cancels it, or on
  /// [dispose], so post-frame callbacks do not call [setState] after teardown.
  int _mountGeneration = 0;

  static const int _finalStage = 8;

  Overview? _sortedListsSource;
  List<OverviewAgentRanking>? _sortedAgentsCache;
  List<OverviewUserRanking>? _sortedUsersCache;

  @override
  void initState() {
    super.initState();
    if (!widget.showSkeleton) {
      _belowKpisStage = 0;
      _scheduleStagedMount();
    } else {
      _belowKpisStage = _finalStage;
    }
  }

  @override
  void dispose() {
    _mountGeneration++;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OverviewHomeStagedBelowKpis oldWidget) {
    super.didUpdateWidget(oldWidget);
    // New overview while already showing data (e.g. refresh with keepContentVisible):
    // restart staging so charts do not mix old/new payloads mid-pipeline.
    if (!widget.showSkeleton &&
        !oldWidget.showSkeleton &&
        !identical(oldWidget.displayOverview, widget.displayOverview)) {
      _invalidateSortedCaches();
      _mountGeneration++;
      _belowKpisStage = 0;
      _scheduleStagedMount();
      return;
    }
    if (!oldWidget.showSkeleton && widget.showSkeleton) {
      _mountGeneration++;
      _belowKpisStage = _finalStage;
    } else if (oldWidget.showSkeleton && !widget.showSkeleton) {
      _invalidateSortedCaches();
      _belowKpisStage = 0;
      _scheduleStagedMount();
    }
  }

  void _invalidateSortedCaches() {
    _sortedListsSource = null;
    _sortedAgentsCache = null;
    _sortedUsersCache = null;
  }

  void _enqueueStagedWork(int generation, void Function() work) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _mountGeneration) {
        return;
      }
      work();
    });
  }

  void _scheduleStagedMount() {
    final generation = ++_mountGeneration;

    void advanceOneStage() {
      if (!mounted || generation != _mountGeneration) {
        return;
      }
      setState(() {
        if (_belowKpisStage < _finalStage) {
          _belowKpisStage++;
        }
      });
      if (_belowKpisStage < _finalStage) {
        _enqueueStagedWork(generation, advanceOneStage);
      }
    }

    _enqueueStagedWork(generation, advanceOneStage);
  }

  ({List<OverviewAgentRanking> agents, List<OverviewUserRanking> users})
  _sortedRankings(Overview overview) {
    if (identical(_sortedListsSource, overview) &&
        _sortedAgentsCache != null &&
        _sortedUsersCache != null) {
      return (agents: _sortedAgentsCache!, users: _sortedUsersCache!);
    }
    final agentsSorted = List<OverviewAgentRanking>.of(overview.agentRankings)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    final agents = [
      for (final a in agentsSorted)
        if (a.totalAmount > 0) a,
    ];
    final usersSorted = List<OverviewUserRanking>.of(overview.userRankings)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    final users = [
      for (final u in usersSorted)
        if (u.totalAmount > 0) u,
    ];
    _sortedListsSource = overview;
    _sortedAgentsCache = agents;
    _sortedUsersCache = users;
    return (agents: agents, users: users);
  }

  double _userRankingPlaceholderHeight(AppThemeTokens tokens) {
    return tokens.chartStandardHeight + tokens.contentSpacing * 3;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final l10n = widget.l10n;
    final showSkeleton = widget.showSkeleton;
    final displayOverview = widget.displayOverview;
    final chartBlockHeight = tokens.chartStandardHeight + tokens.contentSpacing;
    final mixPlaceholderHeight = AppCategoryDonutCard.loadingBlockHeight(
      tokens,
    );
    bool sectionReady(OverviewProgressiveSection section) {
      return showSkeleton || widget.completedSections.contains(section);
    }

    if (showSkeleton) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(height: tokens.sectionSpacing),
          _OverviewStagedChartBlock(
            showSkeleton: true,
            currentStage: _belowKpisStage,
            requiredStage: 1,
            placeholderHeight: chartBlockHeight,
            showDelay: Duration.zero,
            loadingSemanticsLabel: l10n.overviewLoadingDailySalesSemantics,
            builder: () => OverviewDailySalesTrendChart(
              l10n: l10n,
              points: displayOverview.dailySalesTrend,
              loadFailed: displayOverview.dailySalesTrendLoadFailed,
              loadFailureMessage:
                  displayOverview.dailySalesTrendLoadFailureMessage,
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
          _OverviewStagedChartBlock(
            showSkeleton: true,
            currentStage: _belowKpisStage,
            requiredStage: 2,
            placeholderHeight: chartBlockHeight,
            showDelay: const Duration(milliseconds: 40),
            loadingSemanticsLabel: l10n.overviewLoadingMonthlyParcelsSemantics,
            builder: () => OverviewMonthlyParcelsComboChart(
              l10n: l10n,
              points: displayOverview.monthlyParcelTrend,
              loadFailed: displayOverview.monthlyParcelTrendLoadFailed,
              loadFailureMessage:
                  displayOverview.monthlyParcelTrendLoadFailureMessage,
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
          _OverviewStagedChartBlock(
            showSkeleton: true,
            currentStage: _belowKpisStage,
            requiredStage: 3,
            placeholderHeight: mixPlaceholderHeight,
            showDelay: const Duration(milliseconds: 80),
            loadingSemanticsLabel: l10n.overviewLoadingPaymentMixSemantics,
            builder: () => OverviewPaymentMixCard(
              l10n: l10n,
              methods: displayOverview.paymentMethods,
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
          _OverviewStagedChartBlock(
            showSkeleton: true,
            currentStage: _belowKpisStage,
            requiredStage: 4,
            placeholderHeight: chartBlockHeight,
            showDelay: const Duration(milliseconds: 100),
            loadingSemanticsLabel: l10n.overviewLoadingWeekdaySalesSemantics,
            builder: () => OverviewWeekdaySalesTrendChart(
              l10n: l10n,
              points: displayOverview.weekdaySalesTrend,
              loadFailed: displayOverview.weekdaySalesTrendLoadFailed,
              loadFailureMessage:
                  displayOverview.weekdaySalesTrendLoadFailureMessage,
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
          _OverviewStagedChartBlock(
            showSkeleton: true,
            currentStage: _belowKpisStage,
            requiredStage: 5,
            placeholderHeight: chartBlockHeight,
            showDelay: const Duration(milliseconds: 120),
            loadingSemanticsLabel:
                l10n.overviewLoadingWeekdayUserSalesSemantics,
            builder: () => OverviewWeekdayUserSalesTrendChart(
              l10n: l10n,
              points: displayOverview.weekdayUserSalesTrend,
              loadFailed: displayOverview.weekdayUserSalesTrendLoadFailed,
              loadFailureMessage:
                  displayOverview.weekdayUserSalesTrendLoadFailureMessage,
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
          AppSkeleton(
            enabled: true,
            showDelay: const Duration(milliseconds: 140),
            loadingSemanticsLabel: l10n.overviewLoadingRankingsSemantics,
            child: OverviewRankingsSection(
              l10n: l10n,
              agentRankings: displayOverview.agentRankings,
              userRankings: displayOverview.userRankings,
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
          AppSkeleton(
            enabled: true,
            showDelay: const Duration(milliseconds: 160),
            loadingSemanticsLabel: l10n.overviewLoadingLucratividadeSemantics,
            child: OverviewLucratividadeChart(
              l10n: l10n,
              points: displayOverview.lucratividadeTrend,
              loadFailed: displayOverview.lucratividadeTrendLoadFailed,
              loadFailureMessage:
                  displayOverview.lucratividadeTrendLoadFailureMessage,
              overviewApprovedAgentCount: displayOverview.approvedAgentCount,
            ),
          ),
        ],
      );
    }

    final overview = displayOverview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: tokens.sectionSpacing),
        _OverviewStagedChartBlock(
          showSkeleton: false,
          currentStage: sectionReady(OverviewProgressiveSection.dailySales)
              ? 1
              : 0,
          requiredStage: 1,
          placeholderHeight: chartBlockHeight,
          showDelay: Duration.zero,
          loadingSemanticsLabel: l10n.overviewLoadingDailySalesSemantics,
          builder: () => OverviewDailySalesTrendChart(
            l10n: l10n,
            points: overview.dailySalesTrend,
            loadFailed: overview.dailySalesTrendLoadFailed,
            loadFailureMessage: overview.dailySalesTrendLoadFailureMessage,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        _OverviewStagedChartBlock(
          showSkeleton: false,
          currentStage: sectionReady(OverviewProgressiveSection.monthlyParcels)
              ? 2
              : 0,
          requiredStage: 2,
          placeholderHeight: chartBlockHeight,
          showDelay: const Duration(milliseconds: 40),
          loadingSemanticsLabel: l10n.overviewLoadingMonthlyParcelsSemantics,
          builder: () => OverviewMonthlyParcelsComboChart(
            l10n: l10n,
            points: overview.monthlyParcelTrend,
            loadFailed: overview.monthlyParcelTrendLoadFailed,
            loadFailureMessage: overview.monthlyParcelTrendLoadFailureMessage,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        _OverviewStagedChartBlock(
          showSkeleton: false,
          currentStage: sectionReady(OverviewProgressiveSection.paymentMix)
              ? 3
              : 0,
          requiredStage: 3,
          placeholderHeight: mixPlaceholderHeight,
          showDelay: const Duration(milliseconds: 80),
          loadingSemanticsLabel: l10n.overviewLoadingPaymentMixSemantics,
          builder: () => OverviewPaymentMixCard(
            l10n: l10n,
            methods: overview.paymentMethods,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        _OverviewStagedChartBlock(
          showSkeleton: false,
          currentStage: sectionReady(OverviewProgressiveSection.weekdaySales)
              ? 4
              : 0,
          requiredStage: 4,
          placeholderHeight: chartBlockHeight,
          showDelay: const Duration(milliseconds: 100),
          loadingSemanticsLabel: l10n.overviewLoadingWeekdaySalesSemantics,
          builder: () => OverviewWeekdaySalesTrendChart(
            l10n: l10n,
            points: overview.weekdaySalesTrend,
            loadFailed: overview.weekdaySalesTrendLoadFailed,
            loadFailureMessage: overview.weekdaySalesTrendLoadFailureMessage,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        _OverviewStagedChartBlock(
          showSkeleton: false,
          currentStage:
              sectionReady(OverviewProgressiveSection.weekdayUserSales) ? 5 : 0,
          requiredStage: 5,
          placeholderHeight: chartBlockHeight,
          showDelay: const Duration(milliseconds: 120),
          loadingSemanticsLabel: l10n.overviewLoadingWeekdayUserSalesSemantics,
          builder: () => OverviewWeekdayUserSalesTrendChart(
            l10n: l10n,
            points: overview.weekdayUserSalesTrend,
            loadFailed: overview.weekdayUserSalesTrendLoadFailed,
            loadFailureMessage:
                overview.weekdayUserSalesTrendLoadFailureMessage,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSkeleton(
          enabled: !sectionReady(OverviewProgressiveSection.agentRanking),
          showDelay: const Duration(milliseconds: 140),
          loadingSemanticsLabel: l10n.overviewLoadingRankingsSemantics,
          child: !sectionReady(OverviewProgressiveSection.agentRanking)
              ? SizedBox(
                  height:
                      chartBlockHeight +
                      tokens.sectionSpacing +
                      _userRankingPlaceholderHeight(tokens) +
                      tokens.sectionSpacing +
                      chartBlockHeight,
                )
              : _StagedFadeIn(
                  child: RepaintBoundary(
                    key: const ValueKey<String>('overview-agent-ranking'),
                    child: Builder(
                      builder: (context) {
                        final rankings = _sortedRankings(overview);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            OverviewAgentRankingCard(
                              l10n: l10n,
                              agentRankings: rankings.agents,
                            ),
                            SizedBox(height: tokens.sectionSpacing),
                            if (sectionReady(
                              OverviewProgressiveSection.userRanking,
                            ))
                              _StagedFadeIn(
                                child: RepaintBoundary(
                                  key: const ValueKey<String>(
                                    'overview-user-ranking',
                                  ),
                                  child: OverviewUserRankingCard(
                                    l10n: l10n,
                                    userRankings: rankings.users,
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                height: _userRankingPlaceholderHeight(tokens),
                              ),
                            SizedBox(height: tokens.sectionSpacing),
                            if (sectionReady(
                              OverviewProgressiveSection.lucratividadePeriod,
                            ))
                              _StagedFadeIn(
                                child: RepaintBoundary(
                                  key: const ValueKey<String>(
                                    'overview-lucratividade-period',
                                  ),
                                  child: OverviewLucratividadeChart(
                                    l10n: l10n,
                                    points: overview.lucratividadeTrend,
                                    loadFailed:
                                        overview.lucratividadeTrendLoadFailed,
                                    loadFailureMessage: overview
                                        .lucratividadeTrendLoadFailureMessage,
                                    overviewApprovedAgentCount:
                                        overview.approvedAgentCount,
                                  ),
                                ),
                              )
                            else
                              SizedBox(height: chartBlockHeight),
                          ],
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _OverviewStagedChartBlock extends StatelessWidget {
  const _OverviewStagedChartBlock({
    required this.showSkeleton,
    required this.currentStage,
    required this.requiredStage,
    required this.placeholderHeight,
    required this.showDelay,
    required this.loadingSemanticsLabel,
    required this.builder,
  });

  final bool showSkeleton;
  final int currentStage;
  final int requiredStage;
  final double placeholderHeight;
  final Duration showDelay;
  final String loadingSemanticsLabel;
  final Widget Function() builder;

  @override
  Widget build(BuildContext context) {
    if (showSkeleton) {
      return AppSkeleton(
        enabled: true,
        showDelay: showDelay,
        loadingSemanticsLabel: loadingSemanticsLabel,
        child: builder(),
      );
    }

    final ready = currentStage >= requiredStage;
    return AppSkeleton(
      enabled: !ready,
      showDelay: showDelay,
      loadingSemanticsLabel: loadingSemanticsLabel,
      child: ready
          ? _StagedFadeIn(
              child: RepaintBoundary(
                child: builder(),
              ),
            )
          : SizedBox(height: placeholderHeight),
    );
  }
}

/// Local alias kept for source-compatibility with the staged-mounter call
/// sites; the actual widget lives in
/// [lib/shared/widgets/charts/app_chart_fade_in.dart] so any other dashboard
/// can opt into the same entrance treatment without copy/pasting it.
typedef _StagedFadeIn = AppChartFadeIn;
