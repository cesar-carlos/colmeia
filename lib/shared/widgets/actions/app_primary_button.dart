import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/action_button_helpers.dart';
import 'package:flutter/material.dart';

/// Filled primary action using solid [ColorScheme.primary] and
/// [ColorScheme.onPrimary] (brand CTA). Override [style] for special cases.
///
/// Set [loadingIndicatorColor] when [style] changes the fill so the spinner
/// stays legible.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.onPressed,
    super.key,
    this.label,
    this.child,
    this.icon,
    this.trailing,
    this.isLoading = false,
    this.style,
    this.fillWidth = false,
    this.minimumHeight,
    this.showLabelWhileLoading = false,
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
  final Widget? trailing;
  final bool isLoading;
  final ButtonStyle? style;
  final bool fillWidth;
  final double? minimumHeight;
  final bool showLabelWhileLoading;
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
    final minH = minimumHeight ?? tokens?.actionButtonMinHeight ?? 48;
    final gapSm = tokens?.gapSm ?? 8;
    final gapMd = tokens?.gapMd ?? 12;
    final loadingSize =
        loadingIndicatorSize ?? tokens?.actionButtonLoadingIndicatorSize ?? 22;
    final loadingStroke =
        loadingIndicatorStrokeWidth ??
        tokens?.actionButtonLoadingIndicatorStrokeWidth ??
        2;

    final radius = resolveAppActionButtonRadius(tokens);
    final scheme = theme.colorScheme;
    final labelStyle = resolveAppActionButtonTextStyle(theme);
    var resolvedStyle =
        style ??
        FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
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

    final targetHeight = minimumHeight ?? minH;
    if (fillWidth) {
      resolvedStyle = resolvedStyle.merge(
        FilledButton.styleFrom(
          minimumSize: Size(double.infinity, targetHeight),
          maximumSize: Size(double.infinity, targetHeight),
        ),
      );
    } else if (minimumHeight != null) {
      resolvedStyle = resolvedStyle.merge(
        FilledButton.styleFrom(
          minimumSize: Size(48, targetHeight),
          maximumSize: Size(double.infinity, targetHeight),
        ),
      );
    }

    final indicatorColor = loadingIndicatorColor ?? theme.colorScheme.onPrimary;

    Widget content;
    if (isLoading && showLabelWhileLoading && label != null) {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          buildAppActionButtonProgressIndicator(
            context: context,
            color: indicatorColor,
            size: loadingSize,
            strokeWidth: loadingStroke,
          ),
          SizedBox(width: gapMd),
          Text(label!),
        ],
      );
    } else if (isLoading) {
      content = buildAppActionButtonProgressIndicator(
        context: context,
        color: indicatorColor,
        size: loadingSize,
        strokeWidth: loadingStroke,
      );
    } else {
      content = _buildIdleContent(context, gapSm);
    }

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

  Widget _buildIdleContent(BuildContext context, double iconTextGap) {
    if (child != null) {
      return child!;
    }

    final text = Text(label!);
    if (icon == null && trailing == null) {
      return text;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          icon!,
          SizedBox(width: iconTextGap),
        ],
        text,
        if (trailing != null) ...<Widget>[
          SizedBox(width: iconTextGap),
          trailing!,
        ],
      ],
    );
  }
}
