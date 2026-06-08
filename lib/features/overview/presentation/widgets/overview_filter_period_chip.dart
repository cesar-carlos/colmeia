import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
final class OverviewFilterPeriodChipData {
  const OverviewFilterPeriodChipData({
    required this.startYmd,
    required this.endYmd,
    required this.hasCustomRange,
  });

  final int startYmd;
  final int endYmd;
  final bool hasCustomRange;

  static int packYmd(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  static OverviewFilterPeriodChipData? fromOverview({
    required Overview? overview,
    required DashboardFilter filter,
  }) {
    if (overview == null) {
      return null;
    }
    return OverviewFilterPeriodChipData(
      startYmd: packYmd(overview.periodStart),
      endYmd: packYmd(overview.periodEnd),
      hasCustomRange: filter.referenceRange != null,
    );
  }

  String label(AppLocalizations l10n) {
    final start = DateTime(
      startYmd ~/ 10000,
      (startYmd % 10000) ~/ 100,
      startYmd % 100,
    );
    final end = DateTime(
      endYmd ~/ 10000,
      (endYmd % 10000) ~/ 100,
      endYmd % 100,
    );
    final dates =
        '${AppBrFormatters.shortDate(start)} – ${AppBrFormatters.shortDate(end)}';
    if (hasCustomRange) {
      return '${l10n.overviewPeriodTagCustomRangePrefix}: $dates';
    }
    return dates;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OverviewFilterPeriodChipData &&
          startYmd == other.startYmd &&
          endYmd == other.endYmd &&
          hasCustomRange == other.hasCustomRange);

  @override
  int get hashCode => Object.hash(startYmd, endYmd, hasCustomRange);
}

class OverviewFilterPeriodChip extends StatelessWidget {
  const OverviewFilterPeriodChip({
    required this.data,
    super.key,
  });

  final OverviewFilterPeriodChipData? data;

  @override
  Widget build(BuildContext context) {
    final period = data;
    if (period == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return AppTagChip(
      label: period.label(l10n),
      icon: Icons.calendar_today_outlined,
    );
  }
}
