import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:flutter/material.dart';

class AppChartShell extends StatelessWidget {
  const AppChartShell({
    required this.child,
    super.key,
    this.title = '',
    this.titleWidget,
    this.subtitle,
    this.titleTrailing,
    this.onOpenFullscreen,
    this.openFullscreenTooltip,
    this.openFullscreenSemanticLabel,
    this.belowSubtitle,
    this.cardPadding,
  });

  /// Plain-text chart title. Shown as a styled [Text] unless [titleWidget]
  /// overrides it. Defaults to an empty string (no title shown).
  final String title;

  /// Optional rich-content widget that replaces the [title] [Text] visually.
  ///
  /// When provided, [title] is ignored for display but can still be kept for
  /// semantics or other purposes. [subtitle], [titleTrailing] and
  /// [belowSubtitle] continue to render alongside this widget.
  final Widget? titleWidget;

  final String? subtitle;
  final Widget child;

  /// e.g. link action aligned with the title block.
  final Widget? titleTrailing;

  /// Optional callback that shows an "expand to fullscreen" action in header.
  ///
  /// This keeps fullscreen affordance consistent across chart cards while
  /// preserving any custom [titleTrailing] already provided by call sites.
  final VoidCallback? onOpenFullscreen;

  /// Optional tooltip for the fullscreen action button.
  final String? openFullscreenTooltip;

  /// Optional semantics label for the fullscreen action button.
  final String? openFullscreenSemanticLabel;

  /// e.g. period [SegmentedButton] between subtitle and chart.
  final Widget? belowSubtitle;

  /// Optional [AppSectionCard] padding. When null, uses horizontal/top
  /// [AppThemeTokens.contentSpacing] and bottom [AppThemeTokens.gapMd].
  final EdgeInsetsGeometry? cardPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;

    final resolvedCardPadding =
        cardPadding ??
        EdgeInsets.fromLTRB(
          tokens.contentSpacing,
          tokens.contentSpacing,
          tokens.contentSpacing,
          tokens.gapMd,
        );

    return AppSectionCard(
      padding: resolvedCardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Builder(
            builder: (context) {
              final hasTitle = titleWidget != null || title.isNotEmpty;
              final headerText = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (hasTitle)
                    titleWidget ??
                        Text(
                          title,
                          style: typography.sectionHeaderH2.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                  if (subtitle != null) ...<Widget>[
                    SizedBox(height: tokens.gapXs),
                    Text(subtitle!, style: typography.body),
                  ],
                ],
              );

              final trailing = _resolveTrailing(context, tokens);
              if (trailing == null) {
                return headerText;
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: headerText),
                  SizedBox(width: tokens.gapSm),
                  trailing,
                ],
              );
            },
          ),
          SizedBox(height: tokens.contentSpacing),
          ...switch (belowSubtitle) {
            null => const <Widget>[],
            final Widget w => <Widget>[
              w,
              SizedBox(height: tokens.gapMd),
            ],
          },
          child,
        ],
      ),
    );
  }

  Widget? _resolveTrailing(BuildContext context, AppThemeTokens tokens) {
    final onExpand = onOpenFullscreen;
    if (onExpand == null) {
      return titleTrailing;
    }

    final l10n = AppLocalizations.of(context);
    final tooltip = openFullscreenTooltip ?? l10n.chartOpenFullscreenTooltip;
    final semanticsLabel =
        openFullscreenSemanticLabel ?? l10n.chartOpenFullscreenTooltip;

    Widget expandAction = IconButton(
      onPressed: onExpand,
      tooltip: tooltip,
      icon: const Icon(Icons.open_in_full),
    );
    final trimmedSemanticsLabel = semanticsLabel.trim();
    if (trimmedSemanticsLabel.isNotEmpty) {
      expandAction = Semantics(
        button: true,
        label: trimmedSemanticsLabel,
        child: expandAction,
      );
    }

    final trailing = titleTrailing;
    if (trailing == null) {
      return expandAction;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        trailing,
        SizedBox(width: tokens.gapXs),
        expandAction,
      ],
    );
  }
}
