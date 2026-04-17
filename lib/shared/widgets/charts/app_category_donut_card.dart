import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Slightly smaller type within this card (header, legend, center labels).
const double _kCategoryDonutTypographyTightenFactor = 0.92;

TextStyle _tightenTypographyFontSize(TextStyle style) {
  final fs = style.fontSize;
  if (fs == null) {
    return style;
  }
  return style.copyWith(fontSize: fs * _kCategoryDonutTypographyTightenFactor);
}

class AppCategoryDonutCardStyle {
  const AppCategoryDonutCardStyle({
    this.chartSize,
    this.chartMinHeight,
    this.legendMinWidth,
    this.innerRadius = '64%',
    this.outerRadius = '82%',
    this.rowSpacing,
    this.legendItemPadding,
    this.selectedRowBorderRadius,
    this.chartBackgroundColor,
    this.titleAccentWidth = 4,
    this.titleAccentHeight = 22,
    this.compactBreakpointWidth,
  });

  /// Fixed width/height of the square chart area when not constrained.
  final double? chartSize;

  /// Minimum height of the chart column in responsive [Column] layout.
  final double? chartMinHeight;

  /// Minimum width reserved for the legend in [Row] layout.
  final double? legendMinWidth;

  final String innerRadius;
  final String outerRadius;

  final double? rowSpacing;
  final EdgeInsetsGeometry? legendItemPadding;
  final BorderRadius? selectedRowBorderRadius;
  final Color? chartBackgroundColor;

  final double titleAccentWidth;
  final double titleAccentHeight;

  /// Below this width (card constraints), chart stacks above legend.
  /// Defaults to the app mobile breakpoint (see `AppBreakpoints.mobile`).
  final double? compactBreakpointWidth;
}

/// Donut chart + category legend in a dashboard card (design-system aligned).
///
/// Provide segment weights via `AppCategoryDonutSegment.value`; legend text
/// uses `resolveValueLabel` and percent from value / total.
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
    this.preset = AppChartPreset.standard,
    this.style = const AppCategoryDonutCardStyle(),
    this.selectedIndex,
    this.onSelectedIndexChanged,
    this.onSegmentTap,
    this.isLoading = false,
    this.emptyPlaceholder,
    this.semanticsLabel,
    this.loadingSemanticsLabel = 'Carregando categorias...',
    this.reselectFiresSegmentTap = false,
  });

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
  final String loadingSemanticsLabel;

  /// When false (default), [onSegmentTap] is not called if the tapped segment
  /// is already selected.
  final bool reselectFiresSegmentTap;

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

  String _resolvedCardSemanticsLabel() {
    final custom = widget.semanticsLabel?.trim();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    if (widget.isLoading) {
      return widget.loadingSemanticsLabel;
    }
    if (widget.segments.isEmpty) {
      return '${widget.title}, sem dados';
    }
    return '${widget.title}, ${widget.segments.length} categorias';
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

    final child = LayoutBuilder(
      builder: (context, constraints) {
        final useStacked = constraints.maxWidth < breakpoint;
        final chartSection = _DonutSection(
          segments: widget.segments,
          chartTheme: chartTheme,
          style: widget.style,
          centerPrimary: widget.centerPrimaryLabel,
          centerSecondary: widget.centerSecondaryLabel,
          selectedIndex: _effectiveSelectedIndex,
          onSliceSelected: _setSelected,
        );

        final legend = _LegendSection(
          segments: widget.segments,
          chartTheme: chartTheme,
          selectedIndex: _effectiveSelectedIndex,
          onSelect: _setSelected,
          style: widget.style,
        );

        if (useStacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                height: widget.style.chartMinHeight ?? chartTheme.height * 0.92,
                child: chartSection,
              ),
              SizedBox(height: tokens.gapMd),
              legend,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 5,
              child: SizedBox(
                height: widget.style.chartSize ?? chartTheme.height,
                child: chartSection,
              ),
            ),
            SizedBox(width: tokens.gapMd),
            Expanded(
              flex: 4,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: widget.style.legendMinWidth ?? 140,
                ),
                child: legend,
              ),
            ),
          ],
        );
      },
    );

    final header = _CategoryDonutCardHeader(
      title: widget.title,
      subtitle: widget.subtitle,
      accentColor: widget.titleAccentColor,
      titleTrailing: widget.titleTrailing,
      style: widget.style,
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        header,
        SizedBox(height: tokens.contentSpacing),
        if (widget.isLoading)
          _LoadingBlock(
            tokens: tokens,
            chartTheme: chartTheme,
          )
        else if (widget.segments.isEmpty)
          _EmptyBlock(
            placeholder: widget.emptyPlaceholder,
            tokens: tokens,
            theme: theme,
          )
        else
          child,
      ],
    );

    final card = AppSectionCard(
      child: body,
    );

    return Semantics(
      container: true,
      label: _resolvedCardSemanticsLabel(),
      child: card,
    );
  }
}

class _CategoryDonutCardHeader extends StatelessWidget {
  const _CategoryDonutCardHeader({
    required this.title,
    required this.style,
    this.subtitle,
    this.accentColor,
    this.titleTrailing,
  });

  final String title;
  final String? subtitle;
  final Color? accentColor;
  final Widget? titleTrailing;
  final AppCategoryDonutCardStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style:
              _tightenTypographyFontSize(
                typography.sectionHeaderH2,
              ).copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (subtitle != null) ...<Widget>[
          SizedBox(height: tokens.gapXs),
          Text(
            subtitle!,
            style: _tightenTypographyFontSize(typography.body),
          ),
        ],
      ],
    );

    final accent = accentColor;
    final leading = accent != null
        ? Padding(
            padding: EdgeInsets.only(right: tokens.gapSm),
            child: Semantics(
              excludeSemantics: true,
              child: Container(
                width: style.titleAccentWidth,
                height: style.titleAccentHeight,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(
                    style.titleAccentWidth * 0.5,
                  ),
                ),
              ),
            ),
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trailing = titleTrailing;
        final textRow = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ?leading,
            Expanded(child: titleBlock),
          ],
        );

        if (trailing == null) {
          return textRow;
        }

        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              textRow,
              SizedBox(height: tokens.gapSm),
              Align(
                alignment: Alignment.centerLeft,
                child: trailing,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ?leading,
            Expanded(child: titleBlock),
            SizedBox(width: tokens.gapSm),
            trailing,
          ],
        );
      },
    );
  }
}

class _DonutSection extends StatelessWidget {
  const _DonutSection({
    required this.segments,
    required this.chartTheme,
    required this.style,
    required this.selectedIndex,
    required this.onSliceSelected,
    this.centerPrimary,
    this.centerSecondary,
  });

  final List<AppCategoryDonutSegment> segments;
  final AppChartTheme chartTheme;
  final AppCategoryDonutCardStyle style;
  final int selectedIndex;
  final ValueChanged<int> onSliceSelected;
  final String? centerPrimary;
  final String? centerSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = chartTheme.palette;
    final chart = ExcludeSemantics(
      child: SfCircularChart(
        backgroundColor:
            style.chartBackgroundColor ??
            colors.surfaceContainerLow.withValues(alpha: 0.65),
        tooltipBehavior: TooltipBehavior(
          format: 'point.x : point.y',
        ),
        series: <CircularSeries<AppCategoryDonutSegment, String>>[
          DoughnutSeries<AppCategoryDonutSegment, String>(
            dataSource: segments,
            xValueMapper: (s, _) => s.label,
            yValueMapper: (s, _) => s.value.toDouble(),
            innerRadius: style.innerRadius,
            radius: style.outerRadius,
            explodeIndex: selectedIndex,
            pointColorMapper: (s, i) => s.color ?? palette[i % palette.length],
            onPointTap: (details) {
              final i = details.pointIndex;
              if (i != null && i >= 0 && i < segments.length) {
                onSliceSelected(i);
              }
            },
          ),
        ],
      ),
    );

    final hasCenter =
        (centerPrimary != null && centerPrimary!.isNotEmpty) ||
        (centerSecondary != null && centerSecondary!.isNotEmpty);

    final typography = theme.appTypography;
    final tokens = theme.extension<AppThemeTokens>()!;

    if (!hasCenter) {
      return chart;
    }

    final centerSummary = <String>[
      if (centerPrimary != null && centerPrimary!.isNotEmpty) centerPrimary!,
      if (centerSecondary != null && centerSecondary!.isNotEmpty)
        centerSecondary!,
    ].join(', ');

    final titleLargeSize = theme.textTheme.titleLarge?.fontSize;
    final centerPrimaryFontSize = titleLargeSize != null
        ? titleLargeSize * _kCategoryDonutTypographyTightenFactor
        : _tightenTypographyFontSize(typography.displayH1).fontSize;

    return Semantics(
      container: true,
      label: 'Gráfico de rosca. $centerSummary',
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          chart,
          IgnorePointer(
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (centerPrimary != null && centerPrimary!.isNotEmpty)
                    Text(
                      centerPrimary!,
                      textAlign: TextAlign.center,
                      style: typography.displayH1.copyWith(
                        fontSize: centerPrimaryFontSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (centerSecondary != null &&
                      centerSecondary!.isNotEmpty) ...<Widget>[
                    SizedBox(height: tokens.gapXs),
                    Text(
                      centerSecondary!,
                      textAlign: TextAlign.center,
                      style:
                          _tightenTypographyFontSize(
                            typography.utilityOverline,
                          ).copyWith(
                            color: context.appColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendSection extends StatelessWidget {
  const _LegendSection({
    required this.segments,
    required this.chartTheme,
    required this.selectedIndex,
    required this.onSelect,
    required this.style,
  });

  final List<AppCategoryDonutSegment> segments;
  final AppChartTheme chartTheme;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final AppCategoryDonutCardStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final colors = theme.appColors;
    final palette = chartTheme.palette;
    final total = segments.donutWeightTotal;
    final spacing = style.rowSpacing ?? tokens.gapXs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var i = 0; i < segments.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: spacing),
          _LegendRow(
            segment: segments[i],
            index: i,
            isSelected: i == selectedIndex,
            swatchColor: segments[i].color ?? palette[i % palette.length],
            valueLabel: segments[i].resolveValueLabel(),
            percentLabel: segments[i].resolvePercentLabel(total),
            onTap: () => onSelect(i),
            typography: typography,
            colors: colors,
            padding:
                style.legendItemPadding ??
                EdgeInsets.symmetric(
                  horizontal: tokens.gapSm,
                  vertical: tokens.gapXs,
                ),
            borderRadius:
                style.selectedRowBorderRadius ??
                BorderRadius.circular(tokens.cardRadius * 0.45),
          ),
        ],
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.segment,
    required this.index,
    required this.isSelected,
    required this.swatchColor,
    required this.valueLabel,
    required this.percentLabel,
    required this.onTap,
    required this.typography,
    required this.colors,
    required this.padding,
    required this.borderRadius,
  });

  final AppCategoryDonutSegment segment;
  final int index;
  final bool isSelected;
  final Color swatchColor;
  final String valueLabel;
  final String percentLabel;
  final VoidCallback onTap;
  final AppTypographyTokens typography;
  final AppColors colors;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surfaceContainerHighest.withValues(
      alpha: isSelected ? 0.55 : 0,
    );

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '${segment.label}, $valueLabel, $percentLabel',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Ink(
            decoration: BoxDecoration(
              color: isSelected ? surface : null,
              borderRadius: borderRadius,
            ),
            padding: padding,
            child: Row(
              children: <Widget>[
                ExcludeSemantics(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: swatchColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(width: theme.extension<AppThemeTokens>()!.gapSm),
                Expanded(
                  child: Text(
                    segment.label,
                    style: _tightenTypographyFontSize(typography.body).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      valueLabel,
                      style: _tightenTypographyFontSize(typography.body)
                          .copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      percentLabel,
                      style: _tightenTypographyFontSize(typography.caption)
                          .copyWith(
                            color: swatchColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({
    required this.tokens,
    required this.chartTheme,
  });

  final AppThemeTokens tokens;
  final AppChartTheme chartTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final h = chartTheme.height * 0.85;
    final radius = BorderRadius.circular(tokens.cardRadius * 0.45);
    final placeholder = SizedBox(
      height: h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: h * 0.92,
            height: h * 0.92,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: tokens.gapMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List<Widget>.generate(4, (i) {
                return Padding(
                  padding: EdgeInsets.only(bottom: i < 3 ? tokens.gapXs : 0),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: radius,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );

    return ExcludeSemantics(
      child: Skeletonizer(
        child: placeholder,
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({
    required this.placeholder,
    required this.tokens,
    required this.theme,
  });

  final Widget? placeholder;
  final AppThemeTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: tokens.chartCompactHeight * 0.9,
      child: Center(
        child:
            placeholder ??
            Text(
              l10n.chartCategoryDonutEmptyForFilter,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.appColors.onSurfaceVariant,
              ),
            ),
      ),
    );
  }
}
