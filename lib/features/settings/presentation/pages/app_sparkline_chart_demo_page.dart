import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_sparkline_chart.dart';
import 'package:colmeia/shared/widgets/metrics/app_metric_stat_card.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppSparklineChartDemoPage extends StatelessWidget {
  const AppSparklineChartDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Micro graficos',
          title: 'AppSparklineChart',
          subtitle:
              'Linha de tendencia compacta para KPI cards, tabelas e listas. '
              'Detecta direcao automaticamente e suporta gradiente de area.',
        ),
        SizedBox(height: tokens.sectionSpacing),

        // Trend directions
        const AppSectionCardWithHeading(
          title: '1. Direcao automatica',
          subtitle:
              'AppSparklineTrend.auto infere a cor pelo primeiro e ultimo '
              'valor.',
          child: Column(
            children: <Widget>[
              _SparklineRow(
                label: 'Alta (up)',
                values: _upTrend,
              ),
              Divider(height: 24),
              _SparklineRow(
                label: 'Queda (down)',
                values: _downTrend,
              ),
              Divider(height: 24),
              _SparklineRow(
                label: 'Estavel (flat)',
                values: _flatTrend,
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),

        // Variants
        const AppSectionCardWithHeading(
          title: '2. Variantes visuais',
          subtitle: 'Com e sem preenchimento, com e sem ponto final.',
          child: Column(
            children: <Widget>[
              _SparklineRow(label: 'Gradiente + ponto', values: _upTrend),
              Divider(height: 24),
              _SparklineRow(
                label: 'Sem preenchimento',
                values: _upTrend,
                showFill: false,
              ),
              Divider(height: 24),
              _SparklineRow(
                label: 'Sem ponto final',
                values: _upTrend,
                showEndDot: false,
              ),
              Divider(height: 24),
              _SparklineRow(
                label: 'Linha grossa',
                values: _upTrend,
                lineWidth: 3,
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),

        // Custom colors
        AppSectionCardWithHeading(
          title: '3. Cores customizadas',
          subtitle: 'Passando [color] diretamente.',
          child: Column(
            children: <Widget>[
              _SparklineRow(
                label: 'Primaria',
                values: _zigzag,
                color: cs.primary,
              ),
              const Divider(height: 24),
              _SparklineRow(
                label: 'Secundaria',
                values: _zigzag,
                color: cs.secondary,
              ),
              const Divider(height: 24),
              _SparklineRow(
                label: 'Terciaria',
                values: _zigzag,
                color: cs.tertiary,
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),

        // Heights
        const AppSectionCardWithHeading(
          title: '4. Alturas diferentes',
          subtitle: 'O widget preenche a largura disponivel.',
          child: Column(
            children: <Widget>[
              _SparklineRow(
                label: 'height: 28',
                values: _upTrend,
                height: 28,
              ),
              Divider(height: 24),
              _SparklineRow(
                label: 'height: 48',
                values: _upTrend,
                height: 48,
              ),
              Divider(height: 24),
              _SparklineRow(
                label: 'height: 72',
                values: _upTrend,
                height: 72,
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),

        // Embedded in KPI cards
        const AppSectionCardWithHeading(
          title: '5. Incorporado em KPI cards',
          subtitle:
              'Sparkline como trendWidget de AppMetricStatCard — '
              'padrao tipico de dashboard.',
          child: Column(
            children: <Widget>[
              AppMetricStatCard(
                leading: Icon(Icons.attach_money_rounded),
                trendLabel: '+12,4%',
                label: 'Faturamento',
                value: r'R$ 148,6 mil',
                trendWidget: SizedBox(
                  width: 80,
                  child: AppSparklineChart(
                    values: _upTrend,
                    height: 36,
                  ),
                ),
              ),
              Divider(height: 1),
              AppMetricStatCard(
                leading: Icon(Icons.assignment_return_outlined),
                trendLabel: '+0,8 p.p.',
                label: 'Devolucoes',
                value: '3,2%',
                trendWidget: SizedBox(
                  width: 80,
                  child: AppSparklineChart(
                    values: _downTrend,
                    height: 36,
                  ),
                ),
              ),
              Divider(height: 1),
              AppMetricStatCard(
                leading: Icon(Icons.star_border_rounded),
                trendLabel: '=',
                label: 'NPS',
                value: '72 pts',
                trendWidget: SizedBox(
                  width: 80,
                  child: AppSparklineChart(
                    values: _flatTrend,
                    height: 36,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),

        // Edge cases
        const AppSectionCardWithHeading(
          title: '6. Casos extremos',
          subtitle: 'Menos de 2 pontos renderiza espaco vazio sem erro.',
          child: Column(
            children: <Widget>[
              _SparklineRow(
                label: 'Sem dados (0 pontos)',
                values: <num>[],
              ),
              Divider(height: 24),
              _SparklineRow(
                label: 'Um ponto',
                values: <num>[42],
              ),
              Divider(height: 24),
              _SparklineRow(
                label: 'Valores iguais (sem variacao)',
                values: <num>[50, 50, 50, 50, 50],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SparklineRow extends StatelessWidget {
  const _SparklineRow({
    required this.label,
    required this.values,
    this.height = 40,
    this.lineWidth = 1.5,
    this.showFill = true,
    this.showEndDot = true,
    this.color,
  });

  final String label;
  final List<num> values;
  final double height;
  final double lineWidth;
  final bool showFill;
  final bool showEndDot;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: <Widget>[
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: AppSparklineChart(
            values: values,
            height: height,
            lineWidth: lineWidth,
            showFill: showFill,
            showEndDot: showEndDot,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sample data (demo only)
// ---------------------------------------------------------------------------

const List<num> _upTrend = <num>[
  42, 48, 45, 52, 58, 55, 63, 68, 72, 78,
];

const List<num> _downTrend = <num>[
  78, 72, 75, 68, 63, 67, 59, 55, 50, 44,
];

const List<num> _flatTrend = <num>[
  60, 63, 58, 62, 60, 64, 59, 61, 62, 60,
];

const List<num> _zigzag = <num>[
  40, 80, 35, 75, 45, 85, 50, 70, 40, 78,
];
