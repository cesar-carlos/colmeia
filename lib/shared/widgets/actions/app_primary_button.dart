import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

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
    this.loadingIndicatorSize = 22,
    this.loadingIndicatorStrokeWidth = 2,
    this.semanticsLabel,
  }) : assert(
         label != null || child != null,
         'Provide label or child',
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
  final double loadingIndicatorSize;
  final double loadingIndicatorStrokeWidth;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();
    final colors = theme.appColors;
    final minH = minimumHeight ?? tokens?.actionButtonMinHeight ?? 48;
    final gapSm = tokens?.gapSm ?? 8;
    final gapMd = tokens?.gapMd ?? 12;

    var resolvedStyle =
        style ??
        FilledButton.styleFrom(
          minimumSize: Size(48, minH),
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

    final indicatorColor = loadingIndicatorColor ?? colors.onPrimary;

    Widget content;
    if (isLoading && showLabelWhileLoading && label != null) {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: loadingIndicatorSize,
            height: loadingIndicatorSize,
            child: CircularProgressIndicator(
              strokeWidth: loadingIndicatorStrokeWidth,
              color: indicatorColor,
            ),
          ),
          SizedBox(width: gapMd),
          Text(label!),
        ],
      );
    } else if (isLoading) {
      content = SizedBox(
        width: loadingIndicatorSize,
        height: loadingIndicatorSize,
        child: CircularProgressIndicator(
          strokeWidth: loadingIndicatorStrokeWidth,
          color: indicatorColor,
        ),
      );
    } else {
      content = _buildIdleContent(context, gapSm);
    }

    Widget button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: resolvedStyle,
      child: content,
    );

    if (semanticsLabel != null) {
      button = Semantics(
        button: true,
        enabled: onPressed != null && !isLoading,
        label: semanticsLabel,
        child: button,
      );
    } else if (isLoading && label == null && child == null) {
      button = Semantics(
        button: true,
        label: 'Carregando',
        child: button,
      );
    }

    return button;
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
