import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:flutter/material.dart';

enum AppInlineErrorPanelVariant {
  /// Full-width card surface (default for page-level errors).
  card,

  /// Same content without a card (e.g. inside a compact footer).
  plain,
}

/// Visual weight for [AppInlineErrorPanel] (error vs informational notice).
enum AppInlinePanelTone {
  /// Title uses the semantic error color (default).
  error,

  /// Title uses the primary brand color (non-destructive notices, e.g. cache).
  informational,
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
    this.tone = AppInlinePanelTone.error,
  });

  final String? title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final AppInlineErrorPanelVariant variant;
  final AppInlinePanelTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;
    final typography = theme.appTypography;

    final hasTitle = title?.trim().isNotEmpty ?? false;
    final titleColor = switch (tone) {
      AppInlinePanelTone.error => colors.error,
      AppInlinePanelTone.informational => colors.primary,
    };

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (hasTitle) ...<Widget>[
          Text(
            title!,
            style: typography.sectionHeaderH2.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.gapSm),
        ],
        Text(
          message,
          style: typography.body.copyWith(
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
