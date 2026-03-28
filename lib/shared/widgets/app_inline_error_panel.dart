import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:flutter/material.dart';

/// Inline error surface with optional retry, aligned with app shell error UX.
class AppInlineErrorPanel extends StatelessWidget {
  const AppInlineErrorPanel({
    required this.message,
    super.key,
    this.title = 'Nao foi possivel carregar',
    this.onRetry,
    this.retryLabel = 'Tentar novamente',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return Semantics(
      container: true,
      liveRegion: true,
      child: AppSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: tokens.gapSm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface,
              ),
            ),
            if (onRetry != null) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              FilledButton(
                onPressed: onRetry,
                child: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
