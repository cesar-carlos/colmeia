import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_treemap_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppTreemapChartDemoPage extends StatefulWidget {
  const AppTreemapChartDemoPage({super.key});

  @override
  State<AppTreemapChartDemoPage> createState() =>
      _AppTreemapChartDemoPageState();
}

class _AppTreemapChartDemoPageState extends State<AppTreemapChartDemoPage> {
  String? _selectionSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Graficos treemap',
          title: 'AppTreemapChart',
          subtitle:
              'Usa area para mostrar participacao relativa e agrupamento, '
              'muito '
              'util em mix de vendas, clusters, portfolio e distribuicao.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppTreemapChart<_TreemapMetric>(
          title: '1. Receita por categoria',
          subtitle: 'Cada bloco representa a participacao da categoria.',
          items: _categoryRevenue,
          groupBuilder: (item) => item.group,
          weightValueBuilder: (item) => item.weight,
          colorValueBuilder: (item) => item.colorMetric,
          colorRanges: const <AppTreemapColorRange>[
            AppTreemapColorRange(
              from: 0,
              to: 0.2,
              color: Color(0xFFD9485F),
              name: 'Baixa margem',
            ),
            AppTreemapColorRange(
              from: 0.2001,
              to: 0.35,
              color: Color(0xFFF6B93B),
              name: 'Margem media',
            ),
            AppTreemapColorRange(
              from: 0.3501,
              to: 1,
              color: Color(0xFF2ECC71),
              name: 'Alta margem',
            ),
          ],
          labelBuilder: (node) =>
              '${node.group}\n${AppBrFormatters.compactCurrency(node.weight)}',
          tooltipLabelBuilder: (node) =>
              '${node.group}: ${AppBrFormatters.currency(node.weight)}',
          style: const AppTreemapChartStyle(
            showLegend: true,
            useBarLegend: true,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: '2. Hierarquia com selecao',
          subtitle:
              _selectionSummary ??
              'Categoria principal com subcategoria interna e callback '
                  'de selecao.',
          child: AppTreemapChart<_TreemapMetric>(
            items: _categoryBySubgroup,
            groupBuilder: (item) => item.group,
            subgroupBuilder: (item) => item.subgroup,
            weightValueBuilder: (item) => item.weight,
            colorValueBuilder: (item) => item.colorMetric,
            colorRanges: const <AppTreemapColorRange>[
              AppTreemapColorRange(
                from: 0,
                to: 0.2,
                color: Color(0xFFD9485F),
                name: 'Baixa',
              ),
              AppTreemapColorRange(
                from: 0.2001,
                to: 0.35,
                color: Color(0xFFF6B93B),
                name: 'Media',
              ),
              AppTreemapColorRange(
                from: 0.3501,
                to: 1,
                color: Color(0xFF2ECC71),
                name: 'Alta',
              ),
            ],
            onTileSelected: (node) {
              setState(() {
                _selectionSummary =
                    'Selecionado: ${node.group} '
                    '(${AppBrFormatters.compactCurrency(node.weight)})';
              });
            },
            labelBuilder: (node) =>
                '${node.group}\n'
                '${AppBrFormatters.compactCurrency(node.weight)}',
            style: AppTreemapChartStyle(
              layout: AppTreemapLayoutAlgorithm.slice,
              selectionColor: cs.primary.withValues(alpha: 0.24),
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppSectionCardWithHeading(
          title: '3. Preset compacto',
          subtitle: 'Boa opcao para cards analiticos resumidos.',
          child: AppTreemapChart<_TreemapMetric>(
            items: _categoryRevenue,
            groupBuilder: _treemapGroup,
            weightValueBuilder: _treemapWeight,
            preset: AppChartPreset.compact,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppTreemapChart<String>(
          title: '4. Estado de loading',
          items: <String>[],
          groupBuilder: _identity,
          weightValueBuilder: _zero,
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppTreemapChart<String>(
          title: '5. Estado vazio',
          items: const <String>[],
          groupBuilder: _identity,
          weightValueBuilder: _zero,
          emptyPlaceholder: Text(
            'Nenhum bloco disponivel para este recorte.',
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

double _zero(String _) => 0;

String _treemapGroup(_TreemapMetric item) => item.group;

double _treemapWeight(_TreemapMetric item) => item.weight;

class _TreemapMetric {
  const _TreemapMetric({
    required this.group,
    required this.subgroup,
    required this.weight,
    required this.colorMetric,
  });

  final String group;
  final String subgroup;
  final double weight;
  final double colorMetric;
}

const List<_TreemapMetric> _categoryRevenue = <_TreemapMetric>[
  _TreemapMetric(
    group: 'Mercearia',
    subgroup: 'Mercearia',
    weight: 320000,
    colorMetric: 0.22,
  ),
  _TreemapMetric(
    group: 'Pereciveis',
    subgroup: 'Pereciveis',
    weight: 210000,
    colorMetric: 0.37,
  ),
  _TreemapMetric(
    group: 'Bebidas',
    subgroup: 'Bebidas',
    weight: 185000,
    colorMetric: 0.29,
  ),
  _TreemapMetric(
    group: 'Higiene',
    subgroup: 'Higiene',
    weight: 142000,
    colorMetric: 0.41,
  ),
  _TreemapMetric(
    group: 'Limpeza',
    subgroup: 'Limpeza',
    weight: 119000,
    colorMetric: 0.33,
  ),
];

const List<_TreemapMetric> _categoryBySubgroup = <_TreemapMetric>[
  _TreemapMetric(
    group: 'Mercearia',
    subgroup: 'Massas',
    weight: 98000,
    colorMetric: 0.19,
  ),
  _TreemapMetric(
    group: 'Mercearia',
    subgroup: 'Enlatados',
    weight: 76000,
    colorMetric: 0.23,
  ),
  _TreemapMetric(
    group: 'Mercearia',
    subgroup: 'Graos',
    weight: 146000,
    colorMetric: 0.25,
  ),
  _TreemapMetric(
    group: 'Pereciveis',
    subgroup: 'Frios',
    weight: 82000,
    colorMetric: 0.39,
  ),
  _TreemapMetric(
    group: 'Pereciveis',
    subgroup: 'Laticinios',
    weight: 69000,
    colorMetric: 0.36,
  ),
  _TreemapMetric(
    group: 'Pereciveis',
    subgroup: 'Padaria',
    weight: 59000,
    colorMetric: 0.33,
  ),
  _TreemapMetric(
    group: 'Bebidas',
    subgroup: 'Refrigerante',
    weight: 74000,
    colorMetric: 0.27,
  ),
  _TreemapMetric(
    group: 'Bebidas',
    subgroup: 'Energetico',
    weight: 42000,
    colorMetric: 0.35,
  ),
  _TreemapMetric(
    group: 'Bebidas',
    subgroup: 'Agua',
    weight: 69000,
    colorMetric: 0.3,
  ),
];
