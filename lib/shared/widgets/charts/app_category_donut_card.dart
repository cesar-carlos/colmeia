import 'dart:math' as math;

import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card/category_donut_card_donut_section.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card/category_donut_card_header.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card/category_donut_card_legend_widgets.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card/category_donut_card_placeholder_widgets.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_style.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:flutter/material.dart';

export 'app_category_donut_card_style.dart';

/// Donut chart + category legend in a dashboard card (design-system aligned).
///
/// Provide segment weights via `AppCategoryDonutSegment.value`; legend text
/// uses `resolveValueLabel` and percent from value / total.
///
/// Sweep animation is configured with
/// [AppCategoryDonutCardStyle.doughnutAnimationDurationMs]
/// (see style docs for overview defaults).
class AppCategoryDonutCard extends StatefulWidget {
  const AppCategoryDonutCard({
    required this.title,
    required this.segments,
    super.key,
    this.subtitle,
    this.centerPrimaryLabel,
    this.centerSecondaryLabel,
    this.titleAccentColor,
    this.titleTrailing,
    this.onShare,
    this.shareProgressKey,
    this.shareEnabled = true,
    this.openShareTooltip,
    this.openShareSemanticLabel,
    this.onOpenFullscreen,
    this.openFullscreenTooltip,
    this.openFullscreenSemanticLabel,
    this.preset = AppChartPreset.standard,
    this.style = const AppCategoryDonutCardStyle(),
    this.selectedIndex,
    this.onSelectedIndexChanged,
    this.onSegmentTap,
    this.isLoading = false,
    this.emptyPlaceholder,
    this.semanticsLabel,
    this.loadingSemanticsLabel,
    this.reselectFiresSegmentTap = false,
    this.wrapInSectionCard = true,
    this.showHeader = true,
  });

  /// Loading-block height used when the card is mounted with `isLoading: true`
  /// (mirrors [CategoryDonutCardLoadingBlock]). Exposed so callers that render
  /// their own staged placeholder (e.g. `OverviewHomeChartsBelowKpis`) reserve
  /// the same vertical space and avoid layout shift when the real card mounts.
  static double loadingBlockHeight(
    AppThemeTokens tokens, {
    AppChartPreset preset = AppChartPreset.standard,
  }) {
    final h = switch (preset) {
      AppChartPreset.compact => tokens.chartCompactHeight,
      AppChartPreset.standard => tokens.chartStandardHeight,
      AppChartPreset.explorable => tokens.chartStandardHeight,
    };
    return h * 0.85;
  }

  final String title;
  final String? subtitle;

  final List<AppCategoryDonutSegment> segments;

  /// Center of the donut (e.g. total currency).
  final String? centerPrimaryLabel;

  /// Under [centerPrimaryLabel] (e.g. total scope label).
  final String? centerSecondaryLabel;

  /// Vertical bar beside the title; when null, no accent is drawn.
  final Color? titleAccentColor;
  final Widget? titleTrailing;
  final VoidCallback? onShare;
  final Object? shareProgressKey;
  final bool shareEnabled;
  final String? openShareTooltip;
  final String? openShareSemanticLabel;
  final VoidCallback? onOpenFullscreen;
  final String? openFullscreenTooltip;
  final String? openFullscreenSemanticLabel;

  final AppChartPreset preset;
  final AppCategoryDonutCardStyle style;

  /// Controlled selection; when null, internal state is used (starts at 0).
  final int? selectedIndex;
  final ValueChanged<int>? onSelectedIndexChanged;

  /// After a legend row or slice tap, after selection updates.
  ///
  /// By default only runs when the selected index changes; set
  /// [reselectFiresSegmentTap] to true to also notify when the user taps the
  /// already selected segment.
  final void Function(AppCategoryDonutSegment segment, int index)? onSegmentTap;

  final bool isLoading;
  final Widget? emptyPlaceholder;

  /// Optional screen reader label for the whole card.
  final String? semanticsLabel;

  /// Announced via the card [Semantics] while [isLoading] is true.
  ///
  /// When null, [AppLocalizations.appCategoryDonutCardLoadingSemantics] is used.
  final String? loadingSemanticsLabel;

  /// When false (default), [onSegmentTap] is not called if the tapped segment
  /// is already selected.
  final bool reselectFiresSegmentTap;

  /// When false, chart content is not wrapped in [AppSectionCard] (embed in a
  /// parent surface such as a branch report card).
  final bool wrapInSectionCard;

  /// When false, title/subtitle/trailing header is omitted (use with an outer
  /// heading or [wrapInSectionCard] false).
  final bool showHeader;

  @override
  State<AppCategoryDonutCard> createState() => _AppCategoryDonutCardState();
}

class _AppCategoryDonutCardState extends State<AppCategoryDonutCard> {
  late int _internalSelectedIndex;

  @override
  void initState() {
    super.initState();
    _internalSelectedIndex = widget.segments.isEmpty
        ? 0
        : _clampIndex(0, widget.segments.length);
  }

  @override
  void didUpdateWidget(covariant AppCategoryDonutCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segments.length != widget.segments.length &&
        widget.segments.isNotEmpty) {
      _internalSelectedIndex = _clampIndex(
        _internalSelectedIndex,
        widget.segments.length,
      );
    }
  }

  int _clampIndex(int index, int length) {
    if (length <= 0) {
      return 0;
    }
    return index.clamp(0, length - 1);
  }

  int get _effectiveSelectedIndex {
    final external = widget.selectedIndex;
    if (external != null) {
      return _clampIndex(external, widget.segments.length);
    }
    return _internalSelectedIndex;
  }

  void _setSelected(int index) {
    final next = _clampIndex(index, widget.segments.length);
    final previous = _effectiveSelectedIndex;
    final selectionChanged = next != previous;

    if (widget.selectedIndex == null && selectionChanged) {
      setState(() => _internalSelectedIndex = next);
    }

    if (selectionChanged) {
      widget.onSelectedIndexChanged?.call(next);
    }

    if (widget.segments.isEmpty) {
      return;
    }
    final shouldNotifyTap = selectionChanged || widget.reselectFiresSegmentTap;
    if (shouldNotifyTap) {
      widget.onSegmentTap?.call(widget.segments[next], next);
    }
  }

  String _resolvedCardSemanticsLabel(BuildContext context) {
    final custom = widget.semanticsLabel?.trim();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    final l10n = AppLocalizations.of(context);
    if (widget.isLoading) {
      final explicit = widget.loadingSemanticsLabel?.trim();
      if (explicit != null && explicit.isNotEmpty) {
        return explicit;
      }
      return l10n.appCategoryDonutCardLoadingSemantics;
    }
    if (widget.segments.isEmpty) {
      return l10n.appCategoryDonutCardEmptySemantics(widget.title);
    }
    return l10n.appCategoryDonutCardCategoriesSemantics(
      widget.title,
      widget.segments.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final chartTheme = AppChartTheme.fromContext(
      context,
      preset: widget.preset,
    );
    final breakpoint =
        widget.style.compactBreakpointWidth ?? AppBreakpoints.mobile;

    final header = widget.showHeader
        ? CategoryDonutCardHeader(
            title: widget.title,
            subtitle: widget.subtitle,
            accentColor: widget.titleAccentColor,
            titleTrailing: widget.titleTrailing,
            onShare: widget.onShare,
            shareProgressKey: widget.shareProgressKey,
            shareEnabled: widget.shareEnabled && !widget.isLoading,
            openShareTooltip: widget.openShareTooltip,
            openShareSemanticLabel: widget.openShareSemanticLabel,
            onOpenFullscreen: widget.onOpenFullscreen,
            openFullscreenTooltip: widget.openFullscreenTooltip,
            openFullscreenSemanticLabel: widget.openFullscreenSemanticLabel,
            style: widget.style,
          )
        : null;

    Widget buildChartRegion() {
      return LayoutBuilder(
        builder: (context, constraints) {
          final useStacked = constraints.maxWidth < breakpoint;
          final maxH = constraints.maxHeight;

          AppCategoryDonutCardStyle styleForLayout(
            AppCategoryDonutCardStyle s,
          ) {
            if (!s.showLegend) {
              if (maxH.isFinite && maxH > 0) {
                final preferred = s.chartMinHeight ?? chartTheme.height;
                final chartH = math.max(preferred, maxH);
                return s.copyWith(chartMinHeight: chartH, chartSize: chartH);
              }
              return s;
            }
            if (!maxH.isFinite) {
              return s;
            }
            if (useStacked) {
              final gap = tokens.gapMd;
              final chartPreferred =
                  s.chartMinHeight ?? chartTheme.height * 0.92;
              var chartH = math
                  .min(
                    chartPreferred,
                    math.max(120, (maxH - gap) * 0.48),
                  )
                  .toDouble();
              const minLegend = 80;
              if (chartH + gap + minLegend > maxH) {
                chartH = math.max(120, maxH - gap - minLegend).toDouble();
              }
              final legendSlot = math
                  .max(minLegend, maxH - chartH - gap)
                  .toDouble();
              final cappedLegend = s.legendMaxHeight != null
                  ? math.min(s.legendMaxHeight!, legendSlot)
                  : legendSlot;
              return s.copyWith(
                chartMinHeight: chartH,
                legendMaxHeight: cappedLegend,
              );
            }

            final legendCap = s.legendMaxHeight != null
                ? math.min(s.legendMaxHeight!, maxH)
                : maxH;
            return s.copyWith(legendMaxHeight: legendCap);
          }

          final effectiveStyle = styleForLayout(widget.style);

          final chartSection = CategoryDonutCardDonutSection(
            segments: widget.segments,
            chartTheme: chartTheme,
            style: effectiveStyle,
            centerPrimary: widget.centerPrimaryLabel,
            centerSecondary: widget.centerSecondaryLabel,
            selectedIndex: _effectiveSelectedIndex,
            onSliceSelected: _setSelected,
          );

          final legend = CategoryDonutCardLegendSection(
            segments: widget.segments,
            chartTheme: chartTheme,
            selectedIndex: _effectiveSelectedIndex,
            onSelect: _setSelected,
            style: effectiveStyle,
          );

          if (!widget.style.showLegend) {
            final chartH = maxH.isFinite && maxH > 0
                ? maxH
                : (effectiveStyle.chartMinHeight ?? chartTheme.height);
            return SizedBox(
              height: chartH,
              width: double.infinity,
              child: chartSection,
            );
          }

          if (useStacked) {
            final chartH =
                effectiveStyle.chartMinHeight ?? chartTheme.height * 0.92;
            if (!maxH.isFinite) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    height: chartH,
                    child: chartSection,
                  ),
                  SizedBox(height: tokens.gapMd),
                  legend,
                ],
              );
            }
            final gap = tokens.gapMd;
            final legendSlot = math.max(80, maxH - chartH - gap).toDouble();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  height: chartH,
                  child: chartSection,
                ),
                SizedBox(height: gap),
                SizedBox(
                  height: legendSlot,
                  child: legend,
                ),
              ],
            );
          }

          final rowChartH = maxH.isFinite
              ? math.min(
                  effectiveStyle.chartSize ?? chartTheme.height,
                  maxH,
                )
              : (effectiveStyle.chartSize ?? chartTheme.height);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: rowChartH,
                  child: chartSection,
                ),
              ),
              SizedBox(width: tokens.gapMd),
              Expanded(
                flex: 4,
                child: ConstrainedBox(
                  constraints: maxH.isFinite
                      ? BoxConstraints(
                          minWidth: effectiveStyle.legendMinWidth ?? 140,
                          maxHeight: maxH,
                        )
                      : BoxConstraints(
                          minWidth: effectiveStyle.legendMinWidth ?? 140,
                        ),
                  child: legend,
                ),
              ),
            ],
          );
        },
      );
    }

    Widget buildBody({required bool expandChartWhenBounded}) {
      return LayoutBuilder(
        builder: (context, cardConstraints) {
          final heightBound =
              expandChartWhenBounded &&
              cardConstraints.hasBoundedHeight &&
              cardConstraints.maxHeight.isFinite;

          final chartChild = widget.isLoading
              ? CategoryDonutCardLoadingBlock(
                  tokens: tokens,
                  chartTheme: chartTheme,
                )
              : widget.segments.isEmpty
              ? CategoryDonutCardEmptyBlock(
                  placeholder: widget.emptyPlaceholder,
                  tokens: tokens,
                  theme: theme,
                )
              : heightBound
              ? Expanded(child: buildChartRegion())
              : buildChartRegion();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (header != null) ...<Widget>[
                header,
                SizedBox(height: tokens.contentSpacing),
              ],
              chartChild,
            ],
          );
        },
      );
    }

    final semantics = Semantics(
      container: true,
      label: _resolvedCardSemanticsLabel(context),
      child: widget.wrapInSectionCard
          ? AppSectionCard(
              child: buildBody(expandChartWhenBounded: true),
            )
          : buildBody(expandChartWhenBounded: true),
    );

    return semantics;
  }
}
