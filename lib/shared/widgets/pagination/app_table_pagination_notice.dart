import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

/// Compact footnote below paginated tables ("Pode haver mais linhas...").
class AppTablePaginationNotice extends StatelessWidget {
  const AppTablePaginationNotice({
    required this.message,
    super.key,
    this.visible = true,
    this.hideOnMobileWhenSinglePage = true,
    this.totalPages = 1,
  });

  final String message;
  final bool visible;

  /// When true, hides the note on mobile if [totalPages] is at most one.
  final bool hideOnMobileWhenSinglePage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    final isMobile = AppBreakpoints.isMobile(context);
    if (hideOnMobileWhenSinglePage && isMobile && totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final typography = theme.appTypography;
    final color = theme.colorScheme.onSurfaceVariant;
    final style = isMobile
        ? typography.utilityOverline.copyWith(
            letterSpacing: 0.1,
            fontSize: 10.5,
            height: 1.25,
            color: color.withValues(alpha: 0.92),
          )
        : typography.caption.copyWith(color: color);

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapXs),
      child: Text(
        message,
        style: style,
        maxLines: isMobile ? 2 : 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
