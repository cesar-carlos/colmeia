import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:flutter/material.dart';

class SalesHubCard extends StatelessWidget {
  const SalesHubCard({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final colors = theme.appColors;
    final typography = theme.appTypography;

    return AspectRatio(
      aspectRatio: 1.15,
      child: AppSectionCard(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(tokens.cardRadius),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.gapSm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: Icon(
                          icon,
                          size: 24,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.gapMd),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
