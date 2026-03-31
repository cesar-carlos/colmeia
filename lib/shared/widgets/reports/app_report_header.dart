import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:flutter/material.dart';

/// Report header card with title, subtitle, context chips and optional
/// trailing widget (e.g. export button).
class AppReportHeader extends StatelessWidget {
  const AppReportHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.contextChips = const <String>[],
    this.trailing,
    this.color,
  });

  final String title;
  final String? subtitle;
  final List<String> contextChips;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;

    final hasChips = contextChips.isNotEmpty;
    final titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (title.isNotEmpty)
          Text(
            title,
            style: typography.sectionHeaderH2.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        if (subtitle != null) ...<Widget>[
          if (title.isNotEmpty) SizedBox(height: tokens.gapXs),
          Text(
            subtitle!,
            style: typography.body.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    return AppSectionCard(
      color: color,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showStackedHeader =
              trailing != null && constraints.maxWidth < 560;
          final trailingWidget = trailing;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (showStackedHeader) ...<Widget>[
                titleSection,
                SizedBox(height: tokens.gapMd),
                if (trailingWidget != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: trailingWidget,
                  ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: titleSection),
                    if (trailingWidget != null) ...<Widget>[
                      SizedBox(width: tokens.gapMd),
                      Flexible(child: trailingWidget),
                    ],
                  ],
                ),
              if (hasChips) ...<Widget>[
                SizedBox(height: tokens.gapSm),
                Wrap(
                  spacing: tokens.gapSm,
                  runSpacing: tokens.gapSm,
                  children: contextChips
                      .map((label) {
                        return AppTagChip(label: label);
                      })
                      .toList(growable: false),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
