import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/metrics/app_compact_kpi_stat.dart';
import 'package:colmeia/shared/widgets/metrics/app_executive_metric_tile.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

/// Fake data demos for [AppCompactKpiStat] and [AppExecutiveMetricTile].
class AppCompactKpiAndExecutiveDemoPage extends StatelessWidget {
  const AppCompactKpiAndExecutiveDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Metricas',
          title: 'KPI compacto e executivo',
          subtitle:
              'Dados fake para inspecionar tipografia, espacamento e '
              'hierarquia.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'AppCompactKpiStat',
          subtitle: 'Faixa resumida em relatorios e listagens.',
          child: Row(
            children: <Widget>[
              const Expanded(
                child: AppCompactKpiStat(
                  label: 'Linhas',
                  value: '12',
                ),
              ),
              SizedBox(width: tokens.gapMd),
              const Expanded(
                child: AppCompactKpiStat(
                  label: 'Pedidos',
                  value: '773',
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Mais exemplos compactos',
          subtitle: 'Moeda e percentual.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const AppCompactKpiStat(
                label: 'Faturamento',
                value: r'R$ 268.074,12',
              ),
              SizedBox(height: tokens.gapMd),
              const AppCompactKpiStat(
                label: 'Variacao vs periodo anterior',
                value: '+12,4%',
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'AppExecutiveMetricTile',
          subtitle: 'Resumo executivo com detalhe em linha extra.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const AppExecutiveMetricTile(
                label: 'Faturamento liquido',
                value: r'R$ 1.284.920,00',
                detailLabel: 'Inclui devolucoes e descontos do periodo.',
              ),
              const AppExecutiveMetricTile(
                label: 'Ticket medio',
                value: r'R$ 347,80',
                detailLabel: 'Baseado em 3.698 pedidos fechados.',
                padding: EdgeInsets.zero,
              ),
              AppExecutiveMetricTile(
                label: 'Meta da loja',
                value: '94%',
                detailLabel:
                    'Padding customizado para encostar no fim da lista.',
                padding: EdgeInsets.only(top: tokens.gapSm),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
