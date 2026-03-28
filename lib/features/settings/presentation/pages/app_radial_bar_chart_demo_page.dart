import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_radial_bar_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppRadialBarChartDemoPage extends StatelessWidget {
  const AppRadialBarChartDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Graficos radial bar',
          title: 'AppRadialBarChart',
          subtitle:
              'Compara progresso entre categorias em leitura circular, muito '
              'util para SLA, aderencia de lojas, metas por frente '
              'e scorecards.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppRadialBarChart<_RadialMetric>(
          title: '1. SLA por canal',
          subtitle: 'Mostra rapidamente quem esta mais perto da meta cheia.',
          items: _slaMetrics,
          labelBuilder: (item) => item.label,
          valueBuilder: (item) => item.value,
          tooltipLabelBuilder: (item, value) =>
              '${item.label}: ${value.toStringAsFixed(0)}%',
          style: const AppRadialBarChartStyle(
            showLegend: true,
            maximumValue: 100,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppRadialBarChart<_RadialMetric>(
          title: '2. Aderencia com cores customizadas',
          subtitle:
              'Permite reforcar visualmente times acima ou abaixo da meta.',
          items: _adherenceMetrics(cs),
          labelBuilder: (item) => item.label,
          valueBuilder: (item) => item.value,
          colorBuilder: (item) => item.color,
          dataLabelBuilder: (item, value) =>
              '${item.label}\n${value.toStringAsFixed(0)}%',
          tooltipLabelBuilder: (item, value) =>
              '${item.label}: ${value.toStringAsFixed(1)}%',
          style: const AppRadialBarChartStyle(
            showDataLabels: true,
            maximumValue: 100,
          ),
          onSegmentTap: (item, index) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${index + 1}. ${item.label}: '
                  '${item.value.toStringAsFixed(1)}%',
                ),
              ),
            );
          },
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppSectionCardWithHeading(
          title: '3. Preset compacto',
          subtitle: 'Cabe bem em cards executivos resumidos.',
          child: AppRadialBarChart<_RadialMetric>(
            items: _slaMetrics,
            labelBuilder: _metricLabel,
            valueBuilder: _metricValue,
            preset: AppChartPreset.compact,
            style: AppRadialBarChartStyle(
              showTooltip: false,
              maximumValue: 100,
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppRadialBarChart<_RadialMetric>(
          title: '4. Progresso acumulado em horas',
          subtitle: 'Tambem funciona fora do range percentual.',
          items: _hoursMetrics,
          labelBuilder: (item) => item.label,
          valueBuilder: (item) => item.value,
          tooltipLabelBuilder: (item, value) =>
              '${item.label}: ${_compactNumber.format(value)} h',
          style: const AppRadialBarChartStyle(showLegend: true),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppRadialBarChart<String>(
          title: '5. Estado de loading',
          items: <String>[],
          labelBuilder: _identity,
          valueBuilder: _zero,
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppRadialBarChart<String>(
          title: '6. Estado vazio',
          items: const <String>[],
          labelBuilder: _identity,
          valueBuilder: _zero,
          emptyPlaceholder: Text(
            'Nenhuma serie radial disponivel para este recorte.',
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

String _metricLabel(_RadialMetric item) => item.label;

num _metricValue(_RadialMetric item) => item.value;

class _RadialMetric {
  const _RadialMetric({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final double value;
  final Color? color;
}

final NumberFormat _compactNumber = NumberFormat.compact(locale: 'pt_BR');

const List<_RadialMetric> _slaMetrics = <_RadialMetric>[
  _RadialMetric(label: 'Delivery', value: 94),
  _RadialMetric(label: 'Retirada', value: 88),
  _RadialMetric(label: 'Caixa rapido', value: 81),
  _RadialMetric(label: 'Atacado', value: 73),
];

const List<_RadialMetric> _hoursMetrics = <_RadialMetric>[
  _RadialMetric(label: 'Auditoria', value: 124),
  _RadialMetric(label: 'Reposicao', value: 96),
  _RadialMetric(label: 'Inventario', value: 78),
];

List<_RadialMetric> _adherenceMetrics(ColorScheme cs) => <_RadialMetric>[
  _RadialMetric(label: 'Loja Norte', value: 97.4, color: cs.primary),
  _RadialMetric(label: 'Loja Centro', value: 91.2, color: cs.secondary),
  _RadialMetric(label: 'Loja Sul', value: 84.7, color: cs.tertiary),
  _RadialMetric(
    label: 'Loja Oeste',
    value: 76.5,
    color: cs.error.withValues(alpha: 0.82),
  ),
];
