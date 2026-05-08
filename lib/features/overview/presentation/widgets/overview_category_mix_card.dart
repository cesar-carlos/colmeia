// NOT_RENDERED: not mounted by any current page/route. The home dashboard
// uses `OverviewPaymentMixCard` (payment-method mix), not this category mix.
// Kept for the upcoming overview revamp; modifications here will not surface
// in the running app. See `lib/features/overview/presentation/widgets/README.md`.

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_category_share.dart';
import 'package:colmeia/l10n/app_localizations.dart';
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
    required this.l10n,
    required this.shares,
    super.key,
    this.fallbackTotalRevenue,
  });

  final AppLocalizations l10n;
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
  String? _localeNameRef;
  late List<AppCategoryDonutSegment> _segments;
  String? _centerPrimary;

  void _recomputeIfNeeded() {
    if (identical(_sharesRef, widget.shares) &&
        _fallbackOptRef == widget.fallbackTotalRevenue &&
        _localeNameRef == widget.l10n.localeName) {
      return;
    }
    _sharesRef = widget.shares;
    _fallbackOptRef = widget.fallbackTotalRevenue;
    _localeNameRef = widget.l10n.localeName;
    final fallback =
        widget.fallbackTotalRevenue ?? _defaultFallbackTotalRevenue;
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
    final l10n = widget.l10n;

    return AppCategoryDonutCard(
      title: l10n.overviewCategoryMixTitle,
      style: const AppCategoryDonutCardStyle(
        doughnutAnimationDurationMs: 0,
        legendMaxHeight: 280,
      ),
      segments: _segments,
      centerPrimaryLabel: _centerPrimary,
      centerSecondaryLabel: l10n.overviewCategoryMixDonutAnnualTotalLabel,
      titleAccentColor: accent,
      titleTrailing: IconButton(
        icon: const Icon(Icons.more_vert),
        tooltip: l10n.overviewCategoryMixMoreOptionsTooltip,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.overviewCategoryMixMenuComingSoon)),
          );
        },
      ),
    );
  }
}
