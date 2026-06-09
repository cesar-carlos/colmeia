import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/action_button_helpers.dart';
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
  final bool fillWidth;
  final ButtonStyle? style;

  /// Defaults to the ambient progress indicator color, then app primary.
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
    final colors = theme.appColors;
    final scheme = theme.colorScheme;
    final minH = tokens?.actionButtonMinHeight ?? 48;
    final gapSm = tokens?.gapSm ?? 8;
    final radius = resolveAppActionButtonRadius(tokens);
    final loadingSize =
        loadingIndicatorSize ?? tokens?.actionButtonLoadingIndicatorSize ?? 22;
    final loadingStroke =
        loadingIndicatorStrokeWidth ??
        tokens?.actionButtonLoadingIndicatorStrokeWidth ??
        2;
    final indicatorColor =
        loadingIndicatorColor ??
        theme.progressIndicatorTheme.color ??
        colors.onSurfaceVariant;
    final ghostFill = Color.alphaBlend(
      scheme.primaryContainer.withValues(alpha: 0.08),
      scheme.surfaceContainerHigh,
    );
    final labelStyle = resolveAppActionButtonTextStyle(theme);

    var resolvedStyle = FilledButton.styleFrom(
      backgroundColor: ghostFill,
      foregroundColor: colors.onSurfaceVariant,
      disabledBackgroundColor: resolveAppActionButtonDisabledBackground(scheme),
      disabledForegroundColor: resolveAppActionButtonDisabledForeground(scheme),
      elevation: 0,
      shadowColor: Colors.transparent,
      minimumSize: Size(48, minH),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: labelStyle,
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

    final content = isLoading
        ? buildAppActionButtonProgressIndicator(
            context: context,
            color: indicatorColor,
            size: loadingSize,
            strokeWidth: loadingStroke,
          )
        : _buildIdleContent(gapSm, colors.onSurfaceVariant);

    return wrapAppActionButtonSemantics(
      child: FilledButton.tonal(
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

  Widget _buildIdleContent(double iconTextGap, Color iconColor) {
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
            color: iconColor,
          ),
          child: icon!,
        ),
        SizedBox(width: iconTextGap),
        Flexible(child: text),
      ],
    );
  }
}
