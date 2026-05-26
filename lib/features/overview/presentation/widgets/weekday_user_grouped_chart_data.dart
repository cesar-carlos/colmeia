import 'dart:math' as math;

import 'package:colmeia/features/overview/domain/entities/overview_weekday_user_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/overview_weekday_display_order.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/daily_sales_weekday_labels.dart';
import 'package:colmeia/shared/widgets/charts/comparison_bar_plot_floor.dart';

/// One cell in the weekday × user matrix for grouped column charts.
class WeekdayUserGroupedBarDatum {
  const WeekdayUserGroupedBarDatum({
    required this.weekdayCategoryLabel,
    required this.value,
    required this.plottedY,
    required this.salesCount,
    required this.salesAmount,
  });

  final String weekdayCategoryLabel;
  final num value;
  final num plottedY;
  final int salesCount;
  final double salesAmount;
}

/// Prepared side-by-side column series: one list of points per user (same X order).
class WeekdayUserGroupedChartModel {
  const WeekdayUserGroupedChartModel({
    required this.userNames,
    required this.seriesData,
    required this.weekdayCategoryLabels,
    this.combinedRemainingUsers = false,
  });

  /// Legend / tooltip labels (localized for the merged Others series).
  final List<String> userNames;
  final List<List<WeekdayUserGroupedBarDatum>> seriesData;
  final List<String> weekdayCategoryLabels;

  /// True when extra users were merged into the Others series.
  final bool combinedRemainingUsers;
}

/// Maximum simultaneous series (users); remainder are summed into \"Others\".
const int kWeekdayUserGroupedMaxSeries = 8;

const String _kWeekdayUserGroupedOthersSeriesKey =
    '__colmeia_weekday_user_grouped_others__';

List<String> overviewWeekdayCategoryLabels(AppLocalizations l10n) => <String>[
  for (final n in kOverviewApiWeekdayDisplayOrder)
    dailySalesWeekdayLabel(n, l10n),
];

/// Builds clustered column data: X = weekday only; one series per user.
WeekdayUserGroupedChartModel buildWeekdayUserGroupedChartModel({
  required List<OverviewWeekdayUserSalesTrendPoint> points,
  required AppLocalizations l10n,
  required bool useSalesCount,
  double minPlottedValueShareOfMax = 0.06,
}) {
  final labels = overviewWeekdayCategoryLabels(l10n);
  final dayCount = kOverviewApiWeekdayDisplayOrder.length;
  final indexByWeekday = <int, int>{
    for (var i = 0; i < dayCount; i++) kOverviewApiWeekdayDisplayOrder[i]: i,
  };

  final metricByUser = <String, List<num>>{};
  final countByUser = <String, List<int>>{};
  final amountByUser = <String, List<double>>{};
  void ensureUser(String name) {
    if (!metricByUser.containsKey(name)) {
      metricByUser[name] = List<num>.filled(dayCount, 0);
      countByUser[name] = List<int>.filled(dayCount, 0);
      amountByUser[name] = List<double>.filled(dayCount, 0);
    }
  }

  for (final p in points) {
    final name = p.userName.trim();
    final key = name.isEmpty ? '—' : name;
    final wi = indexByWeekday[p.weekdayNumber];
    if (wi == null) {
      continue;
    }
    ensureUser(key);
    final m = metricByUser[key]!;
    final c = countByUser[key]!;
    final a = amountByUser[key]!;
    final metric = useSalesCount ? p.salesCount : p.salesAmount;
    m[wi] = m[wi].toDouble() + metric;
    c[wi] = c[wi] + p.salesCount;
    a[wi] = a[wi] + p.salesAmount;
  }

  if (metricByUser.isEmpty) {
    return WeekdayUserGroupedChartModel(
      userNames: const <String>[],
      seriesData: const <List<WeekdayUserGroupedBarDatum>>[],
      weekdayCategoryLabels: labels,
    );
  }

  final scored = <({String key, double total})>[];
  for (final entry in metricByUser.entries) {
    var total = 0.0;
    for (final v in entry.value) {
      total += v.toDouble();
    }
    scored.add((key: entry.key, total: total));
  }
  scored.sort((a, b) {
    final byMetric = b.total.compareTo(a.total);
    if (byMetric != 0) {
      return byMetric;
    }
    return a.key.toLowerCase().compareTo(b.key.toLowerCase());
  });

  var combinedRemainingUsers = false;
  late final List<String> orderedInternalKeys;
  if (scored.length <= kWeekdayUserGroupedMaxSeries) {
    orderedInternalKeys = [for (final s in scored) s.key];
  } else {
    combinedRemainingUsers = true;
    final top = scored
        .take(kWeekdayUserGroupedMaxSeries - 1)
        .map((s) => s.key)
        .toList(growable: false);
    final tail = scored
        .skip(kWeekdayUserGroupedMaxSeries - 1)
        .map((s) => s.key)
        .toList(growable: false);

    metricByUser[_kWeekdayUserGroupedOthersSeriesKey] = List<num>.filled(
      dayCount,
      0,
    );
    countByUser[_kWeekdayUserGroupedOthersSeriesKey] = List<int>.filled(
      dayCount,
      0,
    );
    amountByUser[_kWeekdayUserGroupedOthersSeriesKey] = List<double>.filled(
      dayCount,
      0,
    );

    final om = metricByUser[_kWeekdayUserGroupedOthersSeriesKey]!;
    final oc = countByUser[_kWeekdayUserGroupedOthersSeriesKey]!;
    final oa = amountByUser[_kWeekdayUserGroupedOthersSeriesKey]!;

    for (final u in tail) {
      final mr = metricByUser[u]!;
      final cr = countByUser[u]!;
      final ar = amountByUser[u]!;
      for (var i = 0; i < dayCount; i++) {
        om[i] = om[i].toDouble() + mr[i].toDouble();
        oc[i] = oc[i] + cr[i];
        oa[i] = oa[i] + ar[i];
      }
      metricByUser.remove(u);
      countByUser.remove(u);
      amountByUser.remove(u);
    }
    orderedInternalKeys = <String>[...top, _kWeekdayUserGroupedOthersSeriesKey];
  }

  /// Weekday slots where at least one displayed series has a positive metric.
  final activeDayIndices = <int>[];
  for (var i = 0; i < dayCount; i++) {
    var anyPositive = false;
    for (final k in orderedInternalKeys) {
      if (metricByUser[k]![i].toDouble() > 0) {
        anyPositive = true;
        break;
      }
    }
    if (anyPositive) {
      activeDayIndices.add(i);
    }
  }

  final filteredLabels = <String>[
    for (final i in activeDayIndices) labels[i],
  ];

  var maxPositive = 0.0;
  for (final k in orderedInternalKeys) {
    for (final i in activeDayIndices) {
      final d = metricByUser[k]![i].toDouble();
      if (d > maxPositive) {
        maxPositive = d;
      }
    }
  }
  final denom = comparisonBarDenominatorForPlotFloor(maxPositive);
  final floor = denom * minPlottedValueShareOfMax;

  List<WeekdayUserGroupedBarDatum> seriesForUser(String userKey) {
    final raw = metricByUser[userKey]!;
    final counts = countByUser[userKey]!;
    final amounts = amountByUser[userKey]!;
    return List<WeekdayUserGroupedBarDatum>.generate(
      activeDayIndices.length,
      (j) {
        final i = activeDayIndices[j];
        final v = raw[i];
        final vd = v.toDouble();
        final plotted = vd > 0 && vd < floor ? floor : vd;
        return WeekdayUserGroupedBarDatum(
          weekdayCategoryLabel: labels[i],
          value: v,
          plottedY: plotted,
          salesCount: counts[i],
          salesAmount: amounts[i],
        );
      },
      growable: false,
    );
  }

  final othersLabel = l10n.overviewWeekdayUserGroupedOthersLabel;
  final displayNames = orderedInternalKeys
      .map(
        (k) => k == _kWeekdayUserGroupedOthersSeriesKey ? othersLabel : k,
      )
      .toList(growable: false);

  return WeekdayUserGroupedChartModel(
    userNames: displayNames,
    seriesData: [
      for (final k in orderedInternalKeys) seriesForUser(k),
    ],
    weekdayCategoryLabels: filteredLabels,
    combinedRemainingUsers: combinedRemainingUsers,
  );
}

/// Flattened metric values for spread / debug helpers.
List<num> weekdayUserGroupedFlatValues(WeekdayUserGroupedChartModel model) {
  final out = <num>[];
  for (final series in model.seriesData) {
    for (final d in series) {
      out.add(d.value);
    }
  }
  return out;
}

String truncateLegendUserName(String name, {int maxChars = 22}) {
  final t = name.trim();
  if (t.length <= maxChars) {
    return t;
  }
  final cap = math.max(4, maxChars - 1);
  return '${t.substring(0, cap)}\u2026';
}
