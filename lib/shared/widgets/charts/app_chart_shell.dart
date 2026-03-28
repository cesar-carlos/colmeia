import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:flutter/material.dart';

class AppChartShell extends StatelessWidget {
  const AppChartShell({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// e.g. link action aligned with the title block.
  final Widget? titleTrailing;

  /// e.g. period [SegmentedButton] between subtitle and chart.
  final Widget? belowSubtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      SizedBox(height: tokens.gapXs),
                      Text(subtitle!, style: theme.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
              ?titleTrailing,
            ],
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
