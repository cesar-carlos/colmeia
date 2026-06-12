import 'package:colmeia/l10n/app_localizations.dart';

/// Accessibility label builder for Syncfusion region map surfaces.
abstract final class SyncfusionRegionMapSemantics {
  static String mapLabel({
    required AppLocalizations l10n,
    required String metricLabel,
    required int regionCount,
    required int markerCount,
    required int selectedIndex,
    required List<String> regionLabels,
    String? customSemanticsLabel,
  }) {
    final customLabel = customSemanticsLabel?.trim();
    if (customLabel != null && customLabel.isNotEmpty) {
      return customLabel;
    }

    final buffer = StringBuffer()
      ..write(l10n.regionMapTerritorialSemanticsLabel)
      ..write(' ')
      ..write(l10n.regionMapSemanticsMetricLabel(metricLabel))
      ..write(' ')
      ..write(l10n.regionMapSemanticsRegionCount(regionCount));
    if (markerCount > 0) {
      buffer
        ..write(' ')
        ..write(l10n.regionMapSemanticsMarkerCount(markerCount));
    }
    if (selectedIndex >= 0 && selectedIndex < regionLabels.length) {
      buffer
        ..write(' ')
        ..write(
          l10n.regionMapSemanticsSelectedRegion(regionLabels[selectedIndex]),
        );
    }

    return buffer.toString();
  }
}
