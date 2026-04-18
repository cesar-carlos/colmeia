import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:flutter/material.dart';

/// Payment mix donut for the overview home. Caches derived segments and total
/// while the [methods] list instance is unchanged (avoids repeated fold/map on
/// every parent rebuild during staged chart mounting).
class OverviewPaymentMixCard extends StatefulWidget {
  const OverviewPaymentMixCard({
    required this.l10n,
    required this.methods,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewPaymentMethodBreakdown> methods;

  @override
  State<OverviewPaymentMixCard> createState() => _OverviewPaymentMixCardState();
}

class _OverviewPaymentMixCardState extends State<OverviewPaymentMixCard> {
  List<OverviewPaymentMethodBreakdown>? _methodsRef;
  String? _localeNameRef;
  List<AppCategoryDonutSegment> _segments = const <AppCategoryDonutSegment>[];
  String? _centerPrimary;

  void _recomputeIfNeeded() {
    if (identical(_methodsRef, widget.methods) &&
        _localeNameRef == widget.l10n.localeName) {
      return;
    }
    _methodsRef = widget.methods;
    _localeNameRef = widget.l10n.localeName;
    final total = widget.methods.fold<double>(
      0,
      (sum, m) => sum + m.totalAmount,
    );
    _segments = widget.methods
        .map(
          (m) => AppCategoryDonutSegment(
            label: m.label,
            value: m.totalAmount,
            valueLabel: AppBrFormatters.currency(m.totalAmount),
            percentLabel: '${m.sharePercent.toStringAsFixed(1)}%',
          ),
        )
        .toList(growable: false);
    _centerPrimary = total > 0 ? AppBrFormatters.compactCurrency(total) : null;
  }

  @override
  void initState() {
    super.initState();
    _recomputeIfNeeded();
  }

  @override
  void didUpdateWidget(covariant OverviewPaymentMixCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recomputeIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AppCategoryDonutCard(
      title: l10n.overviewPaymentMixTitle,
      subtitle: l10n.overviewPaymentMixSubtitle,
      style: const AppCategoryDonutCardStyle(
        legendMaxHeight: 280,
      ),
      segments: _segments,
      centerPrimaryLabel: _centerPrimary,
      centerSecondaryLabel: l10n.overviewPaymentMixDonutTotalLabel,
    );
  }
}
