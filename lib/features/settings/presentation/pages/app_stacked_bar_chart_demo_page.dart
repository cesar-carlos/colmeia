import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_stacked_bar_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppStackedBarChartDemoPage extends StatefulWidget {
  const AppStackedBarChartDemoPage({super.key});

  @override
  State<AppStackedBarChartDemoPage> createState() =>
      _AppStackedBarChartDemoPageState();
}

class _AppStackedBarChartDemoPageState
    extends State<AppStackedBarChartDemoPage> {
  String? _lastTappedGroup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Graficos empilhados',
          title: 'AppStackedBarChart',
          subtitle:
              'Composicao por grupos: canais, categorias, orientacao '
              'horizontal e variante 100% normalizada.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppStackedBarChart<_MonthlySales>(
          title: '1. Vendas por canal (absoluto)',
          subtitle: 'Tres canais empilhados por mes.',
          groups: _monthlySalesSamples,
          groupLabelBuilder: (m) => m.month,
          series: <AppStackedBarSeries<_MonthlySales>>[
            AppStackedBarSeries(
              label: 'Loja',
              valueBuilder: (m) => m.store,
            ),
            AppStackedBarSeries(
              label: 'App',
              valueBuilder: (m) => m.app,
            ),
            AppStackedBarSeries(
              label: 'Delivery',
              valueBuilder: (m) => m.delivery,
            ),
          ],
          style: AppStackedBarChartStyle(
            yAxisFormat: AppBrFormatters.compactCurrencyFormat,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppStackedBarChart<_MonthlySales>(
          title: '2. Participacao percentual (100%)',
          subtitle: 'Normalizacao completa para comparar composicao.',
          groups: _monthlySalesSamples,
          groupLabelBuilder: (m) => m.month,
          series: <AppStackedBarSeries<_MonthlySales>>[
            AppStackedBarSeries(
              label: 'Loja',
              valueBuilder: (m) => m.store,
            ),
            AppStackedBarSeries(
              label: 'App',
              valueBuilder: (m) => m.app,
            ),
            AppStackedBarSeries(
              label: 'Delivery',
              valueBuilder: (m) => m.delivery,
            ),
          ],
          style: const AppStackedBarChartStyle(isPercentStack: true),
        ),
        SizedBox(height: tokens.sectionSpacing),

        // Horizontal orientation
        AppStackedBarChart<_StoreCategory>(
          title: '3. Horizontal — categorias por loja',
          subtitle:
              'orientation: Axis.horizontal facilita rotulos longos.',
          groups: _storeCategorySamples,
          groupLabelBuilder: (s) => s.store,
          series: <AppStackedBarSeries<_StoreCategory>>[
            AppStackedBarSeries(
              label: 'Bebidas',
              valueBuilder: (s) => s.beverages,
            ),
            AppStackedBarSeries(
              label: 'Lanches',
              valueBuilder: (s) => s.snacks,
            ),
            AppStackedBarSeries(
              label: 'Mercearia',
              valueBuilder: (s) => s.grocery,
            ),
          ],
          style: AppStackedBarChartStyle(
            orientation: Axis.horizontal,
            yAxisFormat: AppBrFormatters.compactCurrencyFormat,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),

        // Horizontal 100%
        AppStackedBarChart<_StoreCategory>(
          title: '4. Horizontal 100%',
          subtitle: 'Mesma orientacao com normalizacao percentual.',
          groups: _storeCategorySamples,
          groupLabelBuilder: (s) => s.store,
          series: <AppStackedBarSeries<_StoreCategory>>[
            AppStackedBarSeries(
              label: 'Bebidas',
              valueBuilder: (s) => s.beverages,
            ),
            AppStackedBarSeries(
              label: 'Lanches',
              valueBuilder: (s) => s.snacks,
            ),
            AppStackedBarSeries(
              label: 'Mercearia',
              valueBuilder: (s) => s.grocery,
            ),
          ],
          style: const AppStackedBarChartStyle(
            orientation: Axis.horizontal,
            isPercentStack: true,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),

        // onGroupTap demo
        AppSectionCardWithHeading(
          title: '5. onGroupTap interativo',
          subtitle: 'Toque em um grupo de barras para ver o callback.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppStackedBarChart<_MonthlySales>(
                groups: _monthlySalesSamples,
                groupLabelBuilder: (m) => m.month,
                series: <AppStackedBarSeries<_MonthlySales>>[
                  AppStackedBarSeries(
                    label: 'Loja',
                    valueBuilder: (m) => m.store,
                  ),
                  AppStackedBarSeries(
                    label: 'App',
                    valueBuilder: (m) => m.app,
                  ),
                ],
                style: AppStackedBarChartStyle(
                  yAxisFormat: AppBrFormatters.compactCurrencyFormat,
                ),
                onGroupTap: (group, index) {
                  setState(() {
                    _lastTappedGroup = '${group.month} (indice $index)';
                  });
                },
              ),
              if (_lastTappedGroup != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Grupo tocado: $_lastTappedGroup',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),

        AppSectionCardWithHeading(
          title: '6. Cores customizadas sem shell',
          subtitle: 'Cores por serie, sem legenda, preset compacto.',
          child: AppStackedBarChart<_MonthlySales>(
            groups: _monthlySalesSamples,
            groupLabelBuilder: (m) => m.month,
            series: <AppStackedBarSeries<_MonthlySales>>[
              AppStackedBarSeries(
                label: 'Loja',
                valueBuilder: (m) => m.store,
                color: cs.primary,
              ),
              AppStackedBarSeries(
                label: 'App',
                valueBuilder: (m) => m.app,
                color: cs.secondary,
              ),
              AppStackedBarSeries(
                label: 'Delivery',
                valueBuilder: (m) => m.delivery,
                color: cs.tertiary,
              ),
            ],
            style: const AppStackedBarChartStyle(showLegend: false),
            preset: AppChartPreset.compact,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppStackedBarChart<String>(
          title: '7. Estado de loading',
          groups: const <String>[],
          groupLabelBuilder: (item) => item,
          series: const <AppStackedBarSeries<String>>[],
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppStackedBarChart<String>(
          title: '8. Estado vazio',
          groups: const <String>[],
          groupLabelBuilder: (item) => item,
          series: const <AppStackedBarSeries<String>>[],
          emptyPlaceholder: Text(
            'Sem dados para este recorte.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sample data (demo only)
// ---------------------------------------------------------------------------

class _MonthlySales {
  const _MonthlySales({
    required this.month,
    required this.store,
    required this.app,
    required this.delivery,
  });

  final String month;
  final double store;
  final double app;
  final double delivery;
}

class _StoreCategory {
  const _StoreCategory({
    required this.store,
    required this.beverages,
    required this.snacks,
    required this.grocery,
  });

  final String store;
  final double beverages;
  final double snacks;
  final double grocery;
}

const List<_MonthlySales> _monthlySalesSamples = <_MonthlySales>[
  _MonthlySales(month: 'Out', store: 42000, app: 18000, delivery: 12000),
  _MonthlySales(month: 'Nov', store: 45000, app: 21000, delivery: 14500),
  _MonthlySales(month: 'Dez', store: 62000, app: 28000, delivery: 19000),
  _MonthlySales(month: 'Jan', store: 38000, app: 16000, delivery: 11000),
  _MonthlySales(month: 'Fev', store: 41000, app: 19500, delivery: 13000),
  _MonthlySales(month: 'Mar', store: 47000, app: 23000, delivery: 15500),
];

const List<_StoreCategory> _storeCategorySamples = <_StoreCategory>[
  _StoreCategory(
    store: 'Centro',
    beverages: 38000,
    snacks: 22000,
    grocery: 16000,
  ),
  _StoreCategory(
    store: 'Norte',
    beverages: 29000,
    snacks: 18000,
    grocery: 12000,
  ),
  _StoreCategory(
    store: 'Sul',
    beverages: 24000,
    snacks: 15000,
    grocery: 9500,
  ),
];
