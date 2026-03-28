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
          subtitle: 'Barras, serie temporal, distribuicao e progresso.',
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
            subtitle:
                'AppInlineErrorPanel, InlineAlertBanner e AppSkeleton.',
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
