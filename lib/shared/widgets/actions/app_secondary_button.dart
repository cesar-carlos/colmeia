import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/action_button_helpers.dart';
import 'package:flutter/material.dart';

/// Visual style for [AppSecondaryButton].
enum AppSecondaryButtonVariant {
  /// Amber border, transparent fill — matches Colmeia BI “secondary outline”.
  outline,

  /// M3 filled tonal — softer alternative on busy surfaces.
  tonal,
}

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    required this.onPressed,
    super.key,
    this.label,
    this.child,
    this.icon,
    this.isLoading = false,
    this.style,
    this.loadingIndicatorColor,
    this.loadingIndicatorSize,
    this.loadingIndicatorStrokeWidth,
    this.semanticsLabel,
    this.fillWidth = false,
    this.variant = AppSecondaryButtonVariant.outline,
  }) : assert(
         (label != null) ^ (child != null),
         'Provide exactly one of label or child',
       );

  final VoidCallback? onPressed;
  final String? label;
  final Widget? child;
  final Widget? icon;
  final bool isLoading;
  final ButtonStyle? style;

  /// Outline: defaults to [ColorScheme.primary]. Tonal: defaults to
  /// [ColorScheme.onSecondaryContainer].
  final Color? loadingIndicatorColor;

  /// Defaults to [AppThemeTokens.actionButtonLoadingIndicatorSize].
  final double? loadingIndicatorSize;

  /// Defaults to [AppThemeTokens.actionButtonLoadingIndicatorStrokeWidth].
  final double? loadingIndicatorStrokeWidth;
  final String? semanticsLabel;

  /// When true, expands to the maximum width offered by the parent row.
  final bool fillWidth;

  final AppSecondaryButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      AppSecondaryButtonVariant.outline => _buildOutline(context),
      AppSecondaryButtonVariant.tonal => _buildTonal(context),
    };
  }

  Widget _buildOutline(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();
    final minH = tokens?.actionButtonMinHeight ?? 48;
    final loadingSize =
        loadingIndicatorSize ?? tokens?.actionButtonLoadingIndicatorSize ?? 22;
    final loadingStroke =
        loadingIndicatorStrokeWidth ??
        tokens?.actionButtonLoadingIndicatorStrokeWidth ??
        2;
    final radius = resolveAppActionButtonRadius(tokens);
    final scheme = theme.colorScheme;
    final primary = scheme.primary;
    final labelStyle = resolveAppActionButtonTextStyle(theme);
    final indicatorColor = loadingIndicatorColor ?? primary;

    var effectiveStyle =
        style ??
        OutlinedButton.styleFrom(
          foregroundColor: primary,
          backgroundColor: Colors.transparent,
          disabledForegroundColor: resolveAppActionButtonDisabledForeground(
            scheme,
          ),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.72)),
          elevation: 0,
          minimumSize: Size(48, minH),
          textStyle: labelStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        );

    if (fillWidth) {
      effectiveStyle = effectiveStyle.merge(
        OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, minH),
          maximumSize: Size(double.infinity, minH),
        ),
      );
    }

    final gapSm = tokens?.gapSm ?? 8;
    final content = isLoading
        ? buildAppActionButtonProgressIndicator(
            context: context,
            color: indicatorColor,
            size: loadingSize,
            strokeWidth: loadingStroke,
          )
        : _buildLabelRow(context, gapSm, primary);

    return wrapAppActionButtonSemantics(
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: effectiveStyle,
        child: content,
      ),
      isLoading: isLoading,
      onPressed: onPressed,
      semanticsLabel: semanticsLabel,
      labelForLoadingAnnouncement: label,
    );
  }

  Widget _buildTonal(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();
    final minH = tokens?.actionButtonMinHeight ?? 48;
    final loadingSize =
        loadingIndicatorSize ?? tokens?.actionButtonLoadingIndicatorSize ?? 22;
    final loadingStroke =
        loadingIndicatorStrokeWidth ??
        tokens?.actionButtonLoadingIndicatorStrokeWidth ??
        2;
    final radius = resolveAppActionButtonRadius(tokens);
    final scheme = theme.colorScheme;
    final ghostFill = Color.alphaBlend(
      scheme.primaryContainer.withValues(alpha: 0.08),
      scheme.surfaceContainerHigh,
    );
    final labelStyle = resolveAppActionButtonTextStyle(theme);
    final indicatorColor = loadingIndicatorColor ?? scheme.onSecondaryContainer;

    var effectiveStyle =
        style ??
        FilledButton.styleFrom(
          minimumSize: Size(48, minH),
          foregroundColor: scheme.onSecondaryContainer,
          backgroundColor: ghostFill,
          disabledBackgroundColor: resolveAppActionButtonDisabledBackground(
            scheme,
          ),
          disabledForegroundColor: resolveAppActionButtonDisabledForeground(
            scheme,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: labelStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        );

    if (fillWidth) {
      effectiveStyle = effectiveStyle.merge(
        FilledButton.styleFrom(
          minimumSize: Size(double.infinity, minH),
          maximumSize: Size(double.infinity, minH),
        ),
      );
    }

    final gapSm = tokens?.gapSm ?? 8;
    final content = isLoading
        ? buildAppActionButtonProgressIndicator(
            context: context,
            color: indicatorColor,
            size: loadingSize,
            strokeWidth: loadingStroke,
          )
        : _buildLabelRow(context, gapSm, scheme.primary);

    return wrapAppActionButtonSemantics(
      child: FilledButton.tonal(
        onPressed: isLoading ? null : onPressed,
        style: effectiveStyle,
        child: content,
      ),
      isLoading: isLoading,
      onPressed: onPressed,
      semanticsLabel: semanticsLabel,
      labelForLoadingAnnouncement: label,
    );
  }

  Widget _buildLabelRow(
    BuildContext context,
    double iconTextGap,
    Color iconColor,
  ) {
    if (child != null) {
      return child!;
    }

    final text = Text(
      label!,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
    if (icon == null) {
      return text;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconTheme.merge(
          data: IconThemeData(size: 20, color: iconColor),
          child: icon!,
        ),
        SizedBox(width: iconTextGap),
        Flexible(child: text),
      ],
    );
  }
}
