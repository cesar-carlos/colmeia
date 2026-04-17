import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_category_share.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:flutter/material.dart';

/// Vendas por categoria: donut + legenda.
///
/// Se todos os itens tiverem `amount`, o gráfico e o centro usam a soma real;
/// caso contrário, montantes são estimados a partir de `percent` e
/// [fallbackTotalRevenue] (ou 1,2M quando a API não envia total).
///
/// Segmentos e rótulo central são cacheados enquanto [shares] e
/// [fallbackTotalRevenue] não mudam (evita map/fold em rebuilds frequentes).
class OverviewCategoryMixCard extends StatefulWidget {
  const OverviewCategoryMixCard({
    required this.shares,
    super.key,
    this.fallbackTotalRevenue,
  });

  final List<OverviewCategoryShare> shares;

  /// Total usado para estimar valores quando [OverviewCategoryShare.amount]
  /// não vem em todas as linhas (ex.: `overview.categoryMixTotalRevenue`).
  final double? fallbackTotalRevenue;

  @override
  State<OverviewCategoryMixCard> createState() =>
      _OverviewCategoryMixCardState();
}

class _OverviewCategoryMixCardState extends State<OverviewCategoryMixCard> {
  static const double _defaultFallbackTotalRevenue = 1_200_000;

  List<OverviewCategoryShare>? _sharesRef;
  double? _fallbackOptRef;
  late List<AppCategoryDonutSegment> _segments;
  String? _centerPrimary;

  void _recomputeIfNeeded() {
    if (identical(_sharesRef, widget.shares) &&
        _fallbackOptRef == widget.fallbackTotalRevenue) {
      return;
    }
    _sharesRef = widget.shares;
    _fallbackOptRef = widget.fallbackTotalRevenue;
    final fallback = widget.fallbackTotalRevenue ?? _defaultFallbackTotalRevenue;
    _segments = _buildSegments(widget.shares, fallback);
    _centerPrimary = _buildCenterPrimary(widget.shares, fallback);
  }

  static List<AppCategoryDonutSegment> _buildSegments(
    List<OverviewCategoryShare> shares,
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

  static String? _buildCenterPrimary(
    List<OverviewCategoryShare> shares,
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
  void initState() {
    super.initState();
    _recomputeIfNeeded();
  }

  @override
  void didUpdateWidget(covariant OverviewCategoryMixCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recomputeIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return AppCategoryDonutCard(
      title: 'Vendas por categoria',
      segments: _segments,
      centerPrimaryLabel: _centerPrimary,
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
