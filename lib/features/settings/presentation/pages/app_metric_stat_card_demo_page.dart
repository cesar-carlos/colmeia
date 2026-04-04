import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/metrics/app_metric_stat_card.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppMetricStatCardDemoPage extends StatelessWidget {
  const AppMetricStatCardDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Metricas',
          title: 'AppMetricStatCard',
          subtitle:
              'Layout stacked: titulo + icone no topo, valor, tendencia embaixo'
              ' (texto "vs ..." em cinza). Layout classic para sparklines. '
              'Enfase hero/accent, tooltip, tap e AppMetricStatCardStyle.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Exemplo interativo',
          subtitle: 'Tooltip, tap, pill de variacao e semantica com valor.',
          headingTrailing: Icon(
            Icons.auto_awesome_outlined,
            color: theme.colorScheme.primary,
          ),
          child: AppMetricStatCard(
            leading: Icon(
              Icons.payments_outlined,
              color: theme.colorScheme.onPrimaryContainer,
              size: 22,
            ),
            trendLabel: '+8,9%',
            label: 'Total de vendas',
            value: r'R$ 169.592',
            emphasis: AppMetricStatCardEmphasis.hero,
            tooltipMessage: 'Resumo consolidado do periodo atual.',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('KPI tocado')),
              );
            },
            style: AppMetricStatCardStyle(
              cardPadding: EdgeInsets.all(tokens.contentSpacing),
              topRowBottomSpacing: tokens.contentSpacing,
              borderSide: tokens.cardOutlineBorderSide(theme.colorScheme),
              labelTextStyle: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
              valueTextStyle: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Enfases e variacao neutra',
          subtitle:
              'Hero (marca), accent (suave), padrao; delta ~0% em pill neutra.',
          child: Column(
            children: <Widget>[
              AppMetricStatCard(
                leading: Icon(
                  Icons.payments_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 22,
                ),
                trendLabel: '+12% vs período anterior',
                label: 'TOTAL VENDAS',
                value: r'R$ 142,8k',
                emphasis: AppMetricStatCardEmphasis.hero,
              ),
              Divider(height: tokens.contentSpacing * 2),
              AppMetricStatCard(
                leading: Icon(
                  Icons.receipt_long_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 22,
                ),
                trendLabel: '+2%',
                label: 'TICKET MEDIO',
                value: r'R$ 84,20',
                emphasis: AppMetricStatCardEmphasis.accent,
              ),
              Divider(height: tokens.contentSpacing * 2),
              AppMetricStatCard(
                leading: Icon(
                  Icons.show_chart_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                trendLabel: '+0,0%',
                label: 'SEM VARIACAO',
                value: '100%',
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Sem delta e texto plano',
          subtitle:
              'Apenas icone no topo quando nao ha variacao; texto sem pill.',
          child: Column(
            children: <Widget>[
              AppMetricStatCard(
                leading: Icon(
                  Icons.inventory_2_outlined,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                label: 'Estoque monitorado',
                value: '1.284 SKUs',
              ),
              Divider(height: tokens.contentSpacing * 2),
              AppMetricStatCard(
                leading: Icon(
                  Icons.trending_down,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                trendLabel: '-0,8%',
                label: 'Rentabilidade',
                value: '24,5%',
                showTrendPill: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
