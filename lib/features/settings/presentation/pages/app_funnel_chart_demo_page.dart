import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_funnel_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppFunnelChartDemoPage extends StatelessWidget {
  const AppFunnelChartDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;
    final onboardingStages = <_FunnelStage>[
      _FunnelStage(label: 'Cadastro', volume: 960, color: cs.primary),
      _FunnelStage(label: 'Confirmacao', volume: 810, color: cs.secondary),
      _FunnelStage(label: 'Documento', volume: 620, color: cs.tertiary),
      _FunnelStage(
        label: 'Treinamento',
        volume: 420,
        color: cs.primary.withValues(alpha: 0.7),
      ),
      _FunnelStage(
        label: 'Primeiro acesso',
        volume: 285,
        color: cs.error.withValues(alpha: 0.75),
      ),
    ];

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Graficos de funil',
          title: 'AppFunnelChart',
          subtitle:
              'Visualiza perda entre etapas de um processo, como pipeline '
              'comercial, conversao de onboarding e funil operacional.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppFunnelChart<_FunnelStage>(
          title: '1. Pipeline comercial',
          subtitle: 'Conversao do lead ate o fechamento.',
          items: _salesStages,
          labelBuilder: (item) => item.label,
          valueBuilder: (item) => item.volume,
          dataLabelBuilder: (item, value) =>
              '${item.label}\n${_compactNumber.format(value)}',
          tooltipLabelBuilder: (item, value) =>
              '${item.label}: ${_compactNumber.format(value)} contatos',
          style: const AppFunnelChartStyle(showLegend: true),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppFunnelChart<_FunnelStage>(
          title: '2. Onboarding com cores por etapa',
          subtitle: 'Destaque para validações mais críticas do fluxo.',
          items: onboardingStages,
          labelBuilder: (item) => item.label,
          valueBuilder: (item) => item.volume,
          colorBuilder: (item) => item.color,
          tooltipLabelBuilder: (item, value) =>
              '${item.label}: ${_compactNumber.format(value)} usuarios',
          onSegmentTap: (item, index) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${index + 1}. ${item.label}: '
                  '${_compactNumber.format(item.volume)} usuarios',
                ),
              ),
            );
          },
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppSectionCardWithHeading(
          title: '3. Preset compacto',
          subtitle: 'Boa opcao para cards de acompanhamento rapido.',
          child: AppFunnelChart<_FunnelStage>(
            items: _salesStages,
            labelBuilder: _funnelLabel,
            valueBuilder: _funnelValue,
            preset: AppChartPreset.compact,
            style: AppFunnelChartStyle(
              showTooltip: false,
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppFunnelChart<String>(
          title: '4. Estado de loading',
          items: <String>[],
          labelBuilder: _identity,
          valueBuilder: _zero,
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppFunnelChart<String>(
          title: '5. Estado vazio',
          items: const <String>[],
          labelBuilder: _identity,
          valueBuilder: _zero,
          emptyPlaceholder: Text(
            'Nenhuma etapa registrada para este funil.',
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

String _funnelLabel(_FunnelStage item) => item.label;

num _funnelValue(_FunnelStage item) => item.volume;

class _FunnelStage {
  const _FunnelStage({
    required this.label,
    required this.volume,
    this.color,
  });

  final String label;
  final int volume;
  final Color? color;
}

final NumberFormat _compactNumber = NumberFormat.compact(locale: 'pt_BR');

const List<_FunnelStage> _salesStages = <_FunnelStage>[
  _FunnelStage(label: 'Leads', volume: 1240),
  _FunnelStage(label: 'Qualificados', volume: 780),
  _FunnelStage(label: 'Apresentacao', volume: 440),
  _FunnelStage(label: 'Proposta', volume: 180),
  _FunnelStage(label: 'Fechados', volume: 92),
];
