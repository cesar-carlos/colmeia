import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:flutter/material.dart';

List<Widget> _paginationBarMaybeExpand(bool shouldExpand, Widget child) {
  return shouldExpand ? <Widget>[Expanded(child: child)] : <Widget>[child];
}

class AppInlinePaginationBarStyle {
  const AppInlinePaginationBarStyle({
    this.spacing,
    this.centerTextStyle,
    this.previousButtonStyle,
    this.nextButtonStyle,
    this.buttonsExpanded = true,
    this.centerLiveRegion = false,
  });

  final double? spacing;
  final TextStyle? centerTextStyle;
  final ButtonStyle? previousButtonStyle;
  final ButtonStyle? nextButtonStyle;
  final bool buttonsExpanded;

  /// When true, the center region is exposed as an accessibility live region.
  /// Prefer false unless the center text updates in place and should be
  /// announced on each change (can be noisy for screen readers).
  final bool centerLiveRegion;
}

/// Previous / center label / next actions for paged content inside a card.
class AppInlinePaginationBar extends StatelessWidget {
  AppInlinePaginationBar({
    super.key,
    this.centerLabel,
    this.center,
    this.centerSemanticsLabel,
    this.onPrevious,
    this.onNext,
    this.previousLabel = 'Pagina anterior',
    this.nextLabel = 'Proxima pagina',
    this.previousIcon,
    this.nextIcon,
    this.previousTooltip,
    this.nextTooltip,
    this.style = const AppInlinePaginationBarStyle(),
  }) : assert(
         center != null || (centerLabel != null && centerLabel.isNotEmpty),
         'Provide center or a non-empty centerLabel.',
       ),
       assert(
         center == null ||
             centerSemanticsLabel != null ||
             (centerLabel != null && centerLabel.isNotEmpty),
         'When using center, provide centerSemanticsLabel or centerLabel for '
         'accessibility.',
       );

  final String? centerLabel;
  final Widget? center;

  /// Overrides the accessibility label for the center region when [center] is
  /// a custom widget. Ignored when only [centerLabel] is used (label is used).
  final String? centerSemanticsLabel;
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
          centerLabel!,
          style: style.centerTextStyle ?? theme.textTheme.labelLarge,
          textAlign: TextAlign.center,
        );

    final resolvedCenterSemantics = centerSemanticsLabel ?? centerLabel;

    final labeledCenter = Semantics(
      container: true,
      liveRegion: style.centerLiveRegion,
      label: resolvedCenterSemantics,
      child: centerWidget,
    );

    final previousButton = Tooltip(
      message: previousTooltip ?? previousLabel,
      child: AppSecondaryButton(
        onPressed: onPrevious,
        label: previousLabel,
        icon: previousIcon ?? const Icon(Icons.chevron_left_rounded),
        style: style.previousButtonStyle,
        semanticsLabel: previousTooltip ?? previousLabel,
        fillWidth: style.buttonsExpanded,
      ),
    );

    final nextButton = Tooltip(
      message: nextTooltip ?? nextLabel,
      child: AppPrimaryButton(
        onPressed: onNext,
        label: nextLabel,
        icon: nextIcon ?? const Icon(Icons.chevron_right_rounded),
        style: style.nextButtonStyle,
        semanticsLabel: nextTooltip ?? nextLabel,
        fillWidth: style.buttonsExpanded,
      ),
    );

    if (AppBreakpoints.isMobile(context)) {
      return _MobilePaginationLayout(
        spacing: spacing,
        buttonsExpanded: style.buttonsExpanded,
        center: labeledCenter,
        previousButton: previousButton,
        nextButton: nextButton,
      );
    }

    return Row(
      children: <Widget>[
        ..._paginationBarMaybeExpand(style.buttonsExpanded, previousButton),
        SizedBox(width: spacing),
        Expanded(child: labeledCenter),
        SizedBox(width: spacing),
        ..._paginationBarMaybeExpand(style.buttonsExpanded, nextButton),
      ],
    );
  }
}

class _MobilePaginationLayout extends StatelessWidget {
  const _MobilePaginationLayout({
    required this.spacing,
    required this.buttonsExpanded,
    required this.center,
    required this.previousButton,
    required this.nextButton,
  });

  final double spacing;
  final bool buttonsExpanded;
  final Widget center;
  final Widget previousButton;
  final Widget nextButton;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        center,
        SizedBox(height: spacing),
        Row(
          children: <Widget>[
            ..._paginationBarMaybeExpand(buttonsExpanded, previousButton),
            SizedBox(width: spacing),
            ..._paginationBarMaybeExpand(buttonsExpanded, nextButton),
          ],
        ),
      ],
    );
  }
}
