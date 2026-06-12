import 'package:colmeia/shared/maps/app_location_lookup_normalizer.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_snapshot.dart';

class BrazilMapChartDesktopBranchSidebarFilterResult {
  const BrazilMapChartDesktopBranchSidebarFilterResult({
    required this.entries,
    required this.totalVisibleRevenue,
  });

  final List<AppBrazilStoreSalesVisibleBranchListItem> entries;
  final double totalVisibleRevenue;
}

String? brazilMapChartSidebarNormalizedSearchToken(String? value) {
  final normalized = AppLocationLookupNormalizer.normalizeAddressLine(value);
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

bool brazilMapChartSidebarEntriesEquivalent(
  List<AppBrazilStoreSalesVisibleBranchListItem> left,
  List<AppBrazilStoreSalesVisibleBranchListItem> right,
) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    final leftEntry = left[index];
    final rightEntry = right[index];
    if (leftEntry.id != rightEntry.id ||
        leftEntry.isSelected != rightEntry.isSelected ||
        leftEntry.state != rightEntry.state ||
        leftEntry.salesAmount != rightEntry.salesAmount) {
      return false;
    }
  }
  return true;
}

BrazilMapChartDesktopBranchSidebarFilterResult
filterBrazilMapChartSidebarEntries({
  required List<AppBrazilStoreSalesVisibleBranchListItem> entries,
  required String searchQuery,
}) {
  final normalizedQuery = brazilMapChartSidebarNormalizedSearchToken(
    searchQuery,
  );
  final filteredEntries = normalizedQuery == null
      ? entries
      : entries
            .where((entry) => entry.searchIndexText.contains(normalizedQuery))
            .toList(growable: false);
  final totalVisibleRevenue = filteredEntries.fold<double>(
    0,
    (sum, entry) => sum + entry.salesAmount,
  );
  return BrazilMapChartDesktopBranchSidebarFilterResult(
    entries: filteredEntries,
    totalVisibleRevenue: totalVisibleRevenue,
  );
}
