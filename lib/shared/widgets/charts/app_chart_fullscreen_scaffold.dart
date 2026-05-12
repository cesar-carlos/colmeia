import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fullscreen chart shell: horizontal margin, default vertical body insets,
/// Escape to close (desktop/web), and tighter default vertical padding on
/// short viewports.
class AppChartFullscreenScaffold extends StatelessWidget {
  const AppChartFullscreenScaffold({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.filterSummary,
    this.headerTrailing,
    this.bodyPadding,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final String? filterSummary;
  final Widget? headerTrailing;
  final EdgeInsetsGeometry? bodyPadding;

  EdgeInsets _mergedBodyPadding(BuildContext context, AppThemeTokens tokens) {
    final mq = MediaQuery.maybeOf(context);
    final height = mq?.size.height ?? 0;
    final tightViewport = height.isFinite && height > 0 && height < 560;
    final defaults = EdgeInsets.only(
      top: tightViewport ? tokens.gapXs : tokens.gapSm,
      bottom: tightViewport ? tokens.gapSm : tokens.gapMd,
    );
    if (bodyPadding == null) {
      return defaults;
    }
    final custom = bodyPadding!.resolve(Directionality.of(context));
    return EdgeInsets.fromLTRB(
      custom.left,
      math.max(defaults.top, custom.top),
      custom.right,
      math.max(defaults.bottom, custom.bottom),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final l10n = AppLocalizations.of(context);
    final resolvedBodyPadding = _mergedBodyPadding(context, tokens);

    final resolvedTitle = title?.trim();
    final hasTitle = resolvedTitle != null && resolvedTitle.isNotEmpty;
    final resolvedSubtitle = subtitle?.trim();
    final hasSubtitle = resolvedSubtitle != null && resolvedSubtitle.isNotEmpty;
    final resolvedFilterSummary = filterSummary?.trim();
    final hasFilterSummary =
        resolvedFilterSummary != null && resolvedFilterSummary.isNotEmpty;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (Navigator.of(context).canPop()) {
            unawaited(Navigator.of(context).maybePop());
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.contentSpacing),
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: Navigator.of(context).canPop()
                  ? IconButton(
                      onPressed: () => unawaited(Navigator.of(context).maybePop()),
                      tooltip: l10n.chartCloseFullscreenTooltip,
                      icon: const Icon(Icons.close),
                    )
                  : null,
              titleSpacing: hasTitle || hasSubtitle || hasFilterSummary
                  ? tokens.gapSm
                  : 0,
              title: (hasTitle || hasSubtitle || hasFilterSummary)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (hasTitle)
                          Text(
                            resolvedTitle,
                            style: typography.sectionHeaderH2.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (hasSubtitle)
                          Text(
                            resolvedSubtitle,
                            style: typography.body,
                          ),
                        if (hasFilterSummary) ...<Widget>[
                          if (hasSubtitle || hasTitle)
                            SizedBox(height: tokens.gapXs),
                          Text(
                            resolvedFilterSummary,
                            style: typography.caption,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    )
                  : null,
              actions: switch (headerTrailing) {
                null => const <Widget>[],
                final Widget trailing => <Widget>[
                  trailing,
                  SizedBox(width: tokens.gapXs),
                ],
              },
            ),
            body: SafeArea(
              child: Padding(
                padding: resolvedBodyPadding,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
