import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_user_initials.dart';
import 'package:flutter/material.dart';

class AppShellNavProfileCard extends StatelessWidget {
  const AppShellNavProfileCard({
    required this.name,
    required this.roleLabel,
    super.key,
  });

  final String name;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;

    return AppSectionCard(
      color: colors.surface,
      borderRadius: BorderRadius.circular(tokens.cardRadius),
      borderSide: BorderSide(
        color: colors.outlineVariant.withValues(alpha: 0.5),
      ),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.primary,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: colors.surfaceContainerHigh,
              foregroundColor: colors.onSurface,
              child: Text(
                appShellUserInitials(name),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(height: tokens.gapMd),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: tokens.gapXs),
          Text(
            roleLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
