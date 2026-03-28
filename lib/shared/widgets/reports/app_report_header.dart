import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
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

    final hasChips = contextChips.isNotEmpty;

    return AppSectionCard(
      color: color,
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
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                SizedBox(width: tokens.gapMd),
                trailing!,
              ],
            ],
          ),
          if (hasChips) ...<Widget>[
            SizedBox(height: tokens.gapSm),
            Wrap(
              spacing: tokens.gapSm,
              runSpacing: tokens.gapSm,
              children: contextChips.map((label) {
                return Chip(
                  label: Text(label),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.symmetric(horizontal: tokens.gapSm),
                );
              }).toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}
