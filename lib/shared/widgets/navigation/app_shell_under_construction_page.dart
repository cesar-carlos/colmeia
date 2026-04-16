import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppShellUnderConstructionPage extends StatelessWidget {
  const AppShellUnderConstructionPage({
    required this.sectionTitle,
    super.key,
  });

  final String sectionTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final theme = Theme.of(context);
    final semanticsLabel =
        '$sectionTitle, ${l10n.shellPlaceholderUnderConstructionTitle}';

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: SingleChildScrollView(
        padding: context.pageScrollPadding(tokens),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppShellPageIntro(
              sectionLabel: sectionTitle,
              title: l10n.shellPlaceholderUnderConstructionTitle,
              subtitle: l10n.shellPlaceholderUnderConstructionBody,
            ),
            SizedBox(height: tokens.sectionSpacing),
            AppSectionCard(
              child: Text(
                l10n.shellPlaceholderUnderConstructionBody,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
