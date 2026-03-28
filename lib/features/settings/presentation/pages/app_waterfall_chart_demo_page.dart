import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_waterfall_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppWaterfallChartDemoPage extends StatelessWidget {
  const AppWaterfallChartDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Graficos waterfall',
          title: 'AppWaterfallChart',
          subtitle:
              'Mostra como variacoes positivas e negativas constroem o '
              'resultado final. Ideal para pontes de faturamento, '
              'margem e custo.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppWaterfallChart<_BridgeStep>(
          title: '1. Ponte de faturamento',
          subtitle: 'Base, impactos do periodo, subtotal e total final.',
          items: _revenueBridge,
          labelBuilder: (item) => item.label,
          valueBuilder: (item) => item.delta,
          isIntermediateSum: (item) => item.isIntermediate,
          isTotalSum: (item) => item.isTotal,
          dataLabelBuilder: (item, value) =>
              item.isIntermediate || item.isTotal
              ? AppBrFormatters.compactCurrency(item.displayValue)
              : AppBrFormatters.compactCurrency(value),
          tooltipLabelBuilder: (item, value) =>
              '${item.label}: ${AppBrFormatters.currency(item.displayValue)}',
          style: AppWaterfallChartStyle(
            yAxisFormat: AppBrFormatters.compactCurrencyFormat,
            showDataLabels: true,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppWaterfallChart<_BridgeStep>(
          title: '2. Drivers de margem',
          subtitle: 'Ganhos e perdas por fator operacional.',
          items: _marginBridge,
          labelBuilder: (item) => item.label,
          valueBuilder: (item) => item.delta,
          isIntermediateSum: (item) => item.isIntermediate,
          isTotalSum: (item) => item.isTotal,
          style: AppWaterfallChartStyle(
            yAxisFormat: AppBrFormatters.compactCurrencyFormat,
            positiveColor: cs.tertiary,
            negativeColor: cs.error,
            intermediateSumColor: cs.secondary,
            totalSumColor: cs.primary,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: '3. Compacto com tap',
          subtitle: 'Preset compacto e callback por etapa.',
          child: AppWaterfallChart<_BridgeStep>(
            items: _revenueBridge,
            labelBuilder: (item) => item.label,
            valueBuilder: (item) => item.delta,
            isIntermediateSum: (item) => item.isIntermediate,
            isTotalSum: (item) => item.isTotal,
            preset: AppChartPreset.compact,
            onPointTap: (item, index) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${index + 1}. ${item.label}: '
                    '${AppBrFormatters.currency(item.displayValue)}',
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppWaterfallChart<String>(
          title: '4. Estado de loading',
          items: <String>[],
          labelBuilder: _identity,
          valueBuilder: _zero,
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppWaterfallChart<String>(
          title: '5. Estado vazio',
          items: const <String>[],
          labelBuilder: _identity,
          valueBuilder: _zero,
          emptyPlaceholder: Text(
            'Sem variacoes para este recorte.',
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

class _BridgeStep {
  const _BridgeStep({
    required this.label,
    required this.delta,
    required this.displayValue,
    this.isIntermediate = false,
    this.isTotal = false,
  });

  final String label;
  final double delta;
  final double displayValue;
  final bool isIntermediate;
  final bool isTotal;
}

const List<_BridgeStep> _revenueBridge = <_BridgeStep>[
  _BridgeStep(
    label: 'Base',
    delta: 0,
    displayValue: 180000,
    isIntermediate: true,
  ),
  _BridgeStep(label: 'Preco', delta: 14000, displayValue: 14000),
  _BridgeStep(label: 'Volume', delta: 22000, displayValue: 22000),
  _BridgeStep(label: 'Mix', delta: -9000, displayValue: -9000),
  _BridgeStep(
    label: 'Subtotal',
    delta: 0,
    displayValue: 207000,
    isIntermediate: true,
  ),
  _BridgeStep(label: 'Descontos', delta: -6000, displayValue: -6000),
  _BridgeStep(label: 'Frete', delta: 3000, displayValue: 3000),
  _BridgeStep(
    label: 'Final',
    delta: 0,
    displayValue: 204000,
    isTotal: true,
  ),
];

const List<_BridgeStep> _marginBridge = <_BridgeStep>[
  _BridgeStep(
    label: 'Margem base',
    delta: 0,
    displayValue: 62000,
    isIntermediate: true,
  ),
  _BridgeStep(label: 'Preco', delta: 8500, displayValue: 8500),
  _BridgeStep(label: 'Quebra', delta: -4200, displayValue: -4200),
  _BridgeStep(label: 'Turnos', delta: -3100, displayValue: -3100),
  _BridgeStep(label: 'Mix premium', delta: 6200, displayValue: 6200),
  _BridgeStep(
    label: 'Margem final',
    delta: 0,
    displayValue: 69400,
    isTotal: true,
  ),
];
