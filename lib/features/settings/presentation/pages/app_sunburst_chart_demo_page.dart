import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_sunburst_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppSunburstChartDemoPage extends StatefulWidget {
  const AppSunburstChartDemoPage({super.key});

  @override
  State<AppSunburstChartDemoPage> createState() =>
      _AppSunburstChartDemoPageState();
}

class _AppSunburstChartDemoPageState extends State<AppSunburstChartDemoPage> {
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
          eyebrow: 'Graficos sunburst',
          title: 'AppSunburstChart',
          subtitle:
              'Mostra hierarquia e participacao relativa '
              'em aneis concentricos, '
              'boa para mix por categoria, contas por centro de custo e '
              'exploracao de carteira.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSunburstChart<_SunburstMetric>(
          title: '1. Receita por categoria e subcategoria',
          subtitle:
              'Da visao macro para o detalhe em uma unica leitura radial.',
          items: _revenueTree,
          idBuilder: (item) => item.id,
          labelBuilder: (item) => item.label,
          valueBuilder: (item) => item.value,
          parentIdBuilder: (item) => item.parentId,
          centerLabel: 'Receita total',
          onSegmentTap: (node) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${node.label}: '
                  '${AppBrFormatters.compactCurrency(node.totalValue)}',
                ),
              ),
            );
          },
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: '2. Hierarquia de OPEX com selecao',
          subtitle:
              _selectionSummary ??
              'Tap em qualquer anel para destacar a fatia selecionada.',
          child: AppSunburstChart<_SunburstMetric>(
            items: _opexTree(cs),
            idBuilder: (item) => item.id,
            labelBuilder: (item) => item.label,
            valueBuilder: (item) => item.value,
            parentIdBuilder: (item) => item.parentId,
            colorBuilder: (item) => item.color,
            centerLabel: 'OPEX',
            onSegmentTap: (node) {
              setState(() {
                _selectionSummary =
                    'Selecionado: ${node.label} '
                    '(${AppBrFormatters.currency(node.totalValue)})';
              });
            },
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppSectionCardWithHeading(
          title: '3. Preset compacto',
          subtitle: 'Versao enxuta para cards analiticos resumidos.',
          child: AppSunburstChart<_SunburstMetric>(
            items: _compactTree,
            idBuilder: _metricId,
            labelBuilder: _metricLabel,
            valueBuilder: _metricValue,
            parentIdBuilder: _metricParentId,
            preset: AppChartPreset.compact,
            style: AppSunburstChartStyle(
              showLegend: false,
              showLabels: false,
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppSunburstChart<String>(
          title: '4. Estado de loading',
          items: <String>[],
          idBuilder: _identity,
          labelBuilder: _identity,
          valueBuilder: _zero,
          parentIdBuilder: _nullParent,
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSunburstChart<String>(
          title: '5. Estado vazio',
          items: const <String>[],
          idBuilder: _identity,
          labelBuilder: _identity,
          valueBuilder: _zero,
          parentIdBuilder: _nullParent,
          emptyPlaceholder: Text(
            'Nenhuma hierarquia disponivel para montar o sunburst.',
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

String? _nullParent(String _) => null;

num _zero(String _) => 0;

String _metricId(_SunburstMetric item) => item.id;

String _metricLabel(_SunburstMetric item) => item.label;

num _metricValue(_SunburstMetric item) => item.value;

String? _metricParentId(_SunburstMetric item) => item.parentId;

class _SunburstMetric {
  const _SunburstMetric({
    required this.id,
    required this.label,
    required this.value,
    this.parentId,
    this.color,
  });

  final String id;
  final String label;
  final double value;
  final String? parentId;
  final Color? color;
}

const List<_SunburstMetric> _revenueTree = <_SunburstMetric>[
  _SunburstMetric(id: 'mercearia', label: 'Mercearia', value: 0),
  _SunburstMetric(
    id: 'mercearia-graos',
    label: 'Graos',
    value: 168000,
    parentId: 'mercearia',
  ),
  _SunburstMetric(
    id: 'mercearia-massas',
    label: 'Massas',
    value: 94000,
    parentId: 'mercearia',
  ),
  _SunburstMetric(
    id: 'mercearia-enlatados',
    label: 'Enlatados',
    value: 62000,
    parentId: 'mercearia',
  ),
  _SunburstMetric(id: 'bebidas', label: 'Bebidas', value: 0),
  _SunburstMetric(
    id: 'bebidas-agua',
    label: 'Agua',
    value: 69000,
    parentId: 'bebidas',
  ),
  _SunburstMetric(
    id: 'bebidas-refri',
    label: 'Refrigerante',
    value: 88000,
    parentId: 'bebidas',
  ),
  _SunburstMetric(
    id: 'bebidas-energetico',
    label: 'Energetico',
    value: 47000,
    parentId: 'bebidas',
  ),
  _SunburstMetric(id: 'pereciveis', label: 'Pereciveis', value: 0),
  _SunburstMetric(
    id: 'pereciveis-frios',
    label: 'Frios',
    value: 97000,
    parentId: 'pereciveis',
  ),
  _SunburstMetric(
    id: 'pereciveis-laticinios',
    label: 'Laticinios',
    value: 82000,
    parentId: 'pereciveis',
  ),
  _SunburstMetric(
    id: 'pereciveis-padaria',
    label: 'Padaria',
    value: 61000,
    parentId: 'pereciveis',
  ),
];

const List<_SunburstMetric> _compactTree = <_SunburstMetric>[
  _SunburstMetric(id: 'operacao', label: 'Operacao', value: 0),
  _SunburstMetric(
    id: 'operacao-loja',
    label: 'Loja',
    value: 38,
    parentId: 'operacao',
  ),
  _SunburstMetric(
    id: 'operacao-logistica',
    label: 'Logistica',
    value: 24,
    parentId: 'operacao',
  ),
  _SunburstMetric(id: 'comercial', label: 'Comercial', value: 0),
  _SunburstMetric(
    id: 'comercial-carteira',
    label: 'Carteira',
    value: 19,
    parentId: 'comercial',
  ),
  _SunburstMetric(
    id: 'comercial-campanhas',
    label: 'Campanhas',
    value: 13,
    parentId: 'comercial',
  ),
];

List<_SunburstMetric> _opexTree(ColorScheme cs) => <_SunburstMetric>[
  _SunburstMetric(
    id: 'pessoas',
    label: 'Pessoas',
    value: 0,
    color: cs.primary,
  ),
  const _SunburstMetric(
    id: 'pessoas-salarios',
    label: 'Salarios',
    value: 420000,
    parentId: 'pessoas',
  ),
  const _SunburstMetric(
    id: 'pessoas-beneficios',
    label: 'Beneficios',
    value: 118000,
    parentId: 'pessoas',
  ),
  _SunburstMetric(
    id: 'infra',
    label: 'Infra',
    value: 0,
    color: cs.secondary,
  ),
  const _SunburstMetric(
    id: 'infra-energia',
    label: 'Energia',
    value: 84000,
    parentId: 'infra',
  ),
  const _SunburstMetric(
    id: 'infra-manutencao',
    label: 'Manutencao',
    value: 61000,
    parentId: 'infra',
  ),
  _SunburstMetric(
    id: 'tech',
    label: 'Tech',
    value: 0,
    color: cs.tertiary,
  ),
  const _SunburstMetric(
    id: 'tech-licencas',
    label: 'Licencas',
    value: 47000,
    parentId: 'tech',
  ),
  const _SunburstMetric(
    id: 'tech-dados',
    label: 'Dados',
    value: 26000,
    parentId: 'tech',
  ),
];
