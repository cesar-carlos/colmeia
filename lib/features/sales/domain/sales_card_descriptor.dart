import 'package:flutter/material.dart';

class SalesCardDescriptor {
  const SalesCardDescriptor({
    required this.id,
    required this.icon,
    required this.l10nTitleKey,
  });

  final String id;
  final IconData icon;
  final String l10nTitleKey;

  String get route => '/sales/$id';
}

const List<SalesCardDescriptor> allSalesCards = <SalesCardDescriptor>[
  SalesCardDescriptor(
    id: 'produto_rank_lucro',
    icon: Icons.leaderboard_outlined,
    l10nTitleKey: 'salesCardProdutoRankLucroTitle',
  ),
  SalesCardDescriptor(
    id: 'monthly_pnl',
    icon: Icons.show_chart_rounded,
    l10nTitleKey: 'salesCardMonthlyPnlTitle',
  ),
];
