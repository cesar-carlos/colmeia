import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_category_share.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:flutter/material.dart';

/// Vendas por categoria: donut + legenda.
///
/// Se todos os itens tiverem `amount`, o gráfico e o centro usam a soma real;
/// caso contrário, montantes são estimados a partir de `percent` e
/// [fallbackTotalRevenue] (ou 1,2M quando a API não envia total).
class DashboardCategoryMixCard extends StatelessWidget {
  const DashboardCategoryMixCard({
    required this.shares,
    super.key,
    this.fallbackTotalRevenue,
  });

  final List<DashboardCategoryShare> shares;

  /// Total usado para estimar valores quando [DashboardCategoryShare.amount]
  /// não vem em todas as linhas (ex.: `overview.categoryMixTotalRevenue`).
  final double? fallbackTotalRevenue;

  static const double _defaultFallbackTotalRevenue = 1_200_000;

  static List<AppCategoryDonutSegment> _segments(
    List<DashboardCategoryShare> shares,
    double fallbackTotal,
  ) {
    final useAmounts =
        shares.isNotEmpty && shares.every((s) => s.amount != null);
    if (useAmounts) {
      return shares
          .map(
            (s) => AppCategoryDonutSegment(
              label: s.label,
              value: s.amount!,
              valueLabel: AppBrFormatters.currency(s.amount!),
              percentLabel: '${s.percent.round()}%',
            ),
          )
          .toList(growable: false);
    }
    return shares
        .map((s) {
          final amount = fallbackTotal * s.percent / 100;
          return AppCategoryDonutSegment(
            label: s.label,
            value: amount,
            valueLabel: AppBrFormatters.currency(amount),
            percentLabel: '${s.percent.round()}%',
          );
        })
        .toList(growable: false);
  }

  static String? _centerPrimary(
    List<DashboardCategoryShare> shares,
    double fallbackTotal,
  ) {
    if (shares.isEmpty) {
      return null;
    }
    final useAmounts = shares.every((s) => s.amount != null);
    if (useAmounts) {
      final total = shares.fold<double>(
        0,
        (a, s) => a + s.amount!,
      );
      return AppBrFormatters.compactCurrency(total);
    }
    return AppBrFormatters.compactCurrency(fallbackTotal);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final fallback = fallbackTotalRevenue ?? _defaultFallbackTotalRevenue;

    return AppCategoryDonutCard(
      title: 'Vendas por categoria',
      segments: _segments(shares, fallback),
      centerPrimaryLabel: _centerPrimary(shares, fallback),
      centerSecondaryLabel: 'TOTAL ANUAL',
      titleAccentColor: accent,
      titleTrailing: IconButton(
        icon: const Icon(Icons.more_vert),
        tooltip: 'Mais opcoes',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu em breve.')),
          );
        },
      ),
    );
  }
}
