import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_gauge_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppGaugeChartDemoPage extends StatelessWidget {
  const AppGaugeChartDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Graficos gauge',
          title: 'AppGaugeChart',
          subtitle:
              'Mostra valor atual, faixas de referencia e meta em leitura '
              'instrumental, ideal para SLA, ocupacao, temperatura operacional '
              'e indicadores executivos.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppGaugeChart(
          title: '1. SLA medio de atendimento',
          subtitle: 'Faixas de risco, atencao e saudavel com meta destacada.',
          value: 87,
          targetValue: 92,
          valueLabelBuilder: (value) => '${value.toStringAsFixed(0)}%',
          targetLabelBuilder: (value) => 'Meta ${value.toStringAsFixed(0)}%',
          ranges: const <AppGaugeRange>[
            AppGaugeRange(start: 0, end: 70, color: Color(0xFFD9485F)),
            AppGaugeRange(start: 70, end: 85, color: Color(0xFFF6B93B)),
            AppGaugeRange(start: 85, end: 100, color: Color(0xFF2ECC71)),
          ],
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppGaugeChart(
          title: '2. Ocupacao por capacidade',
          subtitle: 'Gauge com pointer de faixa para uma leitura mais densa.',
          value: 61,
          max: 80,
          targetValue: 68,
          valueLabelBuilder: (value) => '${_compactNumber.format(value)} vagas',
          targetLabelBuilder: (value) => 'Meta ${_compactNumber.format(value)}',
          ranges: <AppGaugeRange>[
            AppGaugeRange(start: 0, end: 36, color: cs.tertiary),
            AppGaugeRange(start: 36, end: 56, color: cs.primary),
            AppGaugeRange(
              start: 56,
              end: 80,
              color: cs.error.withValues(alpha: 0.8),
            ),
          ],
          style: const AppGaugeChartStyle(
            showNeedle: false,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppSectionCardWithHeading(
          title: '3. Preset compacto',
          subtitle: 'Boa opcao para cards de performance resumidos.',
          child: AppGaugeChart(
            value: 73,
            valueLabelBuilder: _compactGaugeLabel,
            preset: AppChartPreset.compact,
            style: AppGaugeChartStyle(
              showTicks: false,
              showTargetMarker: false,
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppGaugeChart(
          title: '4. Estado de loading',
          value: 0,
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppGaugeChart(
          title: '5. Estado vazio',
          value: 0,
          max: 0,
          emptyPlaceholder: Text(
            'Nao foi possivel montar o gauge para este indicador.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

String _compactGaugeLabel(double value) => '${value.toStringAsFixed(0)}%';

final NumberFormat _compactNumber = NumberFormat.compact(locale: 'pt_BR');
