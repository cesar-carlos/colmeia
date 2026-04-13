import 'package:colmeia/features/overview/domain/entities/overview_chart_point.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_renderer.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';

enum OverviewSalesTrendRange {
  lastWeek,
  lastMonth,
}

/// Weekly / monthly toggle around the revenue time series.
class OverviewSalesTrendCard extends StatefulWidget {
  const OverviewSalesTrendCard({
    required this.points,
    super.key,
  });

  final List<OverviewChartPoint> points;

  @override
  State<OverviewSalesTrendCard> createState() => _OverviewSalesTrendCardState();
}

class _OverviewSalesTrendCardState extends State<OverviewSalesTrendCard> {
  OverviewSalesTrendRange _range = OverviewSalesTrendRange.lastWeek;

  List<OverviewChartPoint> get _chartPoints {
    if (_range == OverviewSalesTrendRange.lastWeek) {
      return widget.points;
    }
    return widget.points
        .map(
          (p) => OverviewChartPoint(
            label: p.label,
            value: p.value * 4.15,
          ),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return OverviewChartRenderer(
      title: 'Tendência de vendas diárias',
      subtitle: 'Panorama do faturamento no período selecionado.',
      points: _chartPoints,
      belowSubtitle: SizedBox(
        width: double.infinity,
        child: AppSegmentedControl<OverviewSalesTrendRange>(
          expandToFill: true,
          options: const <AppSegmentedControlOption<OverviewSalesTrendRange>>[
            AppSegmentedControlOption<OverviewSalesTrendRange>(
              value: OverviewSalesTrendRange.lastWeek,
              label: 'Última semana',
            ),
            AppSegmentedControlOption<OverviewSalesTrendRange>(
              value: OverviewSalesTrendRange.lastMonth,
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
