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
              'KPI com icone, variacao, tooltip e estilos opcionais '
              '(AppMetricStatCardStyle).',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Exemplo interativo',
          subtitle: 'Tooltip, tap e estilos customizados.',
          headingTrailing: Icon(
            Icons.auto_awesome_outlined,
            color: theme.colorScheme.primary,
          ),
          child: AppMetricStatCard(
            leading: Icon(
              Icons.payments_outlined,
              color: theme.colorScheme.primary,
              size: 22,
            ),
            trendLabel: '+8,9%',
            label: 'Total de vendas',
            value: r'R$ 169.592',
            tooltipMessage: 'Resumo consolidado do periodo atual.',
            semanticsLabel: 'Total de vendas, abrir detalhes',
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
                color: theme.colorScheme.onSurfaceVariant,
              ),
              valueTextStyle: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
