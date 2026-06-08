import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/app_chart_share_actions.dart';
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
  final GlobalKey _shareKey = GlobalKey();

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
    void openFullscreen() {
      final segmentsSnapshot = List<AppCategoryDonutSegment>.of(
        _segments,
        growable: false,
      );
      final centerPrimarySnapshot = _centerPrimary;
      final fullscreenShareKey = GlobalKey();
      final shareTitle = l10n.overviewPaymentMixTitle;
      unawaited(
        context.pushChartFullscreen<void>(
          extra: AppChartFullscreenRouteExtra(
            title: shareTitle,
            subtitle: l10n.overviewPaymentMixSubtitle,
            chartSemanticsLabel: shareTitle,
            headerTrailing: buildChartFullscreenShareTrailing(
              context: context,
              shareKey: fullscreenShareKey,
              subject: shareTitle,
            ),
            chartBuilder: (fullscreenContext) {
              return RepaintBoundary(
                key: fullscreenShareKey,
                child: LayoutBuilder(
                builder: (context, constraints) {
                  final chartSize = (constraints.biggest.shortestSide * 0.48)
                      .clamp(260.0, 420.0);
                  final legendMaxHeight = (constraints.maxHeight * 0.72).clamp(
                    220.0,
                    520.0,
                  );
                  return AppCategoryDonutCard(
                    title: l10n.overviewPaymentMixTitle,
                    subtitle: l10n.overviewPaymentMixSubtitle,
                    style: AppCategoryDonutCardStyle(
                      chartSize: chartSize,
                      chartMinHeight: chartSize,
                      legendMaxHeight: legendMaxHeight,
                    ),
                    segments: segmentsSnapshot,
                    centerPrimaryLabel: centerPrimarySnapshot,
                    centerSecondaryLabel:
                        l10n.overviewPaymentMixDonutTotalLabel,
                  );
                },
              ),
              );
            },
          ),
        ),
      );
    }

    return RepaintBoundary(
      key: _shareKey,
      child: AppCategoryDonutCard(
        title: l10n.overviewPaymentMixTitle,
        subtitle: l10n.overviewPaymentMixSubtitle,
        onOpenFullscreen: openFullscreen,
        onShare: () => unawaited(
          shareChartCapture(
            context,
            _shareKey,
            subject: l10n.overviewPaymentMixTitle,
          ),
        ),
        style: const AppCategoryDonutCardStyle(
          legendMaxHeight: 280,
        ),
        segments: _segments,
        centerPrimaryLabel: _centerPrimary,
        centerSecondaryLabel: l10n.overviewPaymentMixDonutTotalLabel,
      ),
    );
  }
}
