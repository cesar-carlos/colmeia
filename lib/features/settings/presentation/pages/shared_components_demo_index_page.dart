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
          title: 'Graficos',
          subtitle:
              'Barras, radial bar, gauge, sunburst, funnel, pyramid, polar, '
              'treemap, radar, waterfall, bullet, heatmap, scatter/bubble, '
              'range area, step line, area, empilhado, combo, serie temporal, '
              'sparkline, distribuicao e progresso.',
          child: Column(
            children: <Widget>[
              _DemoEntryTile(
                icon: Icons.bar_chart_rounded,
                title: 'Grafico de barras (comparativo)',
                subtitle: 'Barras verticais, cor por item, loading e empty.',
                onTap: () => context.push(appComparisonBarChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.stacked_bar_chart_rounded,
                title: 'Barras empilhadas',
                subtitle:
                    'Vertical, horizontal, 100%, onGroupTap e paleta '
                    'automatica.',
                onTap: () => context.push(appStackedBarChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.area_chart_rounded,
                title: 'Tendencia de area',
                subtitle:
                    'Series unica e multi-series com trackball, '
                    'gradiente e marcadores.',
                onTap: () => context.push(appAreaTrendChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.insert_chart_outlined_rounded,
                title: 'Grafico combinado (barra + linha)',
                subtitle: 'Dois eixos, data labels, onBarTap e onLineTap.',
                onTap: () => context.push(appComboChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.account_tree_outlined,
                title: 'Waterfall',
                subtitle:
                    'Ponte de variacao com positivos, negativos, '
                    'subtotal e total.',
                onTap: () => context.push(appWaterfallChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.straighten_rounded,
                title: 'Bullet chart',
                subtitle:
                    'Realizado vs meta com faixas qualitativas '
                    'e toque por linha.',
                onTap: () => context.push(appBulletChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.grid_on_rounded,
                title: 'Heatmap',
                subtitle:
                    'Matriz de calor para dia x hora, loja x etapa '
                    'e densidade operacional.',
                onTap: () => context.push(appHeatmapChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.bubble_chart_rounded,
                title: 'Scatter / Bubble',
                subtitle: 'Correlacao entre metricas com pontos ou bolhas.',
                onTap: () => context.push(appScatterBubbleChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.show_chart_rounded,
                title: 'Range area',
                subtitle:
                    'Faixa minima/maxima para previsao, temperatura '
                    'ou banda de confianca.',
                onTap: () => context.push(appRangeAreaChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.filter_alt_rounded,
                title: 'Funnel',
                subtitle:
                    'Conversao por etapa para pipeline comercial, onboarding '
                    'e processos operacionais.',
                onTap: () => context.push(appFunnelChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.speed_rounded,
                title: 'Gauge',
                subtitle:
                    'Leitura instrumental para SLA, ocupacao, metas e alertas '
                    'operacionais.',
                onTap: () => context.push(appGaugeChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.change_history_rounded,
                title: 'Pyramid',
                subtitle:
                    'Hierarquia de volume para capacidade, senioridade e mix '
                    'por faixa.',
                onTap: () => context.push(appPyramidChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.stacked_line_chart_rounded,
                title: 'Step line',
                subtitle:
                    'Linha em degraus para eventos discretos, mudancas de '
                    'faixa e ocupacao.',
                onTap: () => context.push(appStepLineChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.radar_rounded,
                title: 'Polar',
                subtitle:
                    'Leitura circular por eixo angular para intensidade e '
                    'sazonalidade radial.',
                onTap: () => context.push(appPolarChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.donut_small_rounded,
                title: 'Radial bar',
                subtitle:
                    'Progresso por categoria em aneis concentricos para score, '
                    'SLA e aderencia.',
                onTap: () => context.push(appRadialBarChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.track_changes_rounded,
                title: 'Radar',
                subtitle:
                    'Comparativo multidimensional para scorecards, maturidade '
                    'e benchmark de lojas.',
                onTap: () => context.push(appRadarChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.blur_circular_rounded,
                title: 'Sunburst',
                subtitle:
                    'Hierarquia radial para categorias, centros de custo e '
                    'carteiras exploraveis.',
                onTap: () => context.push(appSunburstChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.dashboard_customize_rounded,
                title: 'Treemap',
                subtitle:
                    'Participacao por area para mix de vendas, portfolio '
                    'e agrupamentos.',
                onTap: () => context.push(appTreemapChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.trending_up_rounded,
                title: 'Sparkline (micro grafico)',
                subtitle: 'Linha de tendencia inline para KPI cards e tabelas.',
                onTap: () => context.push(appSparklineChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.show_chart_rounded,
                title: 'Serie temporal',
                subtitle: 'Curva temporal com preset, estilo, loading e empty.',
                onTap: () => context.push(appTimeSeriesChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.donut_large_rounded,
                title: 'Distribuicao',
                subtitle: 'Donut chart com legenda, tooltip, loading e empty.',
                onTap: () => context.push(appDistributionChartDemoLocation),
              ),
              const Divider(height: 1),
              _DemoEntryTile(
                icon: Icons.waterfall_chart_rounded,
                title: 'Grafico horizontal de progresso',
                subtitle:
                    'Percentual, valores absolutos, metas, loading e empty.',
                onTap: () => context.push(horizontalProgressChartDemoLocation),
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
                icon: Icons.swap_horiz_rounded,
                title: 'Paginacao inline',
                subtitle: 'AppInlinePaginationBar com centro customizavel.',
                onTap: () => context.push(appInlinePaginationDemoLocation),
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
                'AppPrimaryButton, AppSecondaryButton, AppFlatButton, '
                'AppTextActionButton.',
            onTap: () => context.push(appButtonsDemoLocation),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Feedback e estados',
          subtitle: 'Erros, alertas e skeleton.',
          child: _DemoEntryTile(
            icon: Icons.notifications_active_outlined,
            title: 'Painel de erro, banner e skeleton',
            subtitle: 'AppInlineErrorPanel, InlineAlertBanner e AppSkeleton.',
            onTap: () => context.push(appFeedbackDemoLocation),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Formularios',
          subtitle: 'Campos e escolhas.',
          child: _DemoEntryTile(
            icon: Icons.edit_note_rounded,
            title: 'Campos compartilhados',
            subtitle:
                'AppTextField, AppEmailField, AppPasswordField, '
                'AppCheckboxField e AppRadioGroup.',
            onTap: () => context.push(appFormsDemoLocation),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: cs.primary),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
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
