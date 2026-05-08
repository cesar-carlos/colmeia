import 'package:flutter/material.dart';

class SalesCardDescriptor {
  const SalesCardDescriptor({
    required this.id,
    required this.icon,
  });

  final String id;
  final IconData icon;

  String get route => '/sales/$id';
}

const List<SalesCardDescriptor> allSalesCards = <SalesCardDescriptor>[
  SalesCardDescriptor(
    id: 'produto_rank_lucro',
    icon: Icons.leaderboard_outlined,
  ),
  SalesCardDescriptor(
    id: 'monthly_pnl',
    icon: Icons.show_chart_rounded,
  ),
  SalesCardDescriptor(
    id: 'resumo_total_diario_vendas',
    icon: Icons.calendar_view_day_outlined,
  ),
  SalesCardDescriptor(
    id: 'produto_tendencia_venda',
    icon: Icons.trending_up_rounded,
  ),
  SalesCardDescriptor(
    id: 'produto_tendencia_venda_media_movel',
    icon: Icons.insights_rounded,
  ),
];
