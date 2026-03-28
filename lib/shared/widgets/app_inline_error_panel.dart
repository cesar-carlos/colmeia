import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:flutter/material.dart';

enum AppInlineErrorPanelVariant {
  /// Full-width card surface (default for page-level errors).
  card,

  /// Same content without a card (e.g. inside a compact footer).
  plain,
}

/// Inline error surface with optional retry, aligned with app shell error UX.
class AppInlineErrorPanel extends StatelessWidget {
  const AppInlineErrorPanel({
    required this.message,
    super.key,
    this.title,
    this.onRetry,
    this.retryLabel = 'Tentar novamente',
    this.variant = AppInlineErrorPanelVariant.card,
  });

  final String? title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final AppInlineErrorPanelVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;

    final hasTitle = title?.trim().isNotEmpty ?? false;

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (hasTitle) ...<Widget>[
          Text(
            title!,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.gapSm),
        ],
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface,
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
    );

    return Semantics(
      container: true,
      liveRegion: true,
      child: switch (variant) {
        AppInlineErrorPanelVariant.card => AppSectionCard(child: content),
        AppInlineErrorPanelVariant.plain => content,
      },
    );
  }
}
