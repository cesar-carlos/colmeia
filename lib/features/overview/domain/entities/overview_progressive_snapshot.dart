import 'package:colmeia/features/overview/domain/entities/overview.dart';

enum OverviewProgressiveSection {
  summary,
  dailySales,
  monthlyParcels,
  paymentMix,
  weekdaySales,
  weekdayUserSales,
  agentRanking,
  userRanking,
  lucratividadePeriod,
}

class OverviewProgressiveSnapshot {
  const OverviewProgressiveSnapshot({
    required this.overview,
    required this.completedSections,
    required this.pendingSections,
    required this.isFinal,
  });

  final Overview overview;
  final Set<OverviewProgressiveSection> completedSections;
  final Set<OverviewProgressiveSection> pendingSections;
  final bool isFinal;
}
