import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Low-elevation filled tonal button for dense toolbars, drawers, and footers.
class AppFlatButton extends StatelessWidget {
  const AppFlatButton({
    required this.onPressed,
    super.key,
    this.label,
    this.child,
    this.icon,
    this.isLoading = false,
    this.fillWidth = true,
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
  final bool fillWidth;
  final ButtonStyle? style;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();
    final cs = theme.colorScheme;
    final minH = tokens?.actionButtonMinHeight ?? 48;
    final gapSm = tokens?.gapSm ?? 8;
    final radius = tokens?.formFieldRadius ?? 4;

    var resolvedStyle = FilledButton.styleFrom(
      elevation: 0,
      shadowColor: Colors.transparent,
      minimumSize: Size(48, minH),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: tokens?.gapMd ?? 12,
        vertical: gapSm,
      ),
    );

    if (fillWidth) {
      resolvedStyle = resolvedStyle.merge(
        FilledButton.styleFrom(
          minimumSize: Size(double.infinity, minH),
        ),
      );
    }

    if (style != null) {
      resolvedStyle = resolvedStyle.merge(style);
    }

    final indicatorColor = theme.progressIndicatorTheme.color ?? cs.primary;
    final content = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: indicatorColor,
            ),
          )
        : _buildIdleContent(gapSm, theme);

    Widget button = FilledButton.tonal(
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

  Widget _buildIdleContent(double iconTextGap, ThemeData theme) {
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
          data: IconThemeData(
            size: 20,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          child: icon!,
        ),
        SizedBox(width: iconTextGap),
        Flexible(child: text),
      ],
    );
  }
}
