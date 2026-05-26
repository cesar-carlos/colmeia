import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Semantic variants accepted by [InlineAlertBanner].
///
/// Each kind maps to a `*Container` color from [ColorScheme] so banners
/// adapt to light/dark themes automatically. Use [InlineAlertBannerKind.error]
/// for validation failures (the historical default), [success] for
/// confirmations, [warning] for soft attention, [info] for tips, and
/// [neutral] for status read-outs without urgency.
enum InlineAlertBannerKind { error, success, warning, info, neutral }

/// Default icon size used by [InlineAlertBanner]; kept private so callers
/// do not depend on a magic number when subclassing or wrapping the widget.
const double _kInlineAlertIconSize = 18;

/// Inline full-width message styled from [ColorScheme] container roles.
///
/// Defaults to [InlineAlertBannerKind.error] so legacy call sites that only
/// pass `message` keep their previous error-container appearance.
class InlineAlertBanner extends StatelessWidget {
  const InlineAlertBanner({
    required this.message,
    super.key,
    this.title,
    this.kind = InlineAlertBannerKind.error,
    this.icon,
  });

  /// Optional bolded heading rendered above [message]. When provided, the
  /// row uses `CrossAxisAlignment.start` so the icon stays aligned with
  /// the heading rather than centered vertically across both lines.
  final String? title;
  final String message;
  final InlineAlertBannerKind kind;

  /// Overrides the icon implied by [kind]. Use sparingly — semantic kinds
  /// already carry an icon that matches their meaning across the app.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final radius = tokens?.inlineAlertCornerRadius ?? 12;
    final palette = _resolvePalette(cs);
    final resolvedIcon = icon ?? _defaultIconFor(kind);
    final hasTitle = title?.trim().isNotEmpty ?? false;
    final semanticsLabel = hasTitle ? '${title!}. $message' : message;

    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticsLabel,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: tokens?.formFieldPaddingHorizontal ?? 16,
          vertical: tokens?.gapMd ?? 12,
        ),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          crossAxisAlignment: hasTitle
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              resolvedIcon,
              size: _kInlineAlertIconSize,
              color: palette.foreground,
            ),
            SizedBox(width: tokens?.gapSm ?? 8),
            Expanded(
              child: hasTitle
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title!,
                          style: tt.titleSmall?.copyWith(
                            color: palette.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: tokens?.gapXs ?? 4),
                        Text(
                          message,
                          style: tt.bodySmall?.copyWith(
                            color: palette.foreground,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      message,
                      style: tt.bodySmall?.copyWith(color: palette.foreground),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  _InlineAlertPalette _resolvePalette(ColorScheme cs) {
    return switch (kind) {
      InlineAlertBannerKind.error => _InlineAlertPalette(
        background: cs.errorContainer,
        foreground: cs.onErrorContainer,
      ),
      InlineAlertBannerKind.success => _InlineAlertPalette(
        background: cs.primaryContainer,
        foreground: cs.onPrimaryContainer,
      ),
      InlineAlertBannerKind.warning => _InlineAlertPalette(
        background: cs.tertiaryContainer,
        foreground: cs.onTertiaryContainer,
      ),
      InlineAlertBannerKind.info => _InlineAlertPalette(
        background: cs.secondaryContainer,
        foreground: cs.onSecondaryContainer,
      ),
      InlineAlertBannerKind.neutral => _InlineAlertPalette(
        background: cs.surfaceContainerHighest,
        foreground: cs.onSurfaceVariant,
      ),
    };
  }

  IconData _defaultIconFor(InlineAlertBannerKind kind) {
    return switch (kind) {
      InlineAlertBannerKind.error => Icons.error_outline_rounded,
      InlineAlertBannerKind.success => Icons.check_circle_outline_rounded,
      InlineAlertBannerKind.warning => Icons.warning_amber_rounded,
      InlineAlertBannerKind.info => Icons.info_outline_rounded,
      InlineAlertBannerKind.neutral => Icons.help_outline_rounded,
    };
  }
}

class _InlineAlertPalette {
  const _InlineAlertPalette({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}
