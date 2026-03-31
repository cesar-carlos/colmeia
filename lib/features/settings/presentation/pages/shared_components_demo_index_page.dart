import 'package:colmeia/features/settings/presentation/routes/settings_routes.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Entry point for shared-widget demos grouped by category.
class SharedComponentsDemoIndexPage extends StatelessWidget {
  const SharedComponentsDemoIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Componentes compartilhados',
          title: 'Cardapio de UI',
          subtitle:
              'Demos com dados fake: graficos, metricas, botoes, feedback, '
              'formularios e perfil.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Foundations',
          subtitle: 'Tokens base para linguagem visual e consistencia do app.',
          child: _DemoEntryTile(
            icon: Icons.text_fields_rounded,
            title: 'Typography',
            subtitle:
                'Display H1, Section Header H2, Body, Caption e Utility '
                'Overline em light/dark.',
            onTap: () => context.push(appTypographyDemoLocation),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Graficos',
          subtitle:
              'Catalogo com callbacks estruturados, presets compactos, estados '
              'de loading/empty e variacoes responsivas para leitura analitica.',
          child: Column(
            children: <Widget>[
              _DemoEntryTile(
                icon: Icons.bar_chart_rounded,
                title: 'Grafico de barras (comparativo)',
                subtitle:
                    'Barras verticais com toque estruturado por item, loading '
                    'e empty.',
                onTap: () => context.push(appComparisonBarChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.stacked_bar_chart_rounded,
                title: 'Barras empilhadas',
                subtitle:
                    'Vertical, horizontal e 100% com eventos estruturados por '
                    'grupo/segmento e paleta automatica.',
                onTap: () => context.push(appStackedBarChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.area_chart_rounded,
                title: 'Tendencia de area',
                subtitle:
                    'Series unica e multi-series com trackball, gradiente, '
                    'marcadores e tap estruturado por serie.',
                onTap: () => context.push(appAreaTrendChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.insert_chart_outlined_rounded,
                title: 'Grafico combinado (barra + linha)',
                subtitle:
                    'Dois eixos, data labels e eventos estruturados para barra '
                    'e linha.',
                onTap: () => context.push(appComboChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.account_tree_outlined,
                title: 'Waterfall',
                subtitle:
                    'Ponte de variacao com positivos, negativos, subtotal, '
                    'total e callback estruturado por etapa.',
                onTap: () => context.push(appWaterfallChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.straighten_rounded,
                title: 'Bullet chart',
                subtitle:
                    'Realizado vs meta com faixas qualitativas e toque '
                    'estruturado por linha.',
                onTap: () => context.push(appBulletChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.grid_on_rounded,
                title: 'Heatmap',
                subtitle:
                    'Matriz de calor com evento estruturado por celula, '
                    'scroll horizontal e leitura em cenarios compactos.',
                onTap: () => context.push(appHeatmapChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.bubble_chart_rounded,
                title: 'Scatter / Bubble',
                subtitle:
                    'Correlacao entre metricas com pontos ou bolhas e toque '
                    'estruturado por item.',
                onTap: () => context.push(appScatterBubbleChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.show_chart_rounded,
                title: 'Range area',
                subtitle:
                    'Faixa minima/maxima para previsao com trackball, preset '
                    'compacto e tap estruturado.',
                onTap: () => context.push(appRangeAreaChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.filter_alt_rounded,
                title: 'Funnel',
                subtitle:
                    'Conversao por etapa com toque estruturado para pipeline, '
                    'onboarding e processos.',
                onTap: () => context.push(appFunnelChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.speed_rounded,
                title: 'Gauge',
                subtitle:
                    'Leitura instrumental com toque no gauge, payload '
                    'estruturado e anotacao adaptada a layouts compactos.',
                onTap: () => context.push(appGaugeChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.change_history_rounded,
                title: 'Pyramid',
                subtitle:
                    'Hierarquia de volume com toque estruturado por segmento e '
                    'uso compacto em cards.',
                onTap: () => context.push(appPyramidChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.stacked_line_chart_rounded,
                title: 'Step line',
                subtitle:
                    'Linha em degraus com eventos estruturados por serie/ponto '
                    'e presets compactos.',
                onTap: () => context.push(appStepLineChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.radar_rounded,
                title: 'Polar',
                subtitle:
                    'Leitura circular por eixo angular com evento estruturado '
                    'por categoria e serie.',
                onTap: () => context.push(appPolarChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.donut_small_rounded,
                title: 'Radial bar',
                subtitle:
                    'Progresso por categoria em aneis concentricos com toque '
                    'estruturado e leitura resumida.',
                onTap: () => context.push(appRadialBarChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.track_changes_rounded,
                title: 'Radar',
                subtitle:
                    'Comparativo multidimensional com evento estruturado por '
                    'categoria e boa leitura em cards.',
                onTap: () => context.push(appRadarChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.blur_circular_rounded,
                title: 'Sunburst',
                subtitle:
                    'Hierarquia radial com tap estruturado por segmento e '
                    'resumo central adaptado.',
                onTap: () => context.push(appSunburstChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.dashboard_customize_rounded,
                title: 'Treemap',
                subtitle:
                    'Participacao por area com selecao estruturada e variacoes '
                    'de layout para agrupamentos.',
                onTap: () => context.push(appTreemapChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.trending_up_rounded,
                title: 'Sparkline (micro grafico)',
                subtitle:
                    'Linha inline com evento estruturado, uso em KPI cards e '
                    'layout responsivo nas demos.',
                onTap: () => context.push(appSparklineChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.show_chart_rounded,
                title: 'Serie temporal',
                subtitle:
                    'Curva temporal com tap estruturado por ponto, preset, '
                    'loading e empty.',
                onTap: () => context.push(appTimeSeriesChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.donut_large_rounded,
                title: 'Distribuicao',
                subtitle:
                    'Donut chart com evento estruturado por segmento, legenda, '
                    'tooltip, loading e empty.',
                onTap: () => context.push(appDistributionChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.waterfall_chart_rounded,
                title: 'Grafico horizontal de progresso',
                subtitle:
                    'Percentual, valores absolutos, metas, toque estruturado e '
                    'layout adaptado para largura curta.',
                onTap: () => context.push(horizontalProgressChartDemoLocation),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Mapas',
          subtitle:
              'Mapas territoriais para navegacao analitica por regiao e '
              'integracao com dashboards.',
          child: Column(
            children: <Widget>[
              _DemoEntryTile(
                icon: Icons.map_rounded,
                title: 'Mapa territorial interativo',
                subtitle:
                    'Navegacao por regiao com troca de metrica, selecao '
                    'estruturada e integracao com dashboards.',
                onTap: () => context.push(appRegionMapChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.layers_rounded,
                title: 'Mapa com drill-down (simulado)',
                subtitle:
                    'Exemplo de navegacao entre niveis territoriais '
                    '(regiao -> estado) com eventos tipados.',
                badgeText: 'Novo',
                onTap: () => context.push(appRegionMapDrilldownDemoLocation),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Metricas',
          subtitle: 'KPIs e faixas compactas.',
          child: Column(
            children: <Widget>[
              _DemoEntryTile(
                icon: Icons.insights_outlined,
                title: 'Card de metrica (KPI)',
                subtitle: 'AppMetricStatCard com tooltip, toque e estilos.',
                onTap: () => context.push(appMetricStatCardDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.table_rows_rounded,
                title: 'KPI compacto e metrica executiva',
                subtitle:
                    'AppCompactKpiStat e AppExecutiveMetricTile (dados fake).',
                onTap: () => context.push(appCompactKpiExecutiveDemoLocation),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Layout e paginacao',
          subtitle: 'Secoes e controles de lista.',
          child: Column(
            children: <Widget>[
              _DemoEntryTile(
                icon: Icons.view_day_outlined,
                title: 'Secao com titulo',
                subtitle: 'AppSectionCardWithHeading e composicao de header.',
                onTap: () => context.push(appSectionCardHeadingDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.photo_library_outlined,
                title: 'Card editorial com midia',
                subtitle:
                    'Hero visual no topo com bloco editorial abaixo para '
                    'storytelling e destaques de produto.',
                badgeText: 'Novo',
                onTap: () => context.push(appEditorialMediaCardDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.tab_rounded,
                title: 'Tab view',
                subtitle:
                    'Navegacao horizontal com indicador slim, conteudo inline '
                    'e suporte a overflow.',
                badgeText: 'Novo',
                onTap: () => context.push(appTabViewDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.swap_horiz_rounded,
                title: 'Paginacao inline',
                subtitle: 'AppInlinePaginationBar com centro customizavel.',
                onTap: () => context.push(appInlinePaginationDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.table_rows_outlined,
                title: 'Rodape de tabela (paginacao)',
                subtitle:
                    'Itens por pagina, resumo e numeros com estilo de grid.',
                onTap: () => context.push(appTablePaginationFooterDemoLocation),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Botoes e acoes',
          subtitle: 'Primario, secundario, flat e texto.',
          child: _DemoEntryTile(
            icon: Icons.smart_button_outlined,
            title: 'Biblioteca de botoes',
            subtitle:
                'AppPrimaryButton, AppSecondaryButton, AppDestructiveButton, '
                'AppFlatButton, '
                'AppTextActionButton.',
            onTap: () => context.push(appButtonsDemoLocation),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Feedback e estados',
          subtitle: 'Erros, alertas e skeleton.',
          child: Column(
            children: <Widget>[
              _DemoEntryTile(
                icon: Icons.notifications_active_outlined,
                title: 'Painel de erro, banner e skeleton',
                subtitle:
                    'AppInlineErrorPanel, InlineAlertBanner e AppSkeleton.',
                onTap: () => context.push(appFeedbackDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.label_rounded,
                title: 'Tags e status',
                subtitle:
                    'AppTagChip e AppStatusBadge para metadata e estados '
                    'semanticos.',
                badgeText: 'Novo',
                onTap: () => context.push(appBadgesDemoLocation),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Formularios',
          subtitle: 'Campos de texto, datas e FormBuilder.',
          child: Column(
            children: <Widget>[
              _DemoEntryTile(
                icon: Icons.edit_note_rounded,
                title: 'Campos de texto e escolhas',
                subtitle:
                    'AppTextField, AppEmailField, AppPasswordField, '
                    'AppCheckboxField e AppRadioGroup.',
                onTap: () => context.push(appFormsDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.tune_rounded,
                title: 'Segmented control',
                subtitle:
                    'AppSegmentedControl para filtros inline de selecao unica '
                    'com labels curtas ou longas.',
                badgeText: 'Novo',
                onTap: () => context.push(appSegmentedControlDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.calendar_month_rounded,
                title: 'Date pickers',
                subtitle:
                    'Data unica e intervalo (Syncfusion), validacao no form e '
                    'campos FormBuilder como nos relatorios.',
                onTap: () => context.push(appFormsDemoLocation),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Perfil',
          subtitle: 'Titulos, status e linhas de dados.',
          child: _DemoEntryTile(
            icon: Icons.person_outline_rounded,
            title: 'Widgets de perfil',
            subtitle:
                'AppProfileSectionTitle, AppProfileStatusPill, '
                'AppProfileStaticField e AppProfileInteractiveField.',
            onTap: () => context.push(appProfileWidgetsDemoLocation),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Tabelas e relatorios',
          subtitle: 'Grid ERP generico com filtros, paginacao e export.',
          child: _DemoEntryTile(
            icon: Icons.table_view_rounded,
            title: 'AppReportViewer',
            subtitle:
                'Grid interativo com filtros, ordenacao, paginacao, '
                'export PDF/Excel e chooser de colunas.',
            onTap: () => context.push(appReportViewerDemoLocation),
          ),
        ),
      ],
    );
  }
}

class _DemoEntryTile extends StatelessWidget {
  const _DemoEntryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: cs.primary),
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badgeText!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: cs.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
