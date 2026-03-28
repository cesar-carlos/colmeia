import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_horizontal_progress_chart.dart';
import 'package:colmeia/shared/widgets/charts/horizontal_progress_chart_math.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class HorizontalProgressChartDemoPage extends StatelessWidget {
  const HorizontalProgressChartDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Graficos',
          title: 'AppHorizontalProgressChart',
          subtitle:
              'Percentual, valor absoluto, metas, estilo customizado, '
              'loading e empty.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppHorizontalProgressChart<_CategoryShareSample>(
          title: '1. Percentual simples',
          items: _categoryShareSamples,
          labelBuilder: (item) => item.label,
          valueBuilder: (item) => item.percent,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppHorizontalProgressChart<_StoreRevenueSample>(
          title: '2. Valor absoluto com escala fixa',
          items: _storeRevenueSamples,
          labelBuilder: (item) => item.label,
          valueBuilder: (item) => item.revenueInThousands,
          maxValue: 240,
          valueLabelMode: AppHorizontalProgressValueLabelMode.number,
          valueLabelBuilder: (item, value, _) => 'R\$ ${value.toInt()} mil',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppHorizontalProgressChart<_SellerConversionSample>(
          title: '3. Valor exibido diferente da barra',
          items: _sellerConversionSamples,
          labelBuilder: (item) => item.label,
          valueBuilder: (item) => item.conversionPercent,
          progressValueBuilder: (item) => item.currentOrders,
          maxValueBuilder: (item) => item.targetOrders,
          valueLabelMode: AppHorizontalProgressValueLabelMode.percent,
          valueLabelBuilder: (item, value, _) =>
              '${value.toStringAsFixed(1)}% (${item.currentOrders.toInt()}/${item.targetOrders.toInt()} pedidos)',
          barAnimationDuration: const Duration(milliseconds: 700),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: '4. Estilo customizado sem card interno',
          child: AppHorizontalProgressChart<_ServiceLevelSample>(
            titleWidget: Row(
              children: <Widget>[
                Icon(
                  Icons.tune_rounded,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: tokens.gapSm),
                Text(
                  'Custom completo',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            items: _serviceLevelSamples,
            labelBuilder: (item) => item.label,
            valueBuilder: (item) => item.score,
            valueLabelMode: AppHorizontalProgressValueLabelMode.number,
            valueLabelBuilder: (item, value, _) => value.toStringAsFixed(1),
            maxValue: 5,
            wrapInCard: false,
            showDividers: true,
            dividerBuilder: (context, index) => Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant,
            ),
            rowLeadingBuilder: (context, item) => Icon(
              item.icon,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            rowTooltipBuilder: (item, value, rowMax) =>
                '${item.label}: nota ${value.toStringAsFixed(1)} '
                'de ${rowMax.toStringAsFixed(0)}',
            style: AppHorizontalProgressChartStyle(
              barGradient: LinearGradient(
                colors: <Color>[
                  tokens.chartSeriesSecondary,
                  tokens.chartSeriesTertiary,
                ],
              ),
              trackColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: theme.colorScheme.onSurface,
              barHeight: 10,
              rowSpacing: tokens.contentSpacing,
              rowPadding: EdgeInsets.symmetric(vertical: tokens.gapXs),
              labelTextAlign: TextAlign.left,
              valueTextAlign: TextAlign.right,
            ),
            onItemTap: (item) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Selecionado: ${item.label}'),
                ),
              );
            },
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppHorizontalProgressChart<String>(
          title: '5. Loading',
          items: const <String>[],
          labelBuilder: (item) => item,
          valueBuilder: (item) => 0,
          isLoading: true,
          loadingRowCount: 3,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppHorizontalProgressChart<String>(
          title: '6. Empty state',
          items: const <String>[],
          labelBuilder: (item) => item,
          valueBuilder: (item) => 0,
          emptyPlaceholder: Text(
            'Sem dados para este recorte no momento.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryShareSample {
  const _CategoryShareSample({
    required this.label,
    required this.percent,
  });

  final String label;
  final double percent;
}

class _StoreRevenueSample {
  const _StoreRevenueSample({
    required this.label,
    required this.revenueInThousands,
  });

  final String label;
  final double revenueInThousands;
}

class _SellerConversionSample {
  const _SellerConversionSample({
    required this.label,
    required this.conversionPercent,
    required this.currentOrders,
    required this.targetOrders,
  });

  final String label;
  final double conversionPercent;
  final double currentOrders;
  final double targetOrders;
}

class _ServiceLevelSample {
  const _ServiceLevelSample({
    required this.label,
    required this.score,
    required this.icon,
  });

  final String label;
  final double score;
  final IconData icon;
}

const List<_CategoryShareSample> _categoryShareSamples = <_CategoryShareSample>[
  _CategoryShareSample(label: 'Bebidas', percent: 42),
  _CategoryShareSample(label: 'Lanches', percent: 28),
  _CategoryShareSample(label: 'Mercearia', percent: 18),
  _CategoryShareSample(label: 'Outros', percent: 12),
];

const List<_StoreRevenueSample> _storeRevenueSamples = <_StoreRevenueSample>[
  _StoreRevenueSample(label: 'Loja Centro', revenueInThousands: 210),
  _StoreRevenueSample(label: 'Loja Norte', revenueInThousands: 165),
  _StoreRevenueSample(label: 'Loja Sul', revenueInThousands: 132),
];

const List<_SellerConversionSample> _sellerConversionSamples =
    <_SellerConversionSample>[
      _SellerConversionSample(
        label: 'Amanda',
        conversionPercent: 42.5,
        currentOrders: 85,
        targetOrders: 100,
      ),
      _SellerConversionSample(
        label: 'Bruno',
        conversionPercent: 31,
        currentOrders: 62,
        targetOrders: 80,
      ),
      _SellerConversionSample(
        label: 'Carla',
        conversionPercent: 27.5,
        currentOrders: 55,
        targetOrders: 70,
      ),
    ];

const List<_ServiceLevelSample> _serviceLevelSamples = <_ServiceLevelSample>[
  _ServiceLevelSample(
    label: 'Entrega',
    score: 4.6,
    icon: Icons.local_shipping_outlined,
  ),
  _ServiceLevelSample(
    label: 'Atendimento',
    score: 4.3,
    icon: Icons.support_agent_outlined,
  ),
  _ServiceLevelSample(
    label: 'Reposição',
    score: 3.8,
    icon: Icons.inventory_2_outlined,
  ),
];
