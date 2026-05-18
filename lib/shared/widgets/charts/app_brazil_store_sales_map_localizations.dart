import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';

abstract final class AppBrazilStoreSalesMapLocalizations {
  static List<AppMapScopeOption> regionScopeOptions(
    AppLocalizations l10n,
  ) => <AppMapScopeOption>[
    AppMapScopeOption(key: 'NO', label: l10n.brazilStoreSalesMapRegionNorth),
    AppMapScopeOption(
      key: 'NE',
      label: l10n.brazilStoreSalesMapRegionNortheast,
    ),
    AppMapScopeOption(
      key: 'CO',
      label: l10n.brazilStoreSalesMapRegionCenterWest,
    ),
    AppMapScopeOption(
      key: 'SE',
      label: l10n.brazilStoreSalesMapRegionSoutheast,
    ),
    AppMapScopeOption(key: 'SU', label: l10n.brazilStoreSalesMapRegionSouth),
  ];

  static String regionName(
    AppLocalizations l10n,
    String regionKey, {
    String? fallback,
  }) {
    return switch (regionKey) {
      'NO' => l10n.brazilStoreSalesMapRegionNorth,
      'NE' => l10n.brazilStoreSalesMapRegionNortheast,
      'CO' => l10n.brazilStoreSalesMapRegionCenterWest,
      'SE' => l10n.brazilStoreSalesMapRegionSoutheast,
      'SU' => l10n.brazilStoreSalesMapRegionSouth,
      _ => fallback ?? regionKey,
    };
  }

  static String presetLabel(
    AppLocalizations l10n,
    AppBrazilStoreSalesMapPreset preset,
  ) {
    return switch (preset) {
      AppBrazilStoreSalesMapPreset.standard =>
        l10n.brazilStoreSalesMapPresetStandardLabel,
      AppBrazilStoreSalesMapPreset.bubble =>
        l10n.brazilStoreSalesMapPresetBubbleLabel,
      AppBrazilStoreSalesMapPreset.municipalityBubbles =>
        l10n.brazilStoreSalesMapPresetMunicipalityBubblesLabel,
      AppBrazilStoreSalesMapPreset.stateBubbles =>
        l10n.brazilStoreSalesMapPresetStateBubblesLabel,
      AppBrazilStoreSalesMapPreset.storeIcon =>
        l10n.brazilStoreSalesMapPresetStoreIconLabel,
    };
  }

  static String presetTooltip(
    AppLocalizations l10n,
    AppBrazilStoreSalesMapPreset preset,
  ) {
    return switch (preset) {
      AppBrazilStoreSalesMapPreset.standard =>
        l10n.brazilStoreSalesMapPresetStandardTooltip,
      AppBrazilStoreSalesMapPreset.bubble =>
        l10n.brazilStoreSalesMapPresetBubbleTooltip,
      AppBrazilStoreSalesMapPreset.municipalityBubbles =>
        l10n.brazilStoreSalesMapPresetMunicipalityBubblesTooltip,
      AppBrazilStoreSalesMapPreset.stateBubbles =>
        l10n.brazilStoreSalesMapPresetStateBubblesTooltip,
      AppBrazilStoreSalesMapPreset.storeIcon =>
        l10n.brazilStoreSalesMapPresetStoreIconTooltip,
    };
  }
}

extension AppBrazilStoreSalesMapPresetLocalizationX
    on AppBrazilStoreSalesMapPreset {
  String localizedLabel(AppLocalizations l10n) {
    return AppBrazilStoreSalesMapLocalizations.presetLabel(l10n, this);
  }

  String localizedTooltip(AppLocalizations l10n) {
    return AppBrazilStoreSalesMapLocalizations.presetTooltip(l10n, this);
  }
}
