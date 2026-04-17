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
          LayoutBuilder(
            builder: (context, constraints) {
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

              final trailing = titleTrailing;
              if (trailing == null) {
                return headerText;
              }

              final useCompactHeader = constraints.maxWidth < 420;
              if (useCompactHeader) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    headerText,
                    SizedBox(height: tokens.gapSm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: trailing,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: headerText),
                  SizedBox(width: tokens.gapSm),
                  Flexible(child: trailing),
                ],
              );
            },
          ),
          SizedBox(height: tokens.contentSpacing),
          ...switch (belowSubtitle) {
            null => const <Widget>[],
            final Widget w => <Widget>[
              w,
              SizedBox(height: tokens.contentSpacing),
            ],
          },
          child,
        ],
      ),
    );
  }
}
