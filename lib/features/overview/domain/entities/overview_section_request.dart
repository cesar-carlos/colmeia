import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';

/// Declares which overview SQL batches to run for a given surface.
final class OverviewSectionRequest {
  const OverviewSectionRequest({
    required this.runMainBatch,
    required this.sectionBatchSections,
    this.mainBatchIncludePaymentResumo = true,
    this.mainBatchIncludeUserRanking = true,
  });

  /// Lazy chart detail surfaces.
  factory OverviewSectionRequest.forChartSection(
    OverviewProgressiveSection section,
  ) {
    return switch (section) {
      OverviewProgressiveSection.paymentMix => const OverviewSectionRequest(
        runMainBatch: true,
        mainBatchIncludeUserRanking: false,
        sectionBatchSections: <OverviewProgressiveSection>{},
      ),
      OverviewProgressiveSection.userRanking ||
      OverviewProgressiveSection.agentRanking => const OverviewSectionRequest(
        runMainBatch: true,
        mainBatchIncludePaymentResumo: false,
        sectionBatchSections: <OverviewProgressiveSection>{},
      ),
      OverviewProgressiveSection.summary => const OverviewSectionRequest(
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

  /// Home dashboard: KPIs + agent ranking + monthly chart only.
  ///
  /// Payment mix and per-user ranking cards load on demand (prefetch or detail).
  static const OverviewSectionRequest home = OverviewSectionRequest(
    runMainBatch: true,
    mainBatchIncludePaymentResumo: false,
    sectionBatchSections: <OverviewProgressiveSection>{
      OverviewProgressiveSection.monthlyParcels,
    },
  );

  /// Full overview load (legacy / tests).
  ///
  /// Monthly lucratividade is surfaced via Sales monthly PnL — there is no
  /// active chart card or detail route for [OverviewProgressiveSection.lucratividadeMensal].
  static const OverviewSectionRequest full = OverviewSectionRequest(
    runMainBatch: true,
    sectionBatchSections: <OverviewProgressiveSection>{
      OverviewProgressiveSection.dailySales,
      OverviewProgressiveSection.monthlyParcels,
      OverviewProgressiveSection.weekdaySales,
      OverviewProgressiveSection.weekdayUserSales,
      OverviewProgressiveSection.lucratividadePeriod,
    },
  );

  /// Runs selective payment resumo and/or per-user ranking SQL.
  final bool runMainBatch;

  /// When [runMainBatch] is true, issues payment resumo SQL.
  final bool mainBatchIncludePaymentResumo;

  /// When [runMainBatch] is true, issues per-user ranking SQL.
  final bool mainBatchIncludeUserRanking;

  /// Section-batch SQL subsets (daily, monthly, weekday, lucratividade, …).
  final Set<OverviewProgressiveSection> sectionBatchSections;

  Set<OverviewProgressiveSection> completedAfterMainBatch() {
    if (!runMainBatch) {
      return const <OverviewProgressiveSection>{};
    }
    final sections = <OverviewProgressiveSection>{
      OverviewProgressiveSection.summary,
    };
    if (mainBatchIncludePaymentResumo) {
      sections.add(OverviewProgressiveSection.paymentMix);
    }
    if (mainBatchIncludeUserRanking) {
      sections
        ..add(OverviewProgressiveSection.agentRanking)
        ..add(OverviewProgressiveSection.userRanking);
    }
    return sections;
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

  int get mainBatchCommandCount {
    if (!runMainBatch) {
      return 0;
    }
    var count = 0;
    if (mainBatchIncludePaymentResumo) {
      count++;
    }
    if (mainBatchIncludeUserRanking) {
      count++;
    }
    return count;
  }
}
