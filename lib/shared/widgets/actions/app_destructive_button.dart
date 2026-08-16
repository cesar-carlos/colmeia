import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/action_button_helpers.dart';
import 'package:flutter/material.dart';

/// High-emphasis destructive action (delete, remove, discard).
///
/// Uses [ColorScheme.error] / [ColorScheme.onError] in light mode; in dark mode
/// uses [ColorScheme.errorContainer] / [ColorScheme.onErrorContainer] so fills
/// stay legible when [ColorScheme.error] is a light coral. Override [style] for
/// special cases.
class AppDestructiveButton extends StatelessWidget {
  const AppDestructiveButton({
    required this.onPressed,
    super.key,
    this.label,
    this.child,
    this.icon,
    this.isLoading = false,
    this.style,
    this.fillWidth = false,
    this.loadingIndicatorColor,
    this.loadingIndicatorSize,
    this.loadingIndicatorStrokeWidth,
    this.semanticsLabel,
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
  final bool fillWidth;

  /// Defaults to the destructive on-fill color when null.
  final Color? loadingIndicatorColor;

  /// Defaults to [AppThemeTokens.actionButtonLoadingIndicatorSize].
  final double? loadingIndicatorSize;

  /// Defaults to [AppThemeTokens.actionButtonLoadingIndicatorStrokeWidth].
  final double? loadingIndicatorStrokeWidth;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();
    final minH = tokens?.actionButtonMinHeight ?? 48;
    final gapSm = tokens?.gapSm ?? 8;
    final loadingSize =
        loadingIndicatorSize ?? tokens?.actionButtonLoadingIndicatorSize ?? 22;
    final loadingStroke =
        loadingIndicatorStrokeWidth ??
        tokens?.actionButtonLoadingIndicatorStrokeWidth ??
        2;
    final radius = resolveAppActionButtonRadius(tokens);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark ? scheme.errorContainer : scheme.error;
    final onFillColor = isDark ? scheme.onErrorContainer : scheme.onError;
    final labelStyle = resolveAppActionButtonTextStyle(theme);

    var resolvedStyle =
        style ??
        FilledButton.styleFrom(
          backgroundColor: fillColor,
          foregroundColor: onFillColor,
          disabledBackgroundColor: resolveAppActionButtonDisabledBackground(
            scheme,
          ),
          disabledForegroundColor: resolveAppActionButtonDisabledForeground(
            scheme,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: Size(48, minH),
          textStyle: labelStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        );

    if (fillWidth) {
      resolvedStyle = resolvedStyle.merge(
        FilledButton.styleFrom(
          minimumSize: Size(double.infinity, minH),
          maximumSize: Size(double.infinity, minH),
        ),
      );
    }

    final indicatorColor = loadingIndicatorColor ?? onFillColor;

    final content = isLoading
        ? buildAppActionButtonProgressIndicator(
            context: context,
            color: indicatorColor,
            size: loadingSize,
            strokeWidth: loadingStroke,
          )
        : _buildIdleContent(gapSm, onFillColor);

    return wrapAppActionButtonSemantics(
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: resolvedStyle,
        child: content,
      ),
      isLoading: isLoading,
      onPressed: onPressed,
      semanticsLabel: semanticsLabel,
      labelForLoadingAnnouncement: label,
    );
  }

  Widget _buildIdleContent(double iconTextGap, Color onFill) {
    if (child != null) {
      return child!;
    }

    final text = Text(label!);
    if (icon == null) {
      return text;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconTheme.merge(
          data: IconThemeData(size: 20, color: onFill),
          child: icon!,
        ),
        SizedBox(width: iconTextGap),
        text,
      ],
    );
  }
}
