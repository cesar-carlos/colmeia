import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
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

/// Visual structure of the KPI tile.
enum AppMetricStatCardLayout {
  /// Icon and trend share the top row; label then value (legacy / sparklines).
  classic,

  /// Title row (label + icon), value, trend row — common dashboard reference.
  stacked,
}

/// Where the trend label sits relative to the leading widget on the top row
/// ([AppMetricStatCardLayout.classic] only).
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
    this.headerToValueSpacing,
    this.valueToTrendSpacing,
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

  /// Spacing between title row and value ([AppMetricStatCardLayout.stacked]).
  final double? headerToValueSpacing;

  /// Spacing between value and trend row ([AppMetricStatCardLayout.stacked]).
  final double? valueToTrendSpacing;
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
    this.layout = AppMetricStatCardLayout.stacked,
    this.trendPlacement = AppMetricStatTrendPlacement.end,
    this.style = const AppMetricStatCardStyle(),
    this.tooltipMessage,
    this.semanticsLabel,
    this.onTap,
    this.labelWidget,
    this.valueWidget,
    this.trendWidget,
    this.showTrendPill,
  });

  final Widget leading;
  final String? trendLabel;
  final String label;
  final String value;
  final AppMetricStatCardEmphasis emphasis;
  final AppMetricStatCardLayout layout;
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
  /// [AppMetricStatCardLayout.stacked] defaults to inline rich text + icon;
  /// set to true for a pill on the bottom row.
  ///
  /// [AppMetricStatCardStyle.showTrendPill] overrides this when non-null.
  ///
  /// When null, classic layout defaults to pill; stacked defaults to inline
  /// rich text + trend icon.
  final bool? showTrendPill;

  /// `end`: trend at the row end (paired KPIs). `inlineStart`: icon + delta
  /// grouped at the start (full-width / compact metrics). Only used when
  /// [layout] is [AppMetricStatCardLayout.classic].
  final AppMetricStatTrendPlacement trendPlacement;

  bool _effectiveTrendPill(AppMetricStatCardLayout forLayout) {
    if (style.showTrendPill != null) {
      return style.showTrendPill!;
    }
    if (showTrendPill != null) {
      return showTrendPill!;
    }
    return forLayout == AppMetricStatCardLayout.classic;
  }

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

    final body = switch (layout) {
      AppMetricStatCardLayout.classic => _MetricStatClassicLayout(card: this),
      AppMetricStatCardLayout.stacked => _MetricStatStackedLayout(card: this),
    };

    final direction = Directionality.of(context);
    final inkWellBorderRadius = style.borderRadius != null
        ? style.borderRadius!.resolve(direction)
        : BorderRadius.circular(tokens.cardRadius);

    Widget child = AppSectionCard(
      color: _resolvedCardColor(colors),
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

  Color? _resolvedCardColor(AppColors colors) {
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
    return resolvedCardColor;
  }
}

class _MetricStatClassicLayout extends StatelessWidget {
  const _MetricStatClassicLayout({required this.card});

  final AppMetricStatCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;
    final typography = theme.appTypography;
    final style = card.style;

    final leadingSpacing = style.leadingSpacing ?? tokens.gapSm;
    final topRowBottomSpacing = style.topRowBottomSpacing ?? tokens.gapMd;
    final labelBottomSpacing = style.labelBottomSpacing ?? tokens.gapXs;

    final labelStyle =
        style.labelTextStyle ??
        typography.body.copyWith(
          color: card._useOnPrimaryContainer
              ? colors.onPrimaryContainer
              : colors.onSurfaceVariant,
        );
    final valueStyle =
        style.valueTextStyle ??
        typography.displayH1.copyWith(
          fontSize: theme.textTheme.headlineSmall?.fontSize,
          fontWeight: FontWeight.w800,
          color: card._useOnPrimaryContainer ? colors.onPrimaryContainer : null,
        );

    final usePill = card._effectiveTrendPill(AppMetricStatCardLayout.classic);
    final trimmedTrend = card.trendLabel?.trim() ?? '';
    final hasTextTrend = trimmedTrend.isNotEmpty;
    final hasCustomTrend = card.trendWidget != null;
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
                (card.trendPlacement == AppMetricStatTrendPlacement.end
                    ? TextAlign.end
                    : TextAlign.start),
          )
        : Text(
            trimmedTrend,
            textAlign:
                style.trendTextAlign ??
                (card.trendPlacement == AppMetricStatTrendPlacement.end
                    ? TextAlign.end
                    : TextAlign.start),
            style:
                style.trendTextStyle ??
                typography.utilityOverline.copyWith(
                  letterSpacing: 0.2,
                  color: metricDeltaForeground(
                    colors,
                    parseMetricDeltaSign(trimmedTrend),
                  ),
                  fontWeight: FontWeight.w700,
                ),
          );

    final resolvedTrend = hasCustomTrend ? card.trendWidget : builtTextTrend;

    final Widget topRow = switch (card.trendPlacement) {
      AppMetricStatTrendPlacement.end =>
        showTrendRegion
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  card.leading,
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
                children: <Widget>[card.leading],
              ),
      AppMetricStatTrendPlacement.inlineStart =>
        showTrendRegion
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  card.leading,
                  SizedBox(width: leadingSpacing),
                  resolvedTrend ?? const SizedBox.shrink(),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[card.leading],
              ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        topRow,
        SizedBox(height: topRowBottomSpacing),
        card.labelWidget ??
            Text(
              card.label,
              style: labelStyle,
              textAlign: style.labelTextAlign,
            ),
        SizedBox(height: labelBottomSpacing),
        card.valueWidget ??
            Text(
              card.value,
              style: valueStyle,
              textAlign: style.valueTextAlign,
            ),
      ],
    );
  }
}

class _MetricStatStackedLayout extends StatelessWidget {
  const _MetricStatStackedLayout({required this.card});

  final AppMetricStatCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;
    final typography = theme.appTypography;
    final style = card.style;

    final headerToValue = style.headerToValueSpacing ?? tokens.gapSm;
    final valueToTrend = style.valueToTrendSpacing ?? tokens.gapSm;

    final stackedLabelStyle =
        style.labelTextStyle ??
        typography.utilityOverline.copyWith(
          color: card._useOnPrimaryContainer
              ? colors.onPrimaryContainer
              : colors.onSurfaceVariant,
        );

    final valueStyle =
        style.valueTextStyle ??
        typography.displayH1.copyWith(
          fontSize: theme.textTheme.headlineSmall?.fontSize,
          fontWeight: FontWeight.w800,
          color: card._useOnPrimaryContainer ? colors.onPrimaryContainer : null,
        );

    final usePill = card._effectiveTrendPill(AppMetricStatCardLayout.stacked);
    final trimmedTrend = card.trendLabel?.trim() ?? '';
    final hasTextTrend = trimmedTrend.isNotEmpty;
    final hasCustomTrend = card.trendWidget != null;
    final showTrendRegion = hasCustomTrend || hasTextTrend;

    final Widget? builtTextTrend = !hasTextTrend
        ? null
        : usePill
        ? _MetricTrendPill(
            text: trimmedTrend,
            tokens: tokens,
            theme: theme,
            colors: colors,
            textAlign: style.trendTextAlign ?? TextAlign.start,
          )
        : _MetricTrendRichLine(
            text: trimmedTrend,
            tokens: tokens,
            theme: theme,
            colors: colors,
            typography: typography,
            style: style.trendTextStyle,
          );

    final trendBlock = !showTrendRegion
        ? null
        : hasCustomTrend && builtTextTrend != null
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: builtTextTrend),
              SizedBox(width: tokens.gapSm),
              card.trendWidget!,
            ],
          )
        : hasCustomTrend
        ? card.trendWidget
        : builtTextTrend;

    final headerRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child:
              card.labelWidget ??
              Text(
                card.label,
                style: stackedLabelStyle,
                textAlign: style.labelTextAlign ?? TextAlign.start,
              ),
        ),
        SizedBox(width: tokens.gapSm),
        card.leading,
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        headerRow,
        SizedBox(height: headerToValue),
        card.valueWidget ??
            Text(
              card.value,
              style: valueStyle,
              textAlign: style.valueTextAlign ?? TextAlign.start,
            ),
        if (trendBlock != null) ...<Widget>[
          SizedBox(height: valueToTrend),
          trendBlock,
        ],
      ],
    );
  }
}

class _MetricTrendRichLine extends StatelessWidget {
  const _MetricTrendRichLine({
    required this.text,
    required this.tokens,
    required this.theme,
    required this.colors,
    required this.typography,
    this.style,
  });

  final String text;
  final AppThemeTokens tokens;
  final ThemeData theme;
  final AppColors colors;
  final AppTypographyTokens typography;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final sign = parseMetricDeltaSign(text);
    final fg = metricDeltaForeground(colors, sign);
    final split = splitMetricTrendLabel(text);
    final baseStyle =
        style ??
        typography.caption.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.35,
        );

    final primaryStyle = baseStyle.copyWith(color: fg);
    final suffixStyle = baseStyle.copyWith(color: colors.onSurfaceVariant);

    final icon = Icon(
      metricDeltaTrendIcon(sign),
      size: 18,
      color: fg,
    );

    final rich = Text.rich(
      TextSpan(
        style: baseStyle,
        children: <InlineSpan>[
          TextSpan(text: split.primary, style: primaryStyle),
          if (split.suffix != null)
            TextSpan(text: ' ${split.suffix}', style: suffixStyle),
        ],
      ),
      textAlign: TextAlign.start,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: tokens.gapXs * 0.25),
          child: icon,
        ),
        SizedBox(width: tokens.gapXs),
        Expanded(child: rich),
      ],
    );
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
    final baseStyle = theme.appTypography.utilityOverline.copyWith(
      letterSpacing: 0.2,
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
