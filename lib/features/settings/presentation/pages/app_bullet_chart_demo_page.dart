import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_bullet_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppBulletChartDemoPage extends StatelessWidget {
  const AppBulletChartDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Graficos bullet',
          title: 'AppBulletChart',
          subtitle:
              'Compara realizado vs meta com faixas qualitativas. Ideal para '
              'SLA, vendas, conversao e metas operacionais.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppBulletChart<_PerformanceMetric>(
          title: '1. Desempenho por indicador',
          subtitle: 'Cada linha mostra faixas, realizado e marcador de meta.',
          items: _performanceSamples,
          labelBuilder: (item) => item.label,
          valueBuilder: (item) => item.actual,
          targetValueBuilder: (item) => item.target,
          rangesBuilder: (item) => item.ranges,
          style: AppBulletChartStyle(
            numberFormat: AppBrFormatters.compactCurrencyFormat,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppBulletChart<_OperationalMetric>(
          title: '2. Operacional em percentual',
          subtitle: 'Excelente para acompanhar aderencia e SLA.',
          items: _operationalSamples,
          labelBuilder: (item) => item.label,
          valueBuilder: (item) => item.actual,
          targetValueBuilder: (item) => item.target,
          rangesBuilder: (item) => item.ranges,
          maxValueBuilder: (_) => 100,
          style: AppBulletChartStyle(
            numberFormat: _wholePercentFormat,
            targetMarkerColor: cs.error,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: '3. Tap + compacto',
          subtitle: 'Uso em cards com preset compacto e callback de toque.',
          child: AppBulletChart<_OperationalMetric>(
            items: _operationalSamples,
            labelBuilder: (item) => item.label,
            valueBuilder: (item) => item.actual,
            targetValueBuilder: (item) => item.target,
            rangesBuilder: (item) => item.ranges,
            maxValueBuilder: (_) => 100,
            preset: AppChartPreset.compact,
            onPointTap: (item, index) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${item.label}: ${item.actual.toStringAsFixed(0)} / ${item.target.toStringAsFixed(0)}',
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppBulletChart<String>(
          title: '4. Estado de loading',
          items: <String>[],
          labelBuilder: _identity,
          valueBuilder: _zero,
          targetValueBuilder: _zero,
          rangesBuilder: _emptyRanges,
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppBulletChart<String>(
          title: '5. Estado vazio',
          items: const <String>[],
          labelBuilder: _identity,
          valueBuilder: _zero,
          targetValueBuilder: _zero,
          rangesBuilder: _emptyRanges,
          emptyPlaceholder: Text(
            'Sem indicadores para este recorte.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

String _identity(String item) => item;

num _zero(String _) => 0;

List<AppBulletRange> _emptyRanges(String _) => const <AppBulletRange>[];

final NumberFormat _wholePercentFormat = NumberFormat("0'%'", 'pt_BR');

class _PerformanceMetric {
  const _PerformanceMetric({
    required this.label,
    required this.actual,
    required this.target,
    required this.ranges,
  });

  final String label;
  final double actual;
  final double target;
  final List<AppBulletRange> ranges;
}

class _OperationalMetric {
  const _OperationalMetric({
    required this.label,
    required this.actual,
    required this.target,
    required this.ranges,
  });

  final String label;
  final double actual;
  final double target;
  final List<AppBulletRange> ranges;
}

const List<_PerformanceMetric> _performanceSamples = <_PerformanceMetric>[
  _PerformanceMetric(
    label: 'Faturamento',
    actual: 118000,
    target: 130000,
    ranges: <AppBulletRange>[
      AppBulletRange(end: 70000),
      AppBulletRange(end: 100000),
      AppBulletRange(end: 150000),
    ],
  ),
  _PerformanceMetric(
    label: 'Lucro bruto',
    actual: 38400,
    target: 42000,
    ranges: <AppBulletRange>[
      AppBulletRange(end: 22000),
      AppBulletRange(end: 32000),
      AppBulletRange(end: 50000),
    ],
  ),
  _PerformanceMetric(
    label: 'Ticket medio',
    actual: 89,
    target: 94,
    ranges: <AppBulletRange>[
      AppBulletRange(end: 55),
      AppBulletRange(end: 75),
      AppBulletRange(end: 110),
    ],
  ),
];

const List<_OperationalMetric> _operationalSamples = <_OperationalMetric>[
  _OperationalMetric(
    label: 'SLA entrega',
    actual: 91,
    target: 95,
    ranges: <AppBulletRange>[
      AppBulletRange(end: 70),
      AppBulletRange(end: 85),
      AppBulletRange(end: 100),
    ],
  ),
  _OperationalMetric(
    label: 'Aderencia escala',
    actual: 97,
    target: 98,
    ranges: <AppBulletRange>[
      AppBulletRange(end: 75),
      AppBulletRange(end: 90),
      AppBulletRange(end: 100),
    ],
  ),
  _OperationalMetric(
    label: 'Conversao',
    actual: 68,
    target: 72,
    ranges: <AppBulletRange>[
      AppBulletRange(end: 40),
      AppBulletRange(end: 60),
      AppBulletRange(end: 100),
    ],
  ),
];
