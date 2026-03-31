import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:colmeia/shared/widgets/navigation/app_tab_view.dart';
import 'package:flutter/material.dart';

class AppTabViewDemoPage extends StatelessWidget {
  const AppTabViewDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Navegacao',
          title: 'Tab View',
          subtitle:
              'Abas horizontais com indicador leve, conteudo inline e leitura '
              'consistente em light e dark mode.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        const _TabViewShowcaseCard(),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Overflow horizontal',
          subtitle:
              'Quando houver muitas secoes, o componente permite scroll '
              'horizontal sem quebrar o ritmo da superficie.',
          child: AppTabView(
            items: const <AppTabViewItem>[
              AppTabViewItem(
                label: 'Visao geral',
                child: _TabContent(
                  title: 'Resumo da operacao',
                  message:
                      'KPIs principais, alertas e leitura rapida para a rotina '
                      'da loja ativa.',
                ),
              ),
              AppTabViewItem(
                label: 'Performance',
                child: _TabContent(
                  title: 'Performance comercial',
                  message:
                      'Comparativos de vendas, margem e conversao com foco em '
                      'tendencia e desvio.',
                ),
              ),
              AppTabViewItem(
                label: 'Operacao',
                child: _TabContent(
                  title: 'Indicadores operacionais',
                  message:
                      'Monitoramento de ruptura, estoque, tempo medio e '
                      'produtividade por equipe.',
                ),
              ),
              AppTabViewItem(
                label: 'Financeiro',
                child: _TabContent(
                  title: 'Saude financeira',
                  message:
                      'Fluxo, inadimplencia, despesas e metas por centro de '
                      'resultado.',
                ),
              ),
              AppTabViewItem(
                label: 'Recursos',
                child: _TabContent(
                  title: 'Materiais de apoio',
                  message:
                      'Acesso a anexos, docs, exportacoes e referencias da '
                      'analise corrente.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabViewShowcaseCard extends StatelessWidget {
  const _TabViewShowcaseCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return AppSectionCardWithHeading(
      padding: EdgeInsets.fromLTRB(
        tokens.contentSpacing,
        tokens.contentSpacing,
        tokens.contentSpacing,
        tokens.contentSpacing + tokens.gapSm,
      ),
      titleWidget: _TabViewShowcaseHeading(theme: theme, tokens: tokens),
      subtitle:
          'Padrao recomendado para alternar secoes irmas na mesma superficie '
          'sem recorrer a cards paralelos.',
      headingTrailing: const _TabViewShowcaseBadge(),
      headingBottom: const _TabViewShowcaseLegend(),
      style: AppSectionCardWithHeadingStyle(
        headerBottomSpacing: tokens.sectionSpacing,
      ),
      child: AppTabView(
        items: const <AppTabViewItem>[
          AppTabViewItem(
            label: 'Overview',
            child: _TabContent(
              title: 'Overview',
              message: 'Sample tab content area for the current selection.',
            ),
          ),
          AppTabViewItem(
            label: 'Performance',
            child: _TabContent(
              title: 'Performance',
              message:
                  'Track conversion, margin and operational efficiency for the '
                  'current context.',
            ),
          ),
          AppTabViewItem(
            label: 'Resources',
            child: _TabContent(
              title: 'Resources',
              message:
                  'Surface supporting docs, exports, and contextual guidance '
                  'for '
                  'the selected view.',
            ),
          ),
        ],
      ),
    );
  }
}

class _TabViewShowcaseHeading extends StatelessWidget {
  const _TabViewShowcaseHeading({required this.theme, required this.tokens});

  final ThemeData theme;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Navigation Pattern',
          style: theme.appTypography.utilityOverline.copyWith(
            color: cs.primary,
          ),
        ),
        SizedBox(height: tokens.gapXs),
        Row(
          children: <Widget>[
            Icon(Icons.tab_rounded, color: cs.primary, size: 18),
            SizedBox(width: tokens.gapSm),
            Expanded(
              child: Text(
                'Tab Navigation',
                style: theme.appTypography.sectionHeaderH2.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TabViewShowcaseBadge extends StatelessWidget {
  const _TabViewShowcaseBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(tokens.formFieldRadius + 6),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapMd,
          vertical: tokens.gapXs,
        ),
        child: Text(
          'New',
          style: theme.appTypography.utilityOverline.copyWith(
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}

class _TabViewShowcaseLegend extends StatelessWidget {
  const _TabViewShowcaseLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Wrap(
      spacing: tokens.gapSm,
      runSpacing: tokens.gapSm,
      children: const <Widget>[
        _TabViewLegendChip(label: 'Inline'),
        _TabViewLegendChip(label: 'Scrollable'),
        _TabViewLegendChip(label: 'Light/Dark'),
      ],
    );
  }
}

class _TabViewLegendChip extends StatelessWidget {
  const _TabViewLegendChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(tokens.formFieldRadius + 4),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapMd,
          vertical: tokens.gapXs,
        ),
        child: Text(
          label,
          style: theme.appTypography.utilityOverline.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.appTypography.sectionHeaderH2.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: tokens.gapSm),
        Text(
          message,
          style: theme.appTypography.body.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
