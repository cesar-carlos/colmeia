import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class AppTextActionButton extends StatelessWidget {
  const AppTextActionButton({
    required this.onPressed,
    super.key,
    this.label,
    this.child,
    this.icon,
    this.isLoading = false,
    this.style,
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

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final minH = tokens?.actionButtonMinHeight ?? 48;

    final effectiveStyle =
        style ??
        TextButton.styleFrom(
          minimumSize: Size(48, minH),
        );

    final gapSm = tokens?.gapSm ?? 8;
    final content = isLoading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : _buildLabelRow(gapSm);

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: effectiveStyle,
      child: content,
    );
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
