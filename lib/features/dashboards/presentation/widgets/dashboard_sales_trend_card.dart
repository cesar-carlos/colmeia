import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_chart_point.dart';
import 'package:colmeia/features/dashboards/presentation/widgets/dashboard_chart_renderer.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';

enum DashboardSalesTrendRange {
  lastWeek,
  lastMonth,
}

/// Weekly / monthly toggle and reports shortcut around the revenue time series.
class DashboardSalesTrendCard extends StatefulWidget {
  const DashboardSalesTrendCard({
    required this.points,
    super.key,
  });

  final List<DashboardChartPoint> points;

  @override
  State<DashboardSalesTrendCard> createState() =>
      _DashboardSalesTrendCardState();
}

class _DashboardSalesTrendCardState extends State<DashboardSalesTrendCard> {
  DashboardSalesTrendRange _range = DashboardSalesTrendRange.lastWeek;

  List<DashboardChartPoint> get _chartPoints {
    if (_range == DashboardSalesTrendRange.lastWeek) {
      return widget.points;
    }
    return widget.points
        .map(
          (p) => DashboardChartPoint(
            label: p.label,
            value: p.value * 4.15,
          ),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DashboardChartRenderer(
      title: 'Tendência de vendas diárias',
      subtitle: 'Panorama do faturamento no período selecionado.',
      points: _chartPoints,
      titleTrailing: TextButton(
        onPressed: () => context.goTo(AppRoute.reports),
        child: Text(
          'Ver relatório completo',
          style: theme.textTheme.labelLarge?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      belowSubtitle: SizedBox(
        width: double.infinity,
        child: AppSegmentedControl<DashboardSalesTrendRange>(
          expandToFill: true,
          options: const <AppSegmentedControlOption<DashboardSalesTrendRange>>[
            AppSegmentedControlOption<DashboardSalesTrendRange>(
              value: DashboardSalesTrendRange.lastWeek,
              label: 'Última semana',
            ),
            AppSegmentedControlOption<DashboardSalesTrendRange>(
              value: DashboardSalesTrendRange.lastMonth,
              label: 'Último mês',
            ),
          ],
          value: _range,
          onChanged: (selection) => setState(() => _range = selection),
        ),
      ),
    );
  }
}
