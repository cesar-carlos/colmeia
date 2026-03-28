import 'package:colmeia/features/dashboards/domain/entities/dashboard_category_share.dart';
import 'package:colmeia/shared/widgets/charts/app_horizontal_progress_chart.dart';
import 'package:flutter/material.dart';

/// Category share bars (Stitch: resumo de vendas por categoria).
class DashboardCategoryMixCard extends StatelessWidget {
  const DashboardCategoryMixCard({
    required this.shares,
    super.key,
  });

  final List<DashboardCategoryShare> shares;

  @override
  Widget build(BuildContext context) {
    return AppHorizontalProgressChart<DashboardCategoryShare>(
      title: 'Resumo de vendas por categoria',
      items: shares,
      labelBuilder: (share) => share.label,
      valueBuilder: (share) => share.percent,
    );
  }
}
