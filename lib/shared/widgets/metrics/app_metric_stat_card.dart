import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:flutter/material.dart';

enum AppMetricStatCardEmphasis {
  /// Default card surface from theme.
  standard,

  /// Highlighted background (e.g. first KPI in a row).
  accent,
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
}

/// KPI tile: leading icon, trend label, label, and primary value.
/// Reusable on dashboards, reports, and similar compact stat surfaces.
class AppMetricStatCard extends StatelessWidget {
  const AppMetricStatCard({
    required this.leading,
    required this.trendLabel,
    required this.label,
    required this.value,
    super.key,
    this.emphasis = AppMetricStatCardEmphasis.standard,
    this.trendPlacement = AppMetricStatTrendPlacement.end,
    this.style = const AppMetricStatCardStyle(),
    this.tooltipMessage,
    this.semanticsLabel,
    this.onTap,
    this.labelWidget,
    this.valueWidget,
    this.trendWidget,
  });

  final Widget leading;
  final String trendLabel;
  final String label;
  final String value;
  final AppMetricStatCardEmphasis emphasis;
  final AppMetricStatCardStyle style;
  final String? tooltipMessage;

  /// Screen reader label when [onTap] is set; defaults to [label].
  final String? semanticsLabel;
  final VoidCallback? onTap;
  final Widget? labelWidget;
  final Widget? valueWidget;
  final Widget? trendWidget;

  /// `end`: trend at the row end (paired KPIs). `inlineStart`: icon + delta
  /// grouped at the start (full-width / compact metrics).
  final AppMetricStatTrendPlacement trendPlacement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;
    final trimmedDelta = trendLabel.trim();
    final deltaNegative =
        trimmedDelta.startsWith('-') || trimmedDelta.startsWith('−');
    final deltaColor = deltaNegative ? colors.error : colors.tertiary;
    final leadingSpacing = style.leadingSpacing ?? tokens.gapSm;
    final topRowBottomSpacing = style.topRowBottomSpacing ?? tokens.gapMd;
    final labelBottomSpacing = style.labelBottomSpacing ?? tokens.gapXs;
    final trendStyle =
        style.trendTextStyle ??
        theme.textTheme.labelLarge?.copyWith(
          color: deltaColor,
          fontWeight: FontWeight.w700,
        );
    final labelStyle =
        style.labelTextStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        );
    final valueStyle =
        style.valueTextStyle ??
        theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
        );

    var resolvedCardColor = style.cardColor;
    if (resolvedCardColor == null && style.cardDecoration == null) {
      resolvedCardColor = switch (emphasis) {
        AppMetricStatCardEmphasis.accent => Color.alphaBlend(
          colors.primaryContainer.withValues(alpha: 0.65),
          colors.surfaceContainerLowest,
        ),
        AppMetricStatCardEmphasis.standard => null,
      };
    }

    final resolvedTrend =
        trendWidget ??
        Text(
          trendLabel,
          textAlign:
              style.trendTextAlign ??
              (trendPlacement == AppMetricStatTrendPlacement.end
                  ? TextAlign.end
                  : TextAlign.start),
          style: trendStyle,
        );

    final Widget topRow = switch (trendPlacement) {
      AppMetricStatTrendPlacement.end => Row(
        children: <Widget>[
          leading,
          SizedBox(width: leadingSpacing),
          Expanded(
            child: resolvedTrend,
          ),
        ],
      ),
      AppMetricStatTrendPlacement.inlineStart => Row(
        children: <Widget>[
          leading,
          SizedBox(width: leadingSpacing),
          resolvedTrend,
        ],
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
      final resolvedSemantics = semanticsLabel?.trim();
      child = Semantics(
        button: true,
        label: resolvedSemantics != null && resolvedSemantics.isNotEmpty
            ? resolvedSemantics
            : label,
        child: child,
      );
    }
    return child;
  }
}
