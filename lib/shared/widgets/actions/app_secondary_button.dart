import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    required this.onPressed,
    super.key,
    this.label,
    this.child,
    this.icon,
    this.isLoading = false,
    this.style,
    this.semanticsLabel,
  }) : assert(
         label != null || child != null,
         'Provide label or child',
       );

  final VoidCallback? onPressed;
  final String? label;
  final Widget? child;
  final Widget? icon;
  final bool isLoading;
  final ButtonStyle? style;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();
    final colors = theme.appColors;
    final minH = tokens?.actionButtonMinHeight ?? 48;

    final effectiveStyle =
        style ??
        OutlinedButton.styleFrom(
          minimumSize: Size(48, minH),
        );

    final gapSm = tokens?.gapSm ?? 8;
    final content = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          )
        : _buildLabelRow(gapSm);

    Widget button = OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: effectiveStyle,
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

  Widget _buildLabelRow(double iconTextGap) {
    if (child != null) {
      return child!;
    }

    final text = Text(label!);
    if (icon == null) {
      return text;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        icon!,
        SizedBox(width: iconTextGap),
        text,
      ],
    );
  }
}
