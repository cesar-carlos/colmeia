import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_chart_widgets.dart';
import 'package:flutter/material.dart';

Widget buildSyncfusionRegionMapLoadingState({
  required BuildContext context,
  required double height,
  required Color mapBackground,
  required BorderRadius mapBorderRadius,
  required String loadingLabel,
  required Color indicatorColor,
}) {
  final colors = Theme.of(context).appColors;
  final tokens = Theme.of(context).extension<AppThemeTokens>()!;

  return SyncfusionRegionMapSurface(
    height: height,
    background: mapBackground,
    borderRadius: mapBorderRadius,
    child: Center(
      child: Semantics(
        label: loadingLabel,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: indicatorColor,
              ),
            ),
            SizedBox(height: tokens.gapMd),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.gapMd),
              child: Text(
                loadingLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildSyncfusionRegionMapEmptyPlaceholderState({
  required BuildContext context,
  required double height,
  required Color mapBackground,
  required BorderRadius mapBorderRadius,
  required Widget placeholder,
}) {
  return SyncfusionRegionMapSurface(
    height: height,
    background: mapBackground,
    borderRadius: mapBorderRadius,
    child: Center(child: placeholder),
  );
}

Widget buildSyncfusionRegionMapDefaultEmptyState({
  required BuildContext context,
  required double height,
  required Color mapBackground,
  required BorderRadius mapBorderRadius,
  required String emptyLabel,
}) {
  final colors = Theme.of(context).appColors;
  final tokens = Theme.of(context).extension<AppThemeTokens>()!;

  return SyncfusionRegionMapSurface(
    height: height,
    background: mapBackground,
    borderRadius: mapBorderRadius,
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.gapMd * 2),
        child: Semantics(
          label: emptyLabel,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.map_outlined,
                size: 40,
                color: colors.onSurfaceVariant,
              ),
              SizedBox(height: tokens.gapMd),
              Text(
                emptyLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Resolves map chrome colors shared by loading/empty/content states.
({Color background, BorderRadius borderRadius, double height})
resolveSyncfusionRegionMapChrome({
  required BuildContext context,
  required AppChartTheme chartTheme,
  required double? styleHeight,
}) {
  final tokens = Theme.of(context).extension<AppThemeTokens>()!;
  return (
    background: Theme.of(
      context,
    ).colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
    borderRadius: BorderRadius.circular(tokens.cardRadius),
    height: styleHeight ?? chartTheme.height,
  );
}

String resolveSyncfusionRegionMapLoadingLabel({
  required AppLocalizations l10n,
  required String? styleMessage,
}) {
  return styleMessage ?? l10n.regionMapLoadingMessage;
}

String resolveSyncfusionRegionMapEmptyLabel({
  required AppLocalizations l10n,
  required String? styleMessage,
}) {
  return styleMessage ?? l10n.regionMapEmptyStateMessage;
}
