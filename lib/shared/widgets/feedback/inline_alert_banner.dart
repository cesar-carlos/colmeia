import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Inline full-width message using [ColorScheme.errorContainer] styling.
class InlineAlertBanner extends StatelessWidget {
  const InlineAlertBanner({
    required this.message,
    super.key,
    this.icon = Icons.error_outline_rounded,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final radius = tokens?.inlineAlertCornerRadius ?? 12;

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: tokens?.formFieldPaddingHorizontal ?? 16,
          vertical: tokens?.gapMd ?? 12,
        ),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 18, color: cs.onErrorContainer),
            SizedBox(width: tokens?.gapSm ?? 8),
            Expanded(
              child: Text(
                message,
                style: tt.bodySmall?.copyWith(color: cs.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
