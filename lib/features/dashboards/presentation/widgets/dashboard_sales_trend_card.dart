import 'package:colmeia/features/dashboards/domain/entities/dashboard_chart_point.dart';
import 'package:colmeia/features/dashboards/presentation/widgets/dashboard_chart_renderer.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';

enum DashboardSalesTrendRange {
  lastWeek,
  lastMonth,
}

/// Weekly / monthly toggle around the revenue time series.
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
    return DashboardChartRenderer(
      title: 'Tendência de vendas diárias',
      subtitle: 'Panorama do faturamento no período selecionado.',
      points: _chartPoints,
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
