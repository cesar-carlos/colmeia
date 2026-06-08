import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_filter_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fullscreen chart shell: full-screen background, default body insets, Escape
/// to close (desktop/web), and tighter default vertical padding on short
/// viewports.
class AppChartFullscreenScaffold extends StatelessWidget {
  const AppChartFullscreenScaffold({
    required this.child,
    super.key,
    this.header,
    this.title,
    this.subtitle,
    this.filterSummary,
    this.headerTrailing,
    this.bodyPadding,
  });

  final Widget child;
  final Widget? header;
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
    final l10n = AppLocalizations.of(context);
    final resolvedBodyPadding = _mergedBodyPadding(context, tokens);
    final bodyPaddingTop = resolvedBodyPadding.top;
    final bodyPaddingBottom = resolvedBodyPadding.bottom;

    final resolvedTitle = title?.trim();
    final hasTitle = resolvedTitle != null && resolvedTitle.isNotEmpty;
    final resolvedSubtitle = subtitle?.trim();
    final hasSubtitle = resolvedSubtitle != null && resolvedSubtitle.isNotEmpty;
    final resolvedFilterSummary = filterSummary?.trim();
    final hasFilterSummary =
        resolvedFilterSummary != null && resolvedFilterSummary.isNotEmpty;
    final resolvedHeader = header;
    final hasHeader =
        resolvedHeader != null || hasTitle || hasSubtitle || hasFilterSummary;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalInset = screenWidth < 600
        ? tokens.gapXs
        : tokens.contentSpacing;

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
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    onPressed: () =>
                        unawaited(Navigator.of(context).maybePop()),
                    tooltip: l10n.chartCloseFullscreenTooltip,
                    icon: const Icon(Icons.close),
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
              padding: EdgeInsets.fromLTRB(
                horizontalInset + resolvedBodyPadding.left,
                bodyPaddingTop,
                horizontalInset + resolvedBodyPadding.right,
                bodyPaddingBottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (hasHeader) ...<Widget>[
                    resolvedHeader ??
                        AppChartFullscreenHeader(
                          title: resolvedTitle,
                          subtitle: resolvedSubtitle,
                          filterSummary: resolvedFilterSummary,
                        ),
                    SizedBox(height: tokens.contentSpacing),
                  ],
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppChartFullscreenHeader extends StatelessWidget {
  const AppChartFullscreenHeader({
    required this.title,
    required this.subtitle,
    required this.filterSummary,
    super.key,
  });

  final String? title;
  final String? subtitle;
  final String? filterSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (title case final resolvedTitle?
            when resolvedTitle.trim().isNotEmpty)
          Text(
            resolvedTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.sectionHeaderH2.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        if (subtitle case final resolvedSubtitle?
            when resolvedSubtitle.trim().isNotEmpty) ...<Widget>[
          SizedBox(height: tokens.gapXs),
          Text(
            resolvedSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.body,
          ),
        ],
        if (filterSummary case final resolvedFilterSummary?
            when resolvedFilterSummary.trim().isNotEmpty) ...<Widget>[
          SizedBox(height: tokens.gapSm),
          _AppChartFullscreenFilterChips(
            summary: resolvedFilterSummary,
          ),
        ],
      ],
    );
  }
}

class _AppChartFullscreenFilterChips extends StatelessWidget {
  const _AppChartFullscreenFilterChips({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    final parts = AppChartFilterSummary.splitOnMiddleDot(summary);
    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }

    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Tooltip(
      message: summary,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (var index = 0; index < parts.length; index++) ...<Widget>[
              if (index > 0) SizedBox(width: tokens.gapXs),
              _AppChartFullscreenFilterChip(label: parts[index]),
            ],
          ],
        ),
      ),
    );
  }

}

class _AppChartFullscreenFilterChip extends StatelessWidget {
  const _AppChartFullscreenFilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapSm,
          vertical: tokens.gapXs,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
