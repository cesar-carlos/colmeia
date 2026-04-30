import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

class AppChartFullscreenScaffold extends StatelessWidget {
  const AppChartFullscreenScaffold({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.headerTrailing,
    this.bodyPadding,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? headerTrailing;
  final EdgeInsetsGeometry? bodyPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final l10n = AppLocalizations.of(context);
    final resolvedBodyPadding = bodyPadding ?? EdgeInsets.zero;

    final resolvedTitle = title?.trim();
    final hasTitle = resolvedTitle != null && resolvedTitle.isNotEmpty;
    final resolvedSubtitle = subtitle?.trim();
    final hasSubtitle = resolvedSubtitle != null && resolvedSubtitle.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: l10n.chartCloseFullscreenTooltip,
                icon: const Icon(Icons.close),
              )
            : null,
        titleSpacing: hasTitle || hasSubtitle ? null : 0,
        title: (hasTitle || hasSubtitle)
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
    );
  }
}
