import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:flutter/material.dart';

final class OverviewChartCardDescriptor {
  const OverviewChartCardDescriptor({
    required this.id,
    required this.icon,
    required this.section,
  });

  final String id;
  final IconData icon;
  final OverviewProgressiveSection section;
}

const List<OverviewChartCardDescriptor> allOverviewChartCards =
    <OverviewChartCardDescriptor>[
  OverviewChartCardDescriptor(
    id: 'daily_sales',
    icon: Icons.calendar_view_day_outlined,
    section: OverviewProgressiveSection.dailySales,
  ),
  OverviewChartCardDescriptor(
    id: 'payment_mix',
    icon: Icons.donut_large_outlined,
    section: OverviewProgressiveSection.paymentMix,
  ),
  OverviewChartCardDescriptor(
    id: 'weekday_sales',
    icon: Icons.date_range_outlined,
    section: OverviewProgressiveSection.weekdaySales,
  ),
  OverviewChartCardDescriptor(
    id: 'weekday_user_sales',
    icon: Icons.people_outline_rounded,
    section: OverviewProgressiveSection.weekdayUserSales,
  ),
  OverviewChartCardDescriptor(
    id: 'user_ranking',
    icon: Icons.leaderboard_outlined,
    section: OverviewProgressiveSection.userRanking,
  ),
  OverviewChartCardDescriptor(
    id: 'lucratividade_period',
    icon: Icons.account_balance_outlined,
    section: OverviewProgressiveSection.lucratividadePeriod,
  ),
  OverviewChartCardDescriptor(
    id: 'lucratividade_mensal',
    icon: Icons.calendar_month_outlined,
    section: OverviewProgressiveSection.lucratividadeMensal,
  ),
];

OverviewChartCardDescriptor? overviewChartCardById(String id) {
  for (final card in allOverviewChartCards) {
    if (card.id == id) {
      return card;
    }
  }
  return null;
}
