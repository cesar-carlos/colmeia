import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';

/// Declares which overview SQL batches to run for a given surface.
final class OverviewSectionRequest {
  const OverviewSectionRequest({
    required this.runMainBatch,
    required this.sectionBatchSections,
  });

  /// Lazy chart detail surfaces.
  factory OverviewSectionRequest.forChartSection(
    OverviewProgressiveSection section,
  ) {
    return switch (section) {
      OverviewProgressiveSection.summary ||
      OverviewProgressiveSection.paymentMix ||
      OverviewProgressiveSection.agentRanking ||
      OverviewProgressiveSection.userRanking =>
        const OverviewSectionRequest(
          runMainBatch: true,
          sectionBatchSections: <OverviewProgressiveSection>{},
        ),
      OverviewProgressiveSection.dailySales ||
      OverviewProgressiveSection.monthlyParcels ||
      OverviewProgressiveSection.weekdaySales ||
      OverviewProgressiveSection.weekdayUserSales ||
      OverviewProgressiveSection.lucratividadePeriod ||
      OverviewProgressiveSection.lucratividadeMensal =>
        OverviewSectionRequest(
          runMainBatch: false,
          sectionBatchSections: <OverviewProgressiveSection>{section},
        ),
    };
  }

  /// Home dashboard: KPIs + agent ranking chart + monthly chart only.
  static const OverviewSectionRequest home = OverviewSectionRequest(
    runMainBatch: true,
    sectionBatchSections: <OverviewProgressiveSection>{
      OverviewProgressiveSection.monthlyParcels,
    },
  );

  /// Full overview load (legacy / tests).
  ///
  /// Includes [OverviewProgressiveSection.lucratividadeMensal] for batch
  /// coverage, but there is no active chart card or detail route for that
  /// section yet (monthly lucratividade is surfaced via Sales monthly PnL).
  static const OverviewSectionRequest full = OverviewSectionRequest(
    runMainBatch: true,
    sectionBatchSections: <OverviewProgressiveSection>{
      OverviewProgressiveSection.dailySales,
      OverviewProgressiveSection.monthlyParcels,
      OverviewProgressiveSection.weekdaySales,
      OverviewProgressiveSection.weekdayUserSales,
      OverviewProgressiveSection.lucratividadePeriod,
      OverviewProgressiveSection.lucratividadeMensal,
    },
  );

  static const Set<OverviewProgressiveSection> _mainBatchCompletedSections =
      <OverviewProgressiveSection>{
        OverviewProgressiveSection.summary,
        OverviewProgressiveSection.paymentMix,
        OverviewProgressiveSection.agentRanking,
        OverviewProgressiveSection.userRanking,
      };

  /// Runs payment resumo + per-user ranking SQL (KPIs, mix, rankings).
  final bool runMainBatch;

  /// Section-batch SQL subsets (daily, monthly, weekday, lucratividade, …).
  final Set<OverviewProgressiveSection> sectionBatchSections;

  Set<OverviewProgressiveSection> completedAfterMainBatch() {
    return runMainBatch
        ? _mainBatchCompletedSections
        : const <OverviewProgressiveSection>{};
  }

  Set<OverviewProgressiveSection> completedWhenFinal() {
    return <OverviewProgressiveSection>{
      ...completedAfterMainBatch(),
      ...sectionBatchSections,
    };
  }

  bool get isMainBatchOnly =>
      runMainBatch && sectionBatchSections.isEmpty;

  bool get isSectionBatchOnly =>
      !runMainBatch && sectionBatchSections.isNotEmpty;
}
