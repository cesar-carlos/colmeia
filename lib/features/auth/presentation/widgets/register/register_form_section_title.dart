import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

class RegisterFormSectionTitle extends StatelessWidget {
  const RegisterFormSectionTitle({
    required this.title,
    super.key,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.gapMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: typography.sectionHeaderH2.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle case final String resolvedSubtitle) ...<Widget>[
            SizedBox(height: tokens.gapXs),
            Text(
              resolvedSubtitle,
              style: typography.caption.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
