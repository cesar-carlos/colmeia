import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_header_trailing.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_horizontal_progress_chart/horizontal_progress_chart_header.dart';
import 'package:colmeia/shared/widgets/charts/app_horizontal_progress_chart/horizontal_progress_chart_loading.dart';
import 'package:colmeia/shared/widgets/charts/app_horizontal_progress_chart/horizontal_progress_chart_row.dart';
import 'package:colmeia/shared/widgets/charts/app_horizontal_progress_chart_style.dart';
import 'package:colmeia/shared/widgets/charts/horizontal_progress_chart_math.dart';
import 'package:colmeia/shared/widgets/charts/horizontal_progress_chart_typedefs.dart';
import 'package:flutter/material.dart';

export 'app_horizontal_progress_chart_style.dart';
export 'horizontal_progress_chart_typedefs.dart';
class AppHorizontalProgressChart<T> extends StatelessWidget {
  const AppHorizontalProgressChart({
    required this.items,
    required this.labelBuilder,
    required this.valueBuilder,
    super.key,
    this.title,
    this.maxValue = 100,
    this.progressValueBuilder,
    this.maxValueBuilder,
    this.valueLabelBuilder,
    this.valueLabelMode = AppHorizontalProgressValueLabelMode.auto,
    this.titleWidget,
    this.rowLeadingBuilder,
    this.rowTooltipBuilder,
    this.showDividers = false,
    this.dividerBuilder,
    this.style = const AppHorizontalProgressChartStyle(),
    this.wrapInCard = true,
    this.cardColor,
    this.cardPadding,
    this.emptyPlaceholder,
    this.isLoading = false,
    this.loadingRowCount = 4,
    this.onItemTap,
    this.onItemTapEvent,
    this.barAnimationDuration,
    this.onShare,
    this.shareProgressKey,
    this.shareEnabled = true,
    this.openShareTooltip,
    this.openShareSemanticLabel,
    this.onOpenFullscreen,
    this.openFullscreenTooltip,
    this.openFullscreenSemanticLabel,
  });

  final List<T> items;
  final AppHorizontalProgressLabelBuilder<T> labelBuilder;
  final AppHorizontalProgressValueBuilder<T> valueBuilder;
  final String? title;
  final double maxValue;
  final AppHorizontalProgressBarValueBuilder<T>? progressValueBuilder;
  final AppHorizontalProgressMaxValueBuilder<T>? maxValueBuilder;
  final AppHorizontalProgressValueLabelBuilder<T>? valueLabelBuilder;
  final AppHorizontalProgressValueLabelMode valueLabelMode;
  final Widget? titleWidget;
  final AppHorizontalProgressRowLeadingBuilder<T>? rowLeadingBuilder;
  final AppHorizontalProgressTooltipBuilder<T>? rowTooltipBuilder;
  final bool showDividers;
  final AppHorizontalProgressDividerBuilder? dividerBuilder;
  final AppHorizontalProgressChartStyle style;
  final bool wrapInCard;
  final Color? cardColor;
  final EdgeInsetsGeometry? cardPadding;
  final Widget? emptyPlaceholder;
  final bool isLoading;
  final int loadingRowCount;
  final void Function(T item)? onItemTap;
  final ValueChanged<AppChartItemTapEvent<T>>? onItemTapEvent;
  final Duration? barAnimationDuration;
  final VoidCallback? onShare;
  final Object? shareProgressKey;
  final bool shareEnabled;
  final String? openShareTooltip;
  final String? openShareSemanticLabel;
  final VoidCallback? onOpenFullscreen;
  final String? openFullscreenTooltip;
  final String? openFullscreenSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;
    final rowSpacing = style.rowSpacing ?? tokens.gapMd;
    final barColor = style.barColor ?? cs.primary;
    final trackColor = style.trackColor ?? cs.surfaceContainerHigh;
    final valueColor = style.valueColor ?? barColor;
    final barRadius =
        style.barRadius ?? BorderRadius.circular(tokens.formFieldRadius);
    final titleBottomSpacing = style.titleBottomSpacing ?? tokens.gapMd;
    final leadingSpacing = style.leadingSpacing ?? tokens.gapSm;
    final resolvedTitleStyle =
        style.titleTextStyle ??
        theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        );
    final resolvedLabelStyle =
        style.labelTextStyle ??
        theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        );
    final resolvedValueStyle =
        style.valueTextStyle ??
        theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: valueColor,
        );
    final headerTrailing = _resolveHeaderTrailing(context);

    Widget body;
    if (isLoading) {
      body = HorizontalProgressChartLoadingBlock(
        rowCount: loadingRowCount,
        rowSpacing: rowSpacing,
        barHeight: style.barHeight,
        barRadius: barRadius,
        trackColor: trackColor,
        barColor: barColor,
        rowPadding: style.rowPadding,
        gapSm: tokens.gapSm,
        titleWidget: titleWidget,
        title: title,
        resolvedTitleStyle: resolvedTitleStyle,
        titleTextAlign: style.titleTextAlign,
        titleBottomSpacing: titleBottomSpacing,
        headerTrailing: headerTrailing,
      );
    } else if (items.isEmpty) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          HorizontalProgressChartHeader(
            titleWidget: titleWidget,
            title: title,
            titleStyle: resolvedTitleStyle,
            titleTextAlign: style.titleTextAlign,
            bottomSpacing: titleBottomSpacing,
            headerTrailing: headerTrailing,
          ),
          emptyPlaceholder ?? const SizedBox.shrink(),
        ],
      );
    } else {
      final rows = <Widget>[];
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final displayValue = sanitizeHorizontalProgressNumber(
          valueBuilder(item),
        );
        final rowMax = sanitizeHorizontalProgressNumber(
          maxValueBuilder?.call(item) ?? maxValue,
        );
        final barRaw = sanitizeHorizontalProgressNumber(
          progressValueBuilder?.call(item) ?? displayValue,
        );
        final normalized = normalizedHorizontalProgress(
          rawValue: barRaw,
          maxValue: rowMax,
        );
        rows.add(
          HorizontalProgressChartRow<T>(
            item: item,
            itemIndex: i,
            labelBuilder: labelBuilder,
            rowLeadingBuilder: rowLeadingBuilder,
            rowTooltipBuilder: rowTooltipBuilder,
            valueLabelBuilder: valueLabelBuilder,
            valueLabelMode: valueLabelMode,
            displayValue: displayValue,
            rowMaxValue: rowMax,
            normalized: normalized,
            barColor: barColor,
            trackColor: trackColor,
            barGradient: style.barGradient,
            barHeight: style.barHeight,
            barRadius: barRadius,
            rowPadding: style.rowPadding,
            labelTextStyle: resolvedLabelStyle,
            valueTextStyle: resolvedValueStyle,
            labelTextAlign: style.labelTextAlign,
            valueTextAlign: style.valueTextAlign,
            leadingSpacing: leadingSpacing,
            gapSm: tokens.gapSm,
            onItemTap: onItemTap,
            onItemTapEvent: onItemTapEvent,
            barAnimationDuration: barAnimationDuration,
          ),
        );
        if (i < items.length - 1) {
          if (showDividers) {
            rows.add(
              Padding(
                padding:
                    style.dividerPadding ??
                    EdgeInsets.symmetric(vertical: rowSpacing / 2),
                child:
                    dividerBuilder?.call(context, i) ??
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
              ),
            );
          } else {
            rows.add(SizedBox(height: rowSpacing));
          }
        }
      }

      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          HorizontalProgressChartHeader(
            titleWidget: titleWidget,
            title: title,
            titleStyle: resolvedTitleStyle,
            titleTextAlign: style.titleTextAlign,
            bottomSpacing: titleBottomSpacing,
            headerTrailing: headerTrailing,
          ),
          ...rows,
        ],
      );
    }

    if (!wrapInCard) {
      return body;
    }

    return AppSectionCard(
      color: cardColor,
      padding: cardPadding,
      child: body,
    );
  }

  Widget? _resolveHeaderTrailing(BuildContext context) {
    if (onShare == null && onOpenFullscreen == null) {
      return null;
    }
    final l10n = AppLocalizations.of(context);
    return AppChartHeaderTrailing(
      onShare: onShare,
      shareProgressKey: shareProgressKey,
      shareEnabled: shareEnabled && !isLoading,
      openShareTooltip: openShareTooltip ?? l10n.chartShareTooltip,
      openShareSemanticLabel: openShareSemanticLabel ?? l10n.chartShareTooltip,
      onOpenFullscreen: onOpenFullscreen,
      openFullscreenTooltip: openFullscreenTooltip,
      openFullscreenSemanticLabel: openFullscreenSemanticLabel,
    );
  }
}
