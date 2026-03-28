import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppComparisonBarChartDemoPage extends StatelessWidget {
  const AppComparisonBarChartDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Graficos de barras',
          title: 'AppComparisonBarChart',
          subtitle:
              'Grafico de barras verticais com tipo generico, labels, eixos, '
              'interacao, estilizacao e estados de loading/empty.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppComparisonBarChart<_SellerRevenue>(
          title: '1. Faturamento por vendedor',
          subtitle: 'Valores em reais com eixo Y e labels nas barras.',
          items: _sellerRevenueSamples,
          labelBuilder: (item) => item.name,
          valueBuilder: (item) => item.revenue,
          dataLabelBuilder: (item, value) =>
              AppBrFormatters.compactCurrency(value),
          style: AppComparisonBarChartStyle(
            yAxisFormat: AppBrFormatters.compactCurrencyFormat,
            showDataLabels: true,
            dataLabelTextStyle: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppComparisonBarChart<_SellerRevenue>(
          title: '2. Cor, tooltip customizado e tap',
          subtitle: 'Cada vendedor recebe uma cor e interacao propria.',
          items: _sellerRevenueSamples,
          labelBuilder: (item) => item.name,
          valueBuilder: (item) => item.revenue,
          colorBuilder: (item) => item.color,
          tooltipLabelBuilder: (item, value) =>
              '${item.name}: ${AppBrFormatters.currency(value)}',
          onPointTap: (item, index) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Barra ${index + 1}: ${item.name} selecionado',
                ),
              ),
            );
          },
          style: AppComparisonBarChartStyle(
            yAxisFormat: AppBrFormatters.compactCurrencyFormat,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppComparisonBarChart<_SellerRevenue>(
          title: '3. Eixos configurados',
          subtitle: 'Titulos, rotacao, intervalo e limites fixos.',
          items: _sellerRevenueSamples,
          labelBuilder: (item) => item.name,
          valueBuilder: (item) => item.revenue,
          style: AppComparisonBarChartStyle(
            yAxisFormat: AppBrFormatters.compactCurrencyFormat,
            xAxisTitle: 'Vendedores',
            yAxisTitle: 'Faturamento',
            xLabelRotation: -25,
            minY: 0,
            maxY: 30000,
            interval: 5000,
            axisLabelTextStyle: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: '4. Contrato visual completo',
          subtitle: 'Espacamento, largura, borda, fundo e animacao.',
          child: AppComparisonBarChart<_SellerRevenue>(
            items: _sellerRevenueSamples,
            labelBuilder: (item) => item.name,
            valueBuilder: (item) => item.revenue,
            colorBuilder: (item) => item.color,
            dataLabelBuilder: (item, value) =>
                AppBrFormatters.compactCurrency(value),
            style: AppComparisonBarChartStyle(
              yAxisFormat: AppBrFormatters.compactCurrencyFormat,
              showDataLabels: true,
              barWidth: 0.55,
              spacing: 0.12,
              borderColor: cs.outlineVariant,
              borderWidth: 1,
              plotAreaBackgroundColor: cs.surfaceContainerLow,
              chartPadding: EdgeInsets.all(tokens.gapSm),
              animationDuration: const Duration(milliseconds: 900),
              dataLabelTextStyle: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: '5. Compacto sem shell (preset compact)',
          subtitle: 'Altura reduzida, sem titulo interno.',
          child: AppComparisonBarChart<_CategorySales>(
            items: _categorySalesSamples,
            labelBuilder: (item) => item.label,
            valueBuilder: (item) => item.units,
            preset: AppChartPreset.compact,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppComparisonBarChart<_StoreSales>(
          title: '6. Borda customizada e sem grid',
          subtitle: 'barBorderRadius retangular, showYGridLines: false.',
          items: _storeSalesSamples,
          labelBuilder: (item) => item.store,
          valueBuilder: (item) => item.orders,
          style: AppComparisonBarChartStyle(
            barColor: cs.tertiary,
            barBorderRadius: const BorderRadius.all(Radius.circular(2)),
            showYGridLines: false,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppComparisonBarChart<String>(
          title: '7. Estado de loading',
          items: const <String>[],
          labelBuilder: (item) => item,
          valueBuilder: (item) => 0,
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppComparisonBarChart<String>(
          title: '8. Estado vazio',
          items: const <String>[],
          labelBuilder: (item) => item,
          valueBuilder: (item) => 0,
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
// Sample data models (demo only)
// ---------------------------------------------------------------------------

class _SellerRevenue {
  const _SellerRevenue({
    required this.name,
    required this.revenue,
    required this.color,
  });

  final String name;
  final double revenue;
  final Color color;
}

class _CategorySales {
  const _CategorySales({required this.label, required this.units});

  final String label;
  final int units;
}

class _StoreSales {
  const _StoreSales({required this.store, required this.orders});

  final String store;
  final int orders;
}

const List<_SellerRevenue> _sellerRevenueSamples = <_SellerRevenue>[
  _SellerRevenue(name: 'Amanda', revenue: 21340, color: Color(0xFF6200EE)),
  _SellerRevenue(name: 'Bruno', revenue: 23110, color: Color(0xFF03DAC6)),
  _SellerRevenue(name: 'Carla', revenue: 24580, color: Color(0xFFFF6D00)),
  _SellerRevenue(name: 'Diego', revenue: 26050, color: Color(0xFF1565C0)),
];

const List<_CategorySales> _categorySalesSamples = <_CategorySales>[
  _CategorySales(label: 'Bebidas', units: 320),
  _CategorySales(label: 'Lanches', units: 210),
  _CategorySales(label: 'Mercearia', units: 145),
  _CategorySales(label: 'Outros', units: 90),
];

const List<_StoreSales> _storeSalesSamples = <_StoreSales>[
  _StoreSales(store: 'Centro', orders: 773),
  _StoreSales(store: 'Norte', orders: 618),
  _StoreSales(store: 'Sul', orders: 542),
];
