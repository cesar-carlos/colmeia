import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class AppInlinePaginationBarStyle {
  const AppInlinePaginationBarStyle({
    this.spacing,
    this.centerTextStyle,
    this.previousButtonStyle,
    this.nextButtonStyle,
    this.buttonsExpanded = true,
  });

  final double? spacing;
  final TextStyle? centerTextStyle;
  final ButtonStyle? previousButtonStyle;
  final ButtonStyle? nextButtonStyle;
  final bool buttonsExpanded;
}

/// Previous / center label / next actions for paged content inside a card.
class AppInlinePaginationBar extends StatelessWidget {
  const AppInlinePaginationBar({
    super.key,
    this.centerLabel,
    this.center,
    this.onPrevious,
    this.onNext,
    this.previousLabel = 'Pagina anterior',
    this.nextLabel = 'Proxima pagina',
    this.previousIcon,
    this.nextIcon,
    this.previousTooltip,
    this.nextTooltip,
    this.style = const AppInlinePaginationBarStyle(),
  });

  final String? centerLabel;
  final Widget? center;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String previousLabel;
  final String nextLabel;
  final Widget? previousIcon;
  final Widget? nextIcon;
  final String? previousTooltip;
  final String? nextTooltip;
  final AppInlinePaginationBarStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final spacing = style.spacing ?? tokens.gapMd;
    final centerWidget =
        center ??
        Text(
          centerLabel ?? '',
          style: style.centerTextStyle ?? theme.textTheme.labelLarge,
          textAlign: TextAlign.center,
        );

    final previousButton = OutlinedButton.icon(
      onPressed: onPrevious,
      icon: previousIcon ?? const Icon(Icons.chevron_left_rounded),
      style: style.previousButtonStyle,
      label: Text(previousLabel),
    );
    final nextButton = FilledButton.icon(
      onPressed: onNext,
      icon: nextIcon ?? const Icon(Icons.chevron_right_rounded),
      style: style.nextButtonStyle,
      label: Text(nextLabel),
    );

    return Row(
      children: <Widget>[
        ..._maybeExpand(
          style.buttonsExpanded,
          Tooltip(
            message: previousTooltip ?? previousLabel,
            child: previousButton,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Semantics(
            container: true,
            liveRegion: true,
            label: centerLabel,
            child: centerWidget,
          ),
        ),
        SizedBox(width: spacing),
        ..._maybeExpand(
          style.buttonsExpanded,
          Tooltip(
            message: nextTooltip ?? nextLabel,
            child: nextButton,
          ),
        ),
      ],
    );
  }

  List<Widget> _maybeExpand(bool shouldExpand, Widget child) {
    return shouldExpand ? <Widget>[Expanded(child: child)] : <Widget>[child];
  }
}
