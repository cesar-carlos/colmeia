import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

/// Demo for [AppCategoryDonutCard] (donut + legenda em card de dashboard).
class AppCategoryDonutCardDemoPage extends StatelessWidget {
  const AppCategoryDonutCardDemoPage({super.key});

  static const List<AppCategoryDonutSegment> _segmentsWithAmounts =
      <AppCategoryDonutSegment>[
        AppCategoryDonutSegment(
          label: 'Mercearia',
          value: 496_200,
          valueLabel: r'R$ 496.200',
          percentLabel: '40%',
        ),
        AppCategoryDonutSegment(
          label: 'Bebidas',
          value: 372_150,
          valueLabel: r'R$ 372.150',
          percentLabel: '30%',
        ),
        AppCategoryDonutSegment(
          label: 'Lanches',
          value: 248_100,
          valueLabel: r'R$ 248.100',
          percentLabel: '20%',
        ),
        AppCategoryDonutSegment(
          label: 'Outros',
          value: 124_050,
          valueLabel: r'R$ 124.050',
          percentLabel: '10%',
        ),
      ];

  static const List<AppCategoryDonutSegment> _segmentsPercentWeights =
      <AppCategoryDonutSegment>[
        AppCategoryDonutSegment(
          label: 'Canal A',
          value: 45,
          valueLabel: '45%',
          percentLabel: '45%',
        ),
        AppCategoryDonutSegment(
          label: 'Canal B',
          value: 30,
          valueLabel: '30%',
          percentLabel: '30%',
        ),
        AppCategoryDonutSegment(
          label: 'Canal C',
          value: 25,
          valueLabel: '25%',
          percentLabel: '25%',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final accent = theme.colorScheme.primary;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Dashboard',
          title: 'AppCategoryDonutCard',
          subtitle:
              'Donut com centro opcional, legenda responsiva, selecao '
              'sincronizada, skeleton no carregamento, semantica e callbacks '
              'de toque consistentes.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppCategoryDonutCard(
          title: 'Vendas por categoria',
          subtitle: 'Montantes como pesos do arco; centro = soma.',
          segments: _segmentsWithAmounts,
          centerPrimaryLabel: AppBrFormatters.compactCurrency(1_240_500),
          centerSecondaryLabel: 'TOTAL ANUAL',
          titleAccentColor: accent,
          titleTrailing: IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Menu',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menu de exemplo.')),
              );
            },
          ),
          onSegmentTap: (segment, index) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${index + 1}. ${segment.label}')),
            );
          },
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Somente pesos relativos',
          subtitle:
              'Mesmo componente com valores exibidos como percentual; util '
              'quando a API ainda nao envia moeda.',
          child: AppCategoryDonutCard(
            title: 'Mix por canal',
            segments: _segmentsPercentWeights,
            centerPrimaryLabel: '100%',
            centerSecondaryLabel: 'PARTICIPACAO',
            titleAccentColor: accent,
            style: const AppCategoryDonutCardStyle(
              compactBreakpointWidth: 480,
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppSectionCardWithHeading(
          title: 'Estado carregando',
          subtitle:
              'Placeholder em formato de rosca + linhas (Skeletonizer); '
              'rotulo de leitor de tela via loadingSemanticsLabel.',
          child: AppCategoryDonutCard(
            title: 'Carregando exemplo',
            segments: _segmentsWithAmounts,
            isLoading: true,
            loadingSemanticsLabel: 'Carregando mix por categoria...',
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppSectionCardWithHeading(
          title: 'Estado vazio',
          subtitle: 'Lista vazia: mensagem dentro do card.',
          child: AppCategoryDonutCard(
            title: 'Sem dados',
            segments: <AppCategoryDonutSegment>[],
            emptyPlaceholder: Text('Nenhuma categoria neste periodo.'),
          ),
        ),
      ],
    );
  }
}
