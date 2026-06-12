import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card/category_donut_card_constants.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_style.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:flutter/material.dart';

class CategoryDonutCardLegendSection extends StatelessWidget {
  const CategoryDonutCardLegendSection({
    required this.segments,
    required this.chartTheme,
    required this.selectedIndex,
    required this.onSelect,
    required this.style,
    super.key,
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
    final pad =
        style.legendItemPadding ??
        EdgeInsets.symmetric(
          horizontal: tokens.gapSm,
          vertical: tokens.gapXs,
        );
    final radius =
        style.selectedRowBorderRadius ??
        BorderRadius.circular(tokens.cardRadius * 0.45);

    Widget rowAt(int i) {
      return CategoryDonutLegendRow(
        segment: segments[i],
        index: i,
        isSelected: i == selectedIndex,
        swatchColor: segments[i].color ?? palette[i % palette.length],
        valueLabel: segments[i].resolveValueLabel(),
        percentLabel: segments[i].resolvePercentLabel(total),
        onTap: () => onSelect(i),
        typography: typography,
        colors: colors,
        padding: pad,
        borderRadius: radius,
      );
    }

    final maxLegendHeight = style.legendMaxHeight;
    if (maxLegendHeight != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxLegendHeight),
        child: CategoryDonutScrollableLegendList(
          spacing: spacing,
          itemCount: segments.length,
          itemBuilder: rowAt,
          scrollbarGutter:
              style.legendScrollbarGutter ??
              kCategoryDonutLegendScrollbarGutterDefault,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var i = 0; i < segments.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: spacing),
          rowAt(i),
        ],
      ],
    );
  }
}

class CategoryDonutScrollableLegendList extends StatefulWidget {
  const CategoryDonutScrollableLegendList({
    required this.spacing,
    required this.itemCount,
    required this.itemBuilder,
    required this.scrollbarGutter,
    super.key,
  });

  final double spacing;
  final int itemCount;
  final Widget Function(int index) itemBuilder;
  final double scrollbarGutter;

  @override
  State<CategoryDonutScrollableLegendList> createState() =>
      _CategoryDonutScrollableLegendListState();
}

class _CategoryDonutScrollableLegendListState
    extends State<CategoryDonutScrollableLegendList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(
        context,
      ).copyWith(scrollbars: false),
      child: ScrollbarTheme(
        data: ScrollbarTheme.of(context).copyWith(
          thumbColor: WidgetStatePropertyAll(
            colorScheme.onSurfaceVariant.withValues(alpha: 0.34),
          ),
          thickness: const WidgetStatePropertyAll(6),
          radius: const Radius.circular(999),
        ),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: false,
          trackVisibility: false,
          interactive: true,
          child: ListView.separated(
            controller: _scrollController,
            shrinkWrap: true,
            primary: false,
            padding: EdgeInsets.only(right: widget.scrollbarGutter),
            physics: const ClampingScrollPhysics(),
            itemCount: widget.itemCount,
            separatorBuilder: (_, _) => SizedBox(height: widget.spacing),
            itemBuilder: (context, i) => widget.itemBuilder(i),
          ),
        ),
      ),
    );
  }
}

class CategoryDonutLegendRow extends StatelessWidget {
  const CategoryDonutLegendRow({
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
    super.key,
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
    final selectedSurface = theme.colorScheme.surfaceContainerHighest
        .withValues(alpha: 0.55);

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '${segment.label}, $valueLabel, $percentLabel',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: AnimatedContainer(
            duration: categoryDonutLegendHighlightDuration,
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isSelected ? selectedSurface : Colors.transparent,
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
                    style: tightenCategoryDonutTypographyFontSize(
                      typography.body,
                    ).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    right: theme.extension<AppThemeTokens>()!.gapXs / 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        valueLabel,
                        style: tightenCategoryDonutTypographyFontSize(
                          typography.body,
                        ).copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        percentLabel,
                        style: tightenCategoryDonutTypographyFontSize(
                          typography.caption,
                        ).copyWith(
                          color: swatchColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
