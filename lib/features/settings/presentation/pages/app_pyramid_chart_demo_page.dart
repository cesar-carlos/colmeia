import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_pyramid_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppPyramidChartDemoPage extends StatelessWidget {
  const AppPyramidChartDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Graficos pyramid',
          title: 'AppPyramidChart',
          subtitle:
              'Mostra distribuicao decrescente por etapa ou faixa, com leitura '
              'boa para hierarquia de volume, capacidade e segmentacao.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppPyramidChart<_PyramidStep>(
          title: '1. Capacidade por senioridade',
          subtitle: 'Topo largo e base estreita para mostrar concentracao.',
          items: _workforceLevels,
          labelBuilder: (item) => item.label,
          valueBuilder: (item) => item.volume,
          dataLabelBuilder: (item, value) =>
              '${item.label}\n${_compactNumber.format(value)}',
          tooltipLabelBuilder: (item, value) =>
              '${item.label}: ${_compactNumber.format(value)} colaboradores',
          style: const AppPyramidChartStyle(showLegend: true),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppPyramidChart<_PyramidStep>(
          title: '2. Mix por faixa de ticket',
          subtitle: 'Cores por etapa e tap para destacar faixas.',
          items: _ticketBands(cs),
          labelBuilder: (item) => item.label,
          valueBuilder: (item) => item.volume,
          colorBuilder: (item) => item.color,
          onSegmentTap: (item, index) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${index + 1}. ${item.label}: '
                  '${_compactNumber.format(item.volume)} pedidos',
                ),
              ),
            );
          },
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppSectionCardWithHeading(
          title: '3. Preset compacto',
          subtitle: 'Boa opcao para cards de distribuicao resumida.',
          child: AppPyramidChart<_PyramidStep>(
            items: _workforceLevels,
            labelBuilder: _pyramidLabel,
            valueBuilder: _pyramidValue,
            preset: AppChartPreset.compact,
            style: AppPyramidChartStyle(showTooltip: false),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppPyramidChart<String>(
          title: '4. Estado de loading',
          items: <String>[],
          labelBuilder: _identity,
          valueBuilder: _zero,
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppPyramidChart<String>(
          title: '5. Estado vazio',
          items: const <String>[],
          labelBuilder: _identity,
          valueBuilder: _zero,
          emptyPlaceholder: Text(
            'Nenhuma distribuicao disponivel para este recorte.',
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

String _pyramidLabel(_PyramidStep item) => item.label;

num _pyramidValue(_PyramidStep item) => item.volume;

class _PyramidStep {
  const _PyramidStep({
    required this.label,
    required this.volume,
    this.color,
  });

  final String label;
  final int volume;
  final Color? color;
}

final NumberFormat _compactNumber = NumberFormat.compact(locale: 'pt_BR');

const List<_PyramidStep> _workforceLevels = <_PyramidStep>[
  _PyramidStep(label: 'Junior', volume: 420),
  _PyramidStep(label: 'Pleno', volume: 280),
  _PyramidStep(label: 'Senior', volume: 130),
  _PyramidStep(label: 'Especialista', volume: 58),
  _PyramidStep(label: 'Lideranca', volume: 19),
];

List<_PyramidStep> _ticketBands(ColorScheme cs) => <_PyramidStep>[
  _PyramidStep(label: r'Ate R$ 20', volume: 1240, color: cs.primary),
  _PyramidStep(label: r'R$ 20-40', volume: 960, color: cs.secondary),
  _PyramidStep(label: r'R$ 40-60', volume: 620, color: cs.tertiary),
  _PyramidStep(
    label: r'R$ 60-90',
    volume: 310,
    color: cs.primary.withValues(alpha: 0.7),
  ),
  _PyramidStep(
    label: r'Acima de R$ 90',
    volume: 96,
    color: cs.error.withValues(alpha: 0.75),
  ),
];
