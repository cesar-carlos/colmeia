import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/metrics/app_metric_stat_delta.dart';
import 'package:flutter/material.dart';

enum AppMetricStatCardEmphasis {
  /// Default card surface from theme.
  standard,

  /// Soft highlight (e.g. secondary KPIs).
  accent,

  /// Strong brand-tinted surface (e.g. primary KPI in a row).
  hero,
}

/// Where the trend label sits relative to the leading widget on the top row.
enum AppMetricStatTrendPlacement {
  /// Trend uses the rest of the row and aligns to the trailing edge.
  end,

  /// Trend sits right after the leading widget (icon + delta grouped left).
  inlineStart,
}

class AppMetricStatCardStyle {
  const AppMetricStatCardStyle({
    this.cardColor,
    this.cardPadding,
    this.cardDecoration,
    this.borderRadius,
    this.borderSide,
    this.leadingSpacing,
    this.topRowBottomSpacing,
    this.labelBottomSpacing,
    this.labelTextStyle,
    this.valueTextStyle,
    this.trendTextStyle,
    this.labelTextAlign,
    this.valueTextAlign,
    this.trendTextAlign,
    this.showTrendPill,
  });

  final Color? cardColor;
  final EdgeInsetsGeometry? cardPadding;
  final Decoration? cardDecoration;
  final BorderRadiusGeometry? borderRadius;
  final BorderSide? borderSide;
  final double? leadingSpacing;
  final double? topRowBottomSpacing;
  final double? labelBottomSpacing;
  final TextStyle? labelTextStyle;
  final TextStyle? valueTextStyle;
  final TextStyle? trendTextStyle;
  final TextAlign? labelTextAlign;
  final TextAlign? valueTextAlign;
  final TextAlign? trendTextAlign;

  /// When null, [AppMetricStatCard.showTrendPill] applies.
  final bool? showTrendPill;
}

/// KPI tile: leading icon, optional trend, label, and primary value.
/// Reusable on dashboards, reports, and similar compact stat surfaces.
class AppMetricStatCard extends StatelessWidget {
  const AppMetricStatCard({
    required this.leading,
    required this.label,
    required this.value,
    super.key,
    this.trendLabel,
    this.emphasis = AppMetricStatCardEmphasis.standard,
    this.trendPlacement = AppMetricStatTrendPlacement.end,
    this.style = const AppMetricStatCardStyle(),
    this.tooltipMessage,
    this.semanticsLabel,
    this.onTap,
    this.labelWidget,
    this.valueWidget,
    this.trendWidget,
    this.showTrendPill = true,
  });

  final Widget leading;
  final String? trendLabel;
  final String label;
  final String value;
  final AppMetricStatCardEmphasis emphasis;
  final AppMetricStatCardStyle style;
  final String? tooltipMessage;

  /// Screen reader label when [onTap] is set; defaults to a built string from
  /// [label], [value], and [trendLabel].
  final String? semanticsLabel;
  final VoidCallback? onTap;
  final Widget? labelWidget;
  final Widget? valueWidget;
  final Widget? trendWidget;

  /// When true (default), non-custom trends render as a soft pill; when false,
  /// plain colored text (legacy). Ignored when [trendWidget] is set.
  ///
  /// [AppMetricStatCardStyle.showTrendPill] overrides this when non-null.
  final bool showTrendPill;

  /// `end`: trend at the row end (paired KPIs). `inlineStart`: icon + delta
  /// grouped at the start (full-width / compact metrics).
  final AppMetricStatTrendPlacement trendPlacement;

  bool get _useOnPrimaryContainer =>
      emphasis == AppMetricStatCardEmphasis.accent ||
      emphasis == AppMetricStatCardEmphasis.hero;

  String get _resolvedSemanticsLabel {
    final custom = semanticsLabel?.trim();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    final trend = trendLabel?.trim();
    if (trend != null && trend.isNotEmpty) {
      return '$label, $value, $trend';
    }
    return '$label, $value';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;
    final leadingSpacing = style.leadingSpacing ?? tokens.gapSm;
    final topRowBottomSpacing = style.topRowBottomSpacing ?? tokens.gapMd;
    final labelBottomSpacing = style.labelBottomSpacing ?? tokens.gapXs;

    final labelStyle =
        style.labelTextStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          color: _useOnPrimaryContainer
              ? colors.onPrimaryContainer
              : colors.onSurfaceVariant,
        );
    final valueStyle =
        style.valueTextStyle ??
        theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: _useOnPrimaryContainer ? colors.onPrimaryContainer : null,
        );

    var resolvedCardColor = style.cardColor;
    if (resolvedCardColor == null && style.cardDecoration == null) {
      resolvedCardColor = switch (emphasis) {
        AppMetricStatCardEmphasis.hero => colors.primaryContainer,
        AppMetricStatCardEmphasis.accent => Color.alphaBlend(
          colors.primaryContainer.withValues(alpha: 0.65),
          colors.surfaceContainerLowest,
        ),
        AppMetricStatCardEmphasis.standard => null,
      };
    }

    final usePill = style.showTrendPill ?? showTrendPill;
    final trimmedTrend = trendLabel?.trim() ?? '';
    final hasTextTrend = trimmedTrend.isNotEmpty;
    final hasCustomTrend = trendWidget != null;
    final showTrendRegion = hasCustomTrend || hasTextTrend;

    final Widget? builtTextTrend = !hasTextTrend
        ? null
        : usePill
        ? _MetricTrendPill(
            text: trimmedTrend,
            tokens: tokens,
            theme: theme,
            colors: colors,
            textAlign:
                style.trendTextAlign ??
                (trendPlacement == AppMetricStatTrendPlacement.end
                    ? TextAlign.end
                    : TextAlign.start),
          )
        : Text(
            trimmedTrend,
            textAlign:
                style.trendTextAlign ??
                (trendPlacement == AppMetricStatTrendPlacement.end
                    ? TextAlign.end
                    : TextAlign.start),
            style:
                style.trendTextStyle ??
                theme.textTheme.labelLarge?.copyWith(
                  color: metricDeltaForeground(
                    colors,
                    parseMetricDeltaSign(trimmedTrend),
                  ),
                  fontWeight: FontWeight.w700,
                ),
          );

    final resolvedTrend = hasCustomTrend ? trendWidget : builtTextTrend;

    final Widget topRow = switch (trendPlacement) {
      AppMetricStatTrendPlacement.end => showTrendRegion
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                leading,
                SizedBox(width: leadingSpacing),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: resolvedTrend ?? const SizedBox.shrink(),
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[leading],
            ),
      AppMetricStatTrendPlacement.inlineStart => showTrendRegion
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                leading,
                SizedBox(width: leadingSpacing),
                ?resolvedTrend,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[leading],
            ),
    };

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        topRow,
        SizedBox(height: topRowBottomSpacing),
        labelWidget ??
            Text(
              label,
              style: labelStyle,
              textAlign: style.labelTextAlign,
            ),
        SizedBox(height: labelBottomSpacing),
        valueWidget ??
            Text(
              value,
              style: valueStyle,
              textAlign: style.valueTextAlign,
            ),
      ],
    );

    final direction = Directionality.of(context);
    final inkWellBorderRadius = style.borderRadius != null
        ? style.borderRadius!.resolve(direction)
        : BorderRadius.circular(tokens.cardRadius);

    Widget child = AppSectionCard(
      color: resolvedCardColor,
      padding: style.cardPadding,
      borderRadius: style.borderRadius,
      borderSide: style.borderSide,
      decoration: style.cardDecoration,
      child: body,
    );
    if (onTap != null) {
      child = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: inkWellBorderRadius,
          child: child,
        ),
      );
    }
    final resolvedTooltipMessage = tooltipMessage;
    if (resolvedTooltipMessage != null &&
        resolvedTooltipMessage.trim().isNotEmpty) {
      child = Tooltip(message: resolvedTooltipMessage, child: child);
    }
    if (onTap != null) {
      child = Semantics(
        button: true,
        label: _resolvedSemanticsLabel,
        child: child,
      );
    }
    return child;
  }
}

class _MetricTrendPill extends StatelessWidget {
  const _MetricTrendPill({
    required this.text,
    required this.tokens,
    required this.theme,
    required this.colors,
    required this.textAlign,
  });

  final String text;
  final AppThemeTokens tokens;
  final ThemeData theme;
  final AppColors colors;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final sign = parseMetricDeltaSign(text);
    final fg = metricDeltaPillForeground(colors, sign);
    final bg = metricDeltaPillBackground(colors, sign);
    final baseStyle = theme.textTheme.labelLarge?.copyWith(
      color: fg,
      fontWeight: FontWeight.w700,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapSm,
          vertical: tokens.gapXs * 0.75,
        ),
        child: Text(
          text,
          textAlign: textAlign,
          style: baseStyle,
        ),
      ),
    );
  }
}
