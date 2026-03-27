import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.success,
    required this.warning,
    required this.chartSeriesPrimary,
    required this.chartSeriesSecondary,
    required this.chartSeriesTertiary,
    required this.cardRadius,
    required this.gapXs,
    required this.gapSm,
    required this.gapMd,
    required this.contentSpacing,
    required this.sectionSpacing,
    required this.chartCompactHeight,
    required this.chartStandardHeight,
    required this.authGlassBlurSigma,
    required this.authGlassSurfaceOpacity,
    required this.authGlassCornerRadius,
    required this.authGlassPadding,
    required this.authLoginContentMaxWidth,
    required this.authHeroContainerSize,
    required this.authHeroGlyphSize,
    required this.authHeroCornerRadius,
    required this.authLoginCtaMinHeight,
    required this.authLoginScrollPaddingHorizontal,
    required this.authLoginScrollPaddingVertical,
    required this.authLoginGapBrandToForm,
    required this.authLoginGapHeroToTitle,
    required this.authLoginGapMajorSection,
    required this.authLoginGapBetweenFields,
    required this.authLoginGapAfterPassword,
    required this.authLoginGapAfterPrimary,
    required this.authLoginGapBeforeFooter,
    required this.inlineAlertCornerRadius,
    required this.hexGridPatternOpacity,
    required this.formFieldRadius,
    required this.formFieldPaddingHorizontal,
    required this.formFieldPaddingVerticalComfortable,
    required this.formFieldPaddingVerticalCompact,
    required this.formLabelToControlGap,
    required this.formControlCheckboxSide,
    required this.formControlRadioOuter,
    required this.actionButtonMinHeight,
  });

  final Color success;
  final Color warning;

  /// Hive Grid: primary scale for main series (distinct from semantic success).
  final Color chartSeriesPrimary;
  final Color chartSeriesSecondary;
  final Color chartSeriesTertiary;
  final double cardRadius;

  /// Tight vertical/horizontal rhythm (e.g. stacked labels).
  final double gapXs;

  /// Small gap between related elements (matches [formLabelToControlGap]).
  final double gapSm;

  /// Medium gap (e.g. icon-to-text in rows).
  final double gapMd;

  final double contentSpacing;
  final double sectionSpacing;
  final double chartCompactHeight;
  final double chartStandardHeight;

  final double authGlassBlurSigma;
  final double authGlassSurfaceOpacity;
  final double authGlassCornerRadius;
  final double authGlassPadding;
  final double authLoginContentMaxWidth;
  final double authHeroContainerSize;
  final double authHeroGlyphSize;
  final double authHeroCornerRadius;

  /// Primary login CTA minimum height.
  final double authLoginCtaMinHeight;

  /// Horizontal padding for the login/register scroll body.
  final double authLoginScrollPaddingHorizontal;

  /// Vertical padding for the login/register scroll body.
  final double authLoginScrollPaddingVertical;

  /// Space between brand header and the glass card.
  final double authLoginGapBrandToForm;

  /// Space between hero glyph and title in the brand header.
  final double authLoginGapHeroToTitle;

  /// Large vertical breaks inside the auth form (e.g. welcome block, pre-CTA).
  final double authLoginGapMajorSection;

  /// Space between stacked fields (email / password).
  final double authLoginGapBetweenFields;

  /// Space after the password field before remember-me row.
  final double authLoginGapAfterPassword;

  /// Space after the primary CTA before secondary actions.
  final double authLoginGapAfterPrimary;

  /// Space between glass card and footer on login.
  final double authLoginGapBeforeFooter;

  /// Corner radius for inline error/success alert panels.
  final double inlineAlertCornerRadius;

  /// Default opacity for the shared honeycomb hex grid background.
  final double hexGridPatternOpacity;

  /// Text fields, [InputDecoration] borders, and themed button corners.
  /// Stitch `ROUND_FOUR` → 4 logical pixels.
  final double formFieldRadius;

  /// Horizontal padding inside text fields (`InputDecoration.contentPadding`).
  final double formFieldPaddingHorizontal;

  /// Default vertical padding for standard single-line fields.
  final double formFieldPaddingVerticalComfortable;

  /// Tighter vertical padding for dense field layouts.
  final double formFieldPaddingVerticalCompact;

  /// Vertical gap between an external label and the control.
  final double formLabelToControlGap;

  /// Side length for checkbox hit target / visual scale.
  final double formControlCheckboxSide;

  /// Outer size hint for radio circles in custom layouts.
  final double formControlRadioOuter;

  /// Minimum height for primary/secondary action buttons.
  final double actionButtonMinHeight;

  static const AppThemeTokens light = AppThemeTokens(
    success: Color(0xFF00677E),
    warning: Color(0xFFDC813B),
    chartSeriesPrimary: Color(0xFF7E5700),
    chartSeriesSecondary: Color(0xFFDC813B),
    chartSeriesTertiary: Color(0xFF2DB6D1),
    cardRadius: 24,
    gapXs: 4,
    gapSm: 8,
    gapMd: 12,
    contentSpacing: 16,
    sectionSpacing: 24,
    chartCompactHeight: 180,
    chartStandardHeight: 260,
    authGlassBlurSigma: 20,
    authGlassSurfaceOpacity: 0.88,
    authGlassCornerRadius: 24,
    authGlassPadding: 40,
    authLoginContentMaxWidth: 480,
    authHeroContainerSize: 80,
    authHeroGlyphSize: 44,
    authHeroCornerRadius: 12,
    authLoginCtaMinHeight: 60,
    authLoginScrollPaddingHorizontal: 24,
    authLoginScrollPaddingVertical: 40,
    authLoginGapBrandToForm: 48,
    authLoginGapHeroToTitle: 20,
    authLoginGapMajorSection: 32,
    authLoginGapBetweenFields: 24,
    authLoginGapAfterPassword: 20,
    authLoginGapAfterPrimary: 24,
    authLoginGapBeforeFooter: 40,
    inlineAlertCornerRadius: 12,
    hexGridPatternOpacity: 0.055,
    formFieldRadius: 4,
    formFieldPaddingHorizontal: 16,
    formFieldPaddingVerticalComfortable: 16,
    formFieldPaddingVerticalCompact: 12,
    formLabelToControlGap: 8,
    formControlCheckboxSide: 20,
    formControlRadioOuter: 22,
    actionButtonMinHeight: 48,
  );

  static const AppThemeTokens dark = AppThemeTokens(
    success: Color(0xFF43D6FF),
    warning: Color(0xFFFFB691),
    chartSeriesPrimary: Color(0xFFFFBA38),
    chartSeriesSecondary: Color(0xFFFFB691),
    chartSeriesTertiary: Color(0xFF43D6FF),
    cardRadius: 24,
    gapXs: 4,
    gapSm: 8,
    gapMd: 12,
    contentSpacing: 16,
    sectionSpacing: 24,
    chartCompactHeight: 180,
    chartStandardHeight: 260,
    authGlassBlurSigma: 20,
    authGlassSurfaceOpacity: 0.88,
    authGlassCornerRadius: 24,
    authGlassPadding: 40,
    authLoginContentMaxWidth: 480,
    authHeroContainerSize: 80,
    authHeroGlyphSize: 44,
    authHeroCornerRadius: 12,
    authLoginCtaMinHeight: 60,
    authLoginScrollPaddingHorizontal: 24,
    authLoginScrollPaddingVertical: 40,
    authLoginGapBrandToForm: 48,
    authLoginGapHeroToTitle: 20,
    authLoginGapMajorSection: 32,
    authLoginGapBetweenFields: 24,
    authLoginGapAfterPassword: 20,
    authLoginGapAfterPrimary: 24,
    authLoginGapBeforeFooter: 40,
    inlineAlertCornerRadius: 12,
    hexGridPatternOpacity: 0.055,
    formFieldRadius: 4,
    formFieldPaddingHorizontal: 16,
    formFieldPaddingVerticalComfortable: 16,
    formFieldPaddingVerticalCompact: 12,
    formLabelToControlGap: 8,
    formControlCheckboxSide: 20,
    formControlRadioOuter: 22,
    actionButtonMinHeight: 48,
  );

  @override
  AppThemeTokens copyWith({
    Color? success,
    Color? warning,
    Color? chartSeriesPrimary,
    Color? chartSeriesSecondary,
    Color? chartSeriesTertiary,
    double? cardRadius,
    double? gapXs,
    double? gapSm,
    double? gapMd,
    double? contentSpacing,
    double? sectionSpacing,
    double? chartCompactHeight,
    double? chartStandardHeight,
    double? authGlassBlurSigma,
    double? authGlassSurfaceOpacity,
    double? authGlassCornerRadius,
    double? authGlassPadding,
    double? authLoginContentMaxWidth,
    double? authHeroContainerSize,
    double? authHeroGlyphSize,
    double? authHeroCornerRadius,
    double? authLoginCtaMinHeight,
    double? authLoginScrollPaddingHorizontal,
    double? authLoginScrollPaddingVertical,
    double? authLoginGapBrandToForm,
    double? authLoginGapHeroToTitle,
    double? authLoginGapMajorSection,
    double? authLoginGapBetweenFields,
    double? authLoginGapAfterPassword,
    double? authLoginGapAfterPrimary,
    double? authLoginGapBeforeFooter,
    double? inlineAlertCornerRadius,
    double? hexGridPatternOpacity,
    double? formFieldRadius,
    double? formFieldPaddingHorizontal,
    double? formFieldPaddingVerticalComfortable,
    double? formFieldPaddingVerticalCompact,
    double? formLabelToControlGap,
    double? formControlCheckboxSide,
    double? formControlRadioOuter,
    double? actionButtonMinHeight,
  }) {
    return AppThemeTokens(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      chartSeriesPrimary: chartSeriesPrimary ?? this.chartSeriesPrimary,
      chartSeriesSecondary: chartSeriesSecondary ?? this.chartSeriesSecondary,
      chartSeriesTertiary: chartSeriesTertiary ?? this.chartSeriesTertiary,
      cardRadius: cardRadius ?? this.cardRadius,
      gapXs: gapXs ?? this.gapXs,
      gapSm: gapSm ?? this.gapSm,
      gapMd: gapMd ?? this.gapMd,
      contentSpacing: contentSpacing ?? this.contentSpacing,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      chartCompactHeight: chartCompactHeight ?? this.chartCompactHeight,
      chartStandardHeight: chartStandardHeight ?? this.chartStandardHeight,
      authGlassBlurSigma: authGlassBlurSigma ?? this.authGlassBlurSigma,
      authGlassSurfaceOpacity:
          authGlassSurfaceOpacity ?? this.authGlassSurfaceOpacity,
      authGlassCornerRadius:
          authGlassCornerRadius ?? this.authGlassCornerRadius,
      authGlassPadding: authGlassPadding ?? this.authGlassPadding,
      authLoginContentMaxWidth:
          authLoginContentMaxWidth ?? this.authLoginContentMaxWidth,
      authHeroContainerSize:
          authHeroContainerSize ?? this.authHeroContainerSize,
      authHeroGlyphSize: authHeroGlyphSize ?? this.authHeroGlyphSize,
      authHeroCornerRadius: authHeroCornerRadius ?? this.authHeroCornerRadius,
      authLoginCtaMinHeight:
          authLoginCtaMinHeight ?? this.authLoginCtaMinHeight,
      authLoginScrollPaddingHorizontal:
          authLoginScrollPaddingHorizontal ??
          this.authLoginScrollPaddingHorizontal,
      authLoginScrollPaddingVertical:
          authLoginScrollPaddingVertical ??
          this.authLoginScrollPaddingVertical,
      authLoginGapBrandToForm:
          authLoginGapBrandToForm ?? this.authLoginGapBrandToForm,
      authLoginGapHeroToTitle:
          authLoginGapHeroToTitle ?? this.authLoginGapHeroToTitle,
      authLoginGapMajorSection:
          authLoginGapMajorSection ?? this.authLoginGapMajorSection,
      authLoginGapBetweenFields:
          authLoginGapBetweenFields ?? this.authLoginGapBetweenFields,
      authLoginGapAfterPassword:
          authLoginGapAfterPassword ?? this.authLoginGapAfterPassword,
      authLoginGapAfterPrimary:
          authLoginGapAfterPrimary ?? this.authLoginGapAfterPrimary,
      authLoginGapBeforeFooter:
          authLoginGapBeforeFooter ?? this.authLoginGapBeforeFooter,
      inlineAlertCornerRadius:
          inlineAlertCornerRadius ?? this.inlineAlertCornerRadius,
      hexGridPatternOpacity:
          hexGridPatternOpacity ?? this.hexGridPatternOpacity,
      formFieldRadius: formFieldRadius ?? this.formFieldRadius,
      formFieldPaddingHorizontal:
          formFieldPaddingHorizontal ?? this.formFieldPaddingHorizontal,
      formFieldPaddingVerticalComfortable:
          formFieldPaddingVerticalComfortable ??
          this.formFieldPaddingVerticalComfortable,
      formFieldPaddingVerticalCompact:
          formFieldPaddingVerticalCompact ??
          this.formFieldPaddingVerticalCompact,
      formLabelToControlGap:
          formLabelToControlGap ?? this.formLabelToControlGap,
      formControlCheckboxSide:
          formControlCheckboxSide ?? this.formControlCheckboxSide,
      formControlRadioOuter:
          formControlRadioOuter ?? this.formControlRadioOuter,
      actionButtonMinHeight:
          actionButtonMinHeight ?? this.actionButtonMinHeight,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) {
      return this;
    }

    return AppThemeTokens(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      chartSeriesPrimary:
          Color.lerp(chartSeriesPrimary, other.chartSeriesPrimary, t) ??
          chartSeriesPrimary,
      chartSeriesSecondary:
          Color.lerp(chartSeriesSecondary, other.chartSeriesSecondary, t) ??
          chartSeriesSecondary,
      chartSeriesTertiary:
          Color.lerp(chartSeriesTertiary, other.chartSeriesTertiary, t) ??
          chartSeriesTertiary,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t) ?? cardRadius,
      gapXs: lerpDouble(gapXs, other.gapXs, t) ?? gapXs,
      gapSm: lerpDouble(gapSm, other.gapSm, t) ?? gapSm,
      gapMd: lerpDouble(gapMd, other.gapMd, t) ?? gapMd,
      contentSpacing:
          lerpDouble(contentSpacing, other.contentSpacing, t) ?? contentSpacing,
      sectionSpacing:
          lerpDouble(sectionSpacing, other.sectionSpacing, t) ?? sectionSpacing,
      chartCompactHeight:
          lerpDouble(
            chartCompactHeight,
            other.chartCompactHeight,
            t,
          ) ??
          chartCompactHeight,
      chartStandardHeight:
          lerpDouble(
            chartStandardHeight,
            other.chartStandardHeight,
            t,
          ) ??
          chartStandardHeight,
      authGlassBlurSigma:
          lerpDouble(
            authGlassBlurSigma,
            other.authGlassBlurSigma,
            t,
          ) ??
          authGlassBlurSigma,
      authGlassSurfaceOpacity:
          lerpDouble(
            authGlassSurfaceOpacity,
            other.authGlassSurfaceOpacity,
            t,
          ) ??
          authGlassSurfaceOpacity,
      authGlassCornerRadius:
          lerpDouble(
            authGlassCornerRadius,
            other.authGlassCornerRadius,
            t,
          ) ??
          authGlassCornerRadius,
      authGlassPadding:
          lerpDouble(authGlassPadding, other.authGlassPadding, t) ??
          authGlassPadding,
      authLoginContentMaxWidth:
          lerpDouble(
            authLoginContentMaxWidth,
            other.authLoginContentMaxWidth,
            t,
          ) ??
          authLoginContentMaxWidth,
      authHeroContainerSize:
          lerpDouble(
            authHeroContainerSize,
            other.authHeroContainerSize,
            t,
          ) ??
          authHeroContainerSize,
      authHeroGlyphSize:
          lerpDouble(authHeroGlyphSize, other.authHeroGlyphSize, t) ??
          authHeroGlyphSize,
      authHeroCornerRadius:
          lerpDouble(
            authHeroCornerRadius,
            other.authHeroCornerRadius,
            t,
          ) ??
          authHeroCornerRadius,
      authLoginCtaMinHeight:
          lerpDouble(
            authLoginCtaMinHeight,
            other.authLoginCtaMinHeight,
            t,
          ) ??
          authLoginCtaMinHeight,
      authLoginScrollPaddingHorizontal:
          lerpDouble(
            authLoginScrollPaddingHorizontal,
            other.authLoginScrollPaddingHorizontal,
            t,
          ) ??
          authLoginScrollPaddingHorizontal,
      authLoginScrollPaddingVertical:
          lerpDouble(
            authLoginScrollPaddingVertical,
            other.authLoginScrollPaddingVertical,
            t,
          ) ??
          authLoginScrollPaddingVertical,
      authLoginGapBrandToForm:
          lerpDouble(
            authLoginGapBrandToForm,
            other.authLoginGapBrandToForm,
            t,
          ) ??
          authLoginGapBrandToForm,
      authLoginGapHeroToTitle:
          lerpDouble(
            authLoginGapHeroToTitle,
            other.authLoginGapHeroToTitle,
            t,
          ) ??
          authLoginGapHeroToTitle,
      authLoginGapMajorSection:
          lerpDouble(
            authLoginGapMajorSection,
            other.authLoginGapMajorSection,
            t,
          ) ??
          authLoginGapMajorSection,
      authLoginGapBetweenFields:
          lerpDouble(
            authLoginGapBetweenFields,
            other.authLoginGapBetweenFields,
            t,
          ) ??
          authLoginGapBetweenFields,
      authLoginGapAfterPassword:
          lerpDouble(
            authLoginGapAfterPassword,
            other.authLoginGapAfterPassword,
            t,
          ) ??
          authLoginGapAfterPassword,
      authLoginGapAfterPrimary:
          lerpDouble(
            authLoginGapAfterPrimary,
            other.authLoginGapAfterPrimary,
            t,
          ) ??
          authLoginGapAfterPrimary,
      authLoginGapBeforeFooter:
          lerpDouble(
            authLoginGapBeforeFooter,
            other.authLoginGapBeforeFooter,
            t,
          ) ??
          authLoginGapBeforeFooter,
      inlineAlertCornerRadius:
          lerpDouble(
            inlineAlertCornerRadius,
            other.inlineAlertCornerRadius,
            t,
          ) ??
          inlineAlertCornerRadius,
      hexGridPatternOpacity:
          lerpDouble(
            hexGridPatternOpacity,
            other.hexGridPatternOpacity,
            t,
          ) ??
          hexGridPatternOpacity,
      formFieldRadius:
          lerpDouble(formFieldRadius, other.formFieldRadius, t) ??
          formFieldRadius,
      formFieldPaddingHorizontal:
          lerpDouble(
            formFieldPaddingHorizontal,
            other.formFieldPaddingHorizontal,
            t,
          ) ??
          formFieldPaddingHorizontal,
      formFieldPaddingVerticalComfortable:
          lerpDouble(
            formFieldPaddingVerticalComfortable,
            other.formFieldPaddingVerticalComfortable,
            t,
          ) ??
          formFieldPaddingVerticalComfortable,
      formFieldPaddingVerticalCompact:
          lerpDouble(
            formFieldPaddingVerticalCompact,
            other.formFieldPaddingVerticalCompact,
            t,
          ) ??
          formFieldPaddingVerticalCompact,
      formLabelToControlGap:
          lerpDouble(
            formLabelToControlGap,
            other.formLabelToControlGap,
            t,
          ) ??
          formLabelToControlGap,
      formControlCheckboxSide:
          lerpDouble(
            formControlCheckboxSide,
            other.formControlCheckboxSide,
            t,
          ) ??
          formControlCheckboxSide,
      formControlRadioOuter:
          lerpDouble(
            formControlRadioOuter,
            other.formControlRadioOuter,
            t,
          ) ??
          formControlRadioOuter,
      actionButtonMinHeight:
          lerpDouble(
            actionButtonMinHeight,
            other.actionButtonMinHeight,
            t,
          ) ??
          actionButtonMinHeight,
    );
  }
}
