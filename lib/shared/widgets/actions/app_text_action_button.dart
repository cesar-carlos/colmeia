import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/action_button_helpers.dart';
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

  /// Defaults to [ColorScheme.primary] when null.
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
    final loadingSize =
        loadingIndicatorSize ?? tokens?.actionButtonLoadingIndicatorSize ?? 22;
    final loadingStroke = loadingIndicatorStrokeWidth ??
        tokens?.actionButtonLoadingIndicatorStrokeWidth ??
        2;
    final indicatorColor =
        loadingIndicatorColor ?? theme.colorScheme.primary;

    final effectiveStyle =
        style ??
        TextButton.styleFrom(
          minimumSize: Size(48, minH),
        );

    final gapSm = tokens?.gapSm ?? 8;
    final content = isLoading
        ? buildAppActionButtonProgressIndicator(
            color: indicatorColor,
            size: loadingSize,
            strokeWidth: loadingStroke,
          )
        : _buildLabelRow(context, gapSm);

    return wrapAppActionButtonSemantics(
      child: TextButton(
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

  Widget _buildLabelRow(BuildContext context, double iconTextGap) {
    if (child != null) {
      return child!;
    }

    final iconColor = Theme.of(context).colorScheme.primary;
    final text = Text(
      label!,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
