import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/utils/app_branch_display_model.dart';
import 'package:colmeia/shared/utils/app_branch_display_name.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_chart_visual_snapshot.dart';
import 'package:flutter/material.dart';

String brazilMapChartFormatMetricValue(
  BuildContext context,
  AppBrazilStoreSalesMapMetric metric,
  num value,
) {
  return switch (metric) {
    AppBrazilStoreSalesMapMetric.revenue => AppBrFormatters.compactCurrency(
      value,
    ),
    AppBrazilStoreSalesMapMetric.salesCount => brazilMapChartFormatSalesCount(
      context,
      value,
    ),
  };
}

String brazilMapChartMetricShortLabel(
  AppLocalizations l10n,
  AppBrazilStoreSalesMapMetric metric,
) {
  return switch (metric) {
    AppBrazilStoreSalesMapMetric.revenue =>
      l10n.brazilStoreSalesMapMetricRevenueShort,
    AppBrazilStoreSalesMapMetric.salesCount =>
      l10n.brazilStoreSalesMapMetricSalesShort,
  };
}

String brazilMapCityLabelFor(AppBrazilStoreSalesPoint point) {
  return switch (point.city) {
    final city? when city.trim().isNotEmpty =>
      '${city.trim()} / ${AppBrazilStoreSalesMapData.normalizeUf(point.uf)}',
    _ => AppBrazilStoreSalesMapData.normalizeUf(point.uf),
  };
}

Alignment brazilMapFollowerAnchorFor({
  required double screenWidth,
  required double maxWidth,
  required double? markerGlobalDx,
}) {
  final markerDx = markerGlobalDx;
  if (markerDx == null) {
    return Alignment.bottomCenter;
  }

  const margin = 16.0;
  final halfWidth = maxWidth / 2;
  if (markerDx < halfWidth + margin) {
    return Alignment.bottomLeft;
  }
  if (markerDx > screenWidth - halfWidth - margin) {
    return Alignment.bottomRight;
  }
  return Alignment.bottomCenter;
}

Offset brazilMapFollowerOffsetFor(Alignment followerAnchor) {
  if (followerAnchor == Alignment.bottomLeft) {
    return const Offset(8, -10);
  }
  if (followerAnchor == Alignment.bottomRight) {
    return const Offset(-8, -10);
  }
  return const Offset(0, -10);
}

List<AppBrazilStoreSalesPoint> brazilMapOrderedBranchPoints(
  AppBrazilStoreSalesMarkerGroup group, {
  required String? initialStoreId,
}) {
  final selected = <AppBrazilStoreSalesPoint>[];
  final remaining = <AppBrazilStoreSalesPoint>[];

  for (final point in group.points) {
    if (initialStoreId != null && point.id == initialStoreId) {
      selected.add(point);
    } else {
      remaining.add(point);
    }
  }

  remaining.sort(_compareBrazilMapBranchPoints);
  return <AppBrazilStoreSalesPoint>[...selected, ...remaining];
}

int _compareBrazilMapBranchPoints(
  AppBrazilStoreSalesPoint left,
  AppBrazilStoreSalesPoint right,
) {
  final amount = right.salesAmount.compareTo(left.salesAmount);
  if (amount != 0) {
    return amount;
  }

  final salesCount = right.salesCount.compareTo(left.salesCount);
  if (salesCount != 0) {
    return salesCount;
  }

  return brazilMapBranchOrdinalName(left).compareTo(
    brazilMapBranchOrdinalName(right),
  );
}

String brazilMapBranchOrdinalName(AppBrazilStoreSalesPoint point) {
  return brazilMapBranchDisplayModel(point).primaryName;
}

String brazilMapBranchDisplayNameUi(
  BuildContext context,
  AppBrazilStoreSalesPoint point,
) {
  return resolveAppBranchDisplayModel(
    registrationName: point.branchName,
    fantasyName: point.fantasyName,
    fallbackName:
        brazilMapTrimmedOrNull(point.name) ??
        AppLocalizations.of(context).brazilStoreSalesMapDefaultBranchName,
  ).primaryName;
}

String? brazilMapBranchNameLabel(AppBrazilStoreSalesPoint point) {
  return brazilMapBranchDisplayModel(point).secondaryName;
}

AppBranchDisplayModel brazilMapBranchDisplayModel(
  AppBrazilStoreSalesPoint point,
) {
  return resolveAppBranchDisplayModel(
    registrationName: point.branchName,
    fantasyName: point.fantasyName,
    fallbackName: brazilMapTrimmedOrNull(point.name) ?? point.id,
  );
}

String brazilMapAgentChipLabel(AppLocalizations l10n, String agentName) {
  return l10n.brazilStoreSalesMapAgentChipWithName(
    appBranchDisplayName(agentName),
  );
}

String? brazilMapTrimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String brazilMapLocationResolutionLabel(
  AppLocalizations l10n,
  AppBrazilStoreSalesLocationResolution? resolution,
) {
  return switch (resolution) {
    AppBrazilStoreSalesLocationResolution.providedGeoPoint =>
      l10n.brazilStoreSalesMapLocationProvidedGeoPoint,
    AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode =>
      l10n.brazilStoreSalesMapLocationIbge,
    AppBrazilStoreSalesLocationResolution.cep =>
      l10n.brazilStoreSalesMapLocationCep,
    AppBrazilStoreSalesLocationResolution.cityUf =>
      l10n.brazilStoreSalesMapLocationCityUf,
    AppBrazilStoreSalesLocationResolution.capitalUf =>
      l10n.brazilStoreSalesMapLocationCapitalUf,
    AppBrazilStoreSalesLocationResolution.stateUf =>
      l10n.brazilStoreSalesMapLocationStateUf,
    null => l10n.brazilStoreSalesMapLocationUnknown,
  };
}
