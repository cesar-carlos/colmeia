import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/presentation/overview_sorted_rankings.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_lucratividade_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_monthly_parcels_combo_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_payment_mix_card.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_rankings_section.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_weekday_sales_trend_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_weekday_user_sales_trend_chart.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_motion_tokens.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fade_in.dart';
import 'package:colmeia/shared/widgets/charts/daily_sales_trend_chart.dart';
import 'package:flutter/material.dart';

/// Renders the charts below the KPI bar on the overview home screen.
///
/// Each chart is wrapped in `AppSkeleton`; while the corresponding
/// `OverviewProgressiveSection` is not yet completed the section either:
///   - shows a skeleton over the chart widget itself (initial load), or
///   - shows a sized-box skeleton placeholder (progressive snapshot in
///     flight, chart not built yet).
///
/// As sections complete, the real chart fades in via `AppChartFadeIn`.
class OverviewHomeChartsBelowKpis extends StatefulWidget {
  const OverviewHomeChartsBelowKpis({
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
  State<OverviewHomeChartsBelowKpis> createState() =>
      _OverviewHomeChartsBelowKpisState();
}

class _OverviewHomeChartsBelowKpisState
    extends State<OverviewHomeChartsBelowKpis> {
  final OverviewSortedRankingsCache _rankingsCache =
      OverviewSortedRankingsCache();

  @override
  void didUpdateWidget(covariant OverviewHomeChartsBelowKpis oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.displayOverview, widget.displayOverview)) {
      _rankingsCache.invalidate();
    }
  }

  bool _sectionReady(OverviewProgressiveSection section) {
    return widget.showSkeleton ||
        widget.completedSections.contains(section);
  }

  double _userRankingPlaceholderHeight(AppThemeTokens tokens) {
    return tokens.chartStandardHeight + tokens.contentSpacing * 3;
  }

  List<_OverviewStageDescriptor> _buildChartStages(
    double chartBlockHeight,
    AppMotionTokens motion,
  ) {
    final overview = widget.displayOverview;
    final l10n = widget.l10n;
    return <_OverviewStageDescriptor>[
      _OverviewStageDescriptor(
        section: OverviewProgressiveSection.dailySales,
        semanticsLabel: l10n.overviewLoadingDailySalesSemantics,
        placeholderHeight: chartBlockHeight,
        showDelay: motion.dashboardStageDelay(0),
        builder: () => DailySalesTrendChart(
          l10n: l10n,
          points: overview.dailySalesTrend,
          loadFailed: overview.dailySalesTrendLoadFailed,
          loadFailureMessage: overview.dailySalesTrendLoadFailureMessage,
        ),
      ),
      _OverviewStageDescriptor(
        section: OverviewProgressiveSection.monthlyParcels,
        semanticsLabel: l10n.overviewLoadingMonthlyParcelsSemantics,
        placeholderHeight: chartBlockHeight,
        showDelay: motion.dashboardStageDelay(1),
        builder: () => OverviewMonthlyParcelsComboChart(
          l10n: l10n,
          points: overview.monthlyParcelTrend,
          loadFailed: overview.monthlyParcelTrendLoadFailed,
          loadFailureMessage: overview.monthlyParcelTrendLoadFailureMessage,
        ),
      ),
      _OverviewStageDescriptor(
        section: OverviewProgressiveSection.paymentMix,
        semanticsLabel: l10n.overviewLoadingPaymentMixSemantics,
        placeholderHeight: AppCategoryDonutCard.loadingBlockHeight(
          widget.tokens,
        ),
        showDelay: motion.dashboardStageDelay(2),
        builder: () => OverviewPaymentMixCard(
          l10n: l10n,
          methods: overview.paymentMethods,
        ),
      ),
      _OverviewStageDescriptor(
        section: OverviewProgressiveSection.weekdaySales,
        semanticsLabel: l10n.overviewLoadingWeekdaySalesSemantics,
        placeholderHeight: chartBlockHeight,
        showDelay: motion.dashboardStageDelay(3),
        builder: () => OverviewWeekdaySalesTrendChart(
          l10n: l10n,
          points: overview.weekdaySalesTrend,
          loadFailed: overview.weekdaySalesTrendLoadFailed,
          loadFailureMessage: overview.weekdaySalesTrendLoadFailureMessage,
        ),
      ),
      _OverviewStageDescriptor(
        section: OverviewProgressiveSection.weekdayUserSales,
        semanticsLabel: l10n.overviewLoadingWeekdayUserSalesSemantics,
        placeholderHeight: chartBlockHeight,
        showDelay: motion.dashboardStageDelay(4),
        builder: () => OverviewWeekdayUserSalesTrendChart(
          l10n: l10n,
          points: overview.weekdayUserSalesTrend,
          loadFailed: overview.weekdayUserSalesTrendLoadFailed,
          loadFailureMessage: overview.weekdayUserSalesTrendLoadFailureMessage,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final l10n = widget.l10n;
    final motion = context.appMotion;
    final showSkeleton = widget.showSkeleton;
    final overview = widget.displayOverview;
    final chartBlockHeight = tokens.chartStandardHeight + tokens.contentSpacing;
    final stages = _buildChartStages(chartBlockHeight, motion);
    final rankings = showSkeleton
        ? OverviewSortedRankings.empty
        : _rankingsCache.resolve(overview);

    final children = <Widget>[];
    for (final stage in stages) {
      children
        ..add(SizedBox(height: tokens.sectionSpacing))
        ..add(
          _OverviewStagedChartBlock(
            visualState: _resolveVisualState(stage.section),
            placeholderHeight: stage.placeholderHeight,
            showDelay: stage.showDelay,
            loadingSemanticsLabel: stage.semanticsLabel,
            builder: stage.builder,
          ),
        );
    }
    children
      ..add(SizedBox(height: tokens.sectionSpacing))
      ..add(
        _OverviewRankingsAndLucratividade(
          showSkeleton: showSkeleton,
          tokens: tokens,
          l10n: l10n,
          motion: motion,
          overview: overview,
          rankings: rankings,
          agentRankingReady: _sectionReady(
            OverviewProgressiveSection.agentRanking,
          ),
          userRankingReady: _sectionReady(
            OverviewProgressiveSection.userRanking,
          ),
          lucratividadeReady: _sectionReady(
            OverviewProgressiveSection.lucratividadePeriod,
          ),
          chartBlockHeight: chartBlockHeight,
          userRankingPlaceholderHeight:
              _userRankingPlaceholderHeight(tokens),
        ),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  _OverviewStageVisualState _resolveVisualState(
    OverviewProgressiveSection section,
  ) {
    if (widget.showSkeleton) {
      return _OverviewStageVisualState.skeletonWithChart;
    }
    return _sectionReady(section)
        ? _OverviewStageVisualState.ready
        : _OverviewStageVisualState.placeholder;
  }
}

@immutable
class _OverviewStageDescriptor {
  const _OverviewStageDescriptor({
    required this.section,
    required this.semanticsLabel,
    required this.placeholderHeight,
    required this.showDelay,
    required this.builder,
  });

  final OverviewProgressiveSection section;
  final String semanticsLabel;
  final double placeholderHeight;
  final Duration showDelay;
  final Widget Function() builder;
}

enum _OverviewStageVisualState {
  /// Initial full-page skeleton: chart is mounted under shimmer so the
  /// element tree is warm by the time data arrives.
  skeletonWithChart,

  /// Progressive load in flight, this section's chart payload is not
  /// ready yet — render a sized-box skeleton instead of building the
  /// chart for nothing.
  placeholder,

  /// Section completed — fade the chart in.
  ready,
}

class _OverviewStagedChartBlock extends StatelessWidget {
  const _OverviewStagedChartBlock({
    required this.visualState,
    required this.placeholderHeight,
    required this.showDelay,
    required this.loadingSemanticsLabel,
    required this.builder,
  });

  final _OverviewStageVisualState visualState;
  final double placeholderHeight;
  final Duration showDelay;
  final String loadingSemanticsLabel;
  final Widget Function() builder;

  @override
  Widget build(BuildContext context) {
    switch (visualState) {
      case _OverviewStageVisualState.skeletonWithChart:
        return AppSkeleton(
          enabled: true,
          showDelay: showDelay,
          loadingSemanticsLabel: loadingSemanticsLabel,
          child: builder(),
        );
      case _OverviewStageVisualState.placeholder:
        return AppSkeleton(
          enabled: true,
          showDelay: showDelay,
          loadingSemanticsLabel: loadingSemanticsLabel,
          child: SizedBox(height: placeholderHeight),
        );
      case _OverviewStageVisualState.ready:
        return AppSkeleton(
          enabled: false,
          showDelay: showDelay,
          loadingSemanticsLabel: loadingSemanticsLabel,
          child: AppChartFadeIn(
            child: RepaintBoundary(child: builder()),
          ),
        );
    }
  }
}

class _OverviewRankingsAndLucratividade extends StatelessWidget {
  const _OverviewRankingsAndLucratividade({
    required this.showSkeleton,
    required this.tokens,
    required this.l10n,
    required this.motion,
    required this.overview,
    required this.rankings,
    required this.agentRankingReady,
    required this.userRankingReady,
    required this.lucratividadeReady,
    required this.chartBlockHeight,
    required this.userRankingPlaceholderHeight,
  });

  final bool showSkeleton;
  final AppThemeTokens tokens;
  final AppLocalizations l10n;
  final AppMotionTokens motion;
  final Overview overview;
  final OverviewSortedRankings rankings;
  final bool agentRankingReady;
  final bool userRankingReady;
  final bool lucratividadeReady;
  final double chartBlockHeight;
  final double userRankingPlaceholderHeight;

  Widget _buildAgentCard() {
    return OverviewAgentRankingCard(
      l10n: l10n,
      agentRankings: rankings.agents,
    );
  }

  Widget _buildUserCard() {
    return OverviewUserRankingCard(
      l10n: l10n,
      userRankings: rankings.users,
    );
  }

  Widget _buildLucratividadeCard() {
    return OverviewLucratividadeChart(
      l10n: l10n,
      points: overview.lucratividadeTrend,
      loadFailed: overview.lucratividadeTrendLoadFailed,
      loadFailureMessage: overview.lucratividadeTrendLoadFailureMessage,
      overviewApprovedAgentCount: overview.approvedAgentCount,
    );
  }

  Widget _wrapReady({required Key key, required Widget child}) {
    return AppChartFadeIn(
      child: RepaintBoundary(key: key, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final delay = motion.dashboardStageDelay(5);

    if (showSkeleton) {
      return AppSkeleton(
        enabled: true,
        showDelay: delay,
        loadingSemanticsLabel: l10n.overviewLoadingRankingsSemantics,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildAgentCard(),
            SizedBox(height: tokens.sectionSpacing),
            _buildUserCard(),
            SizedBox(height: tokens.sectionSpacing),
            _buildLucratividadeCard(),
          ],
        ),
      );
    }

    if (!agentRankingReady) {
      return AppSkeleton(
        enabled: true,
        showDelay: delay,
        loadingSemanticsLabel: l10n.overviewLoadingRankingsSemantics,
        child: SizedBox(
          height: chartBlockHeight +
              tokens.sectionSpacing +
              userRankingPlaceholderHeight +
              tokens.sectionSpacing +
              chartBlockHeight,
        ),
      );
    }

    final userSlot = userRankingReady
        ? _wrapReady(
            key: const ValueKey<String>('overview-user-ranking'),
            child: _buildUserCard(),
          )
        : SizedBox(height: userRankingPlaceholderHeight);

    final lucratividadeSlot = lucratividadeReady
        ? _wrapReady(
            key: const ValueKey<String>('overview-lucratividade-period'),
            child: _buildLucratividadeCard(),
          )
        : SizedBox(height: chartBlockHeight);

    return AppSkeleton(
      enabled: false,
      showDelay: delay,
      loadingSemanticsLabel: l10n.overviewLoadingRankingsSemantics,
      child: _wrapReady(
        key: const ValueKey<String>('overview-agent-ranking'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildAgentCard(),
            SizedBox(height: tokens.sectionSpacing),
            userSlot,
            SizedBox(height: tokens.sectionSpacing),
            lucratividadeSlot,
          ],
        ),
      ),
    );
  }
}
