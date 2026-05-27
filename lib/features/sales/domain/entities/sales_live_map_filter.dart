import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_metric.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/utils/app_unordered_set_equality.dart';
import 'package:flutter/foundation.dart';

export 'package:colmeia/features/sales/domain/entities/sales_live_map_agent_option.dart';
export 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_option.dart';

const int kSalesLiveMapMaxCustomRangeInclusiveDays = 31;
const String kSalesLiveMapDefaultOrigem = 'FrenteLoja';
const String kSalesLiveMapDefaultGeraFinanceiro = 'S';
const String kSalesLiveMapDefaultPreVenda = 'N';

enum SalesLiveMapPeriodMode {
  today,
  lastSevenDays,
  currentMonth,
  customRange,
}

enum SalesLiveMapMapPreset {
  standard,
  bubble,
  municipalities,
  stateBubbles,
  storeIcon,
}

enum SalesLiveMapMapDetail {
  branches,
  municipalities,
  states,
}

enum SalesLiveMapMarkerVisual {
  dot,
  bubble,
  storeIcon,
}

@immutable
class SalesLiveMapFilter {
  const SalesLiveMapFilter({
    this.selectedAgentIds,
    this.selectedBranchIds,
    this.periodMode = SalesLiveMapPeriodMode.today,
    this.customDateRange,
    this.detailLevel = SalesLiveMapMapDetail.branches,
    this.markerVisual = SalesLiveMapMarkerVisual.dot,
    this.metric = SalesLiveMapMetric.revenue,
  });

  final Set<String>? selectedAgentIds;
  final Set<SalesLiveMapBranchRef>? selectedBranchIds;
  final SalesLiveMapPeriodMode periodMode;
  final DashboardDateRange? customDateRange;
  final SalesLiveMapMapDetail detailLevel;
  final SalesLiveMapMarkerVisual markerVisual;
  final SalesLiveMapMetric metric;

  SalesLiveMapFilter copyWith({
    Object? selectedAgentIds = _sentinel,
    Object? selectedBranchIds = _sentinel,
    SalesLiveMapPeriodMode? periodMode,
    Object? customDateRange = _sentinel,
    SalesLiveMapMapDetail? detailLevel,
    SalesLiveMapMarkerVisual? markerVisual,
    SalesLiveMapMetric? metric,
  }) {
    final nextSelectedAgentIds = selectedAgentIds == _sentinel
        ? this.selectedAgentIds
        : selectedAgentIds as Set<String>?;
    final nextSelectedBranchIds = selectedBranchIds == _sentinel
        ? this.selectedBranchIds
        : selectedBranchIds as Set<SalesLiveMapBranchRef>?;
    return SalesLiveMapFilter(
      selectedAgentIds: nextSelectedAgentIds == null
          ? null
          : Set<String>.unmodifiable(nextSelectedAgentIds),
      selectedBranchIds: nextSelectedBranchIds == null
          ? null
          : Set<SalesLiveMapBranchRef>.unmodifiable(nextSelectedBranchIds),
      periodMode: periodMode ?? this.periodMode,
      customDateRange: customDateRange == _sentinel
          ? this.customDateRange
          : customDateRange as DashboardDateRange?,
      detailLevel: detailLevel ?? this.detailLevel,
      markerVisual: markerVisual ?? this.markerVisual,
      metric: metric ?? this.metric,
    );
  }

  DashboardDateRange resolveDateRange({DateTime? now}) {
    final current = _day(now ?? DateTime.now());
    return switch (periodMode) {
      SalesLiveMapPeriodMode.today => DashboardDateRange(
        startInclusive: current,
        endInclusive: current,
      ),
      SalesLiveMapPeriodMode.lastSevenDays => DashboardDateRange(
        startInclusive: current.subtract(const Duration(days: 6)),
        endInclusive: current,
      ),
      SalesLiveMapPeriodMode.currentMonth => DashboardDateRange(
        startInclusive: DateTime(current.year, current.month),
        endInclusive: current,
      ),
      SalesLiveMapPeriodMode.customRange =>
        (customDateRange ??
                DashboardDateRange(
                  startInclusive: current,
                  endInclusive: current,
                ))
            .clampedToMaxInclusiveCalendarDays(
              kSalesLiveMapMaxCustomRangeInclusiveDays,
            ),
    };
  }

  ResumoTotalVendasMunicipioFilialPeriodoFilter toAgentQueryFilter({
    DateTime? now,
    int? codEmpresa,
    int? codFilial,
  }) {
    final range = resolveDateRange(now: now);
    return ResumoTotalVendasMunicipioFilialPeriodoFilter(
      dataVendaInicio: range.startInclusive,
      dataVendaFim: range.endInclusive,
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      selectedBranches: _selectedBranchRefs(),
    );
  }

  List<ResumoTotalVendasMunicipioFilialPeriodoBranchRef> _selectedBranchRefs() {
    final selected = selectedBranchIds;
    if (selected == null || selected.isEmpty) {
      return const <ResumoTotalVendasMunicipioFilialPeriodoBranchRef>[];
    }

    return selected
        .map((branchRef) => branchRef.toAgentQueryBranchRef())
        .toList(growable: false);
  }

  static DateTime _day(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SalesLiveMapFilter &&
        appSetEquals(other.selectedAgentIds, selectedAgentIds) &&
        appSetEquals(other.selectedBranchIds, selectedBranchIds) &&
        other.periodMode == periodMode &&
        other.customDateRange == customDateRange &&
        other.detailLevel == detailLevel &&
        other.markerVisual == markerVisual &&
        other.metric == metric;
  }

  @override
  int get hashCode => Object.hash(
    periodMode,
    customDateRange,
    detailLevel,
    markerVisual,
    metric,
    appOrderedSetHash<String>(selectedAgentIds, _identityKey),
    appOrderedSetHash<SalesLiveMapBranchRef>(selectedBranchIds, _branchRefKey),
  );

  static String _identityKey(String value) => value;

  static String _branchRefKey(SalesLiveMapBranchRef branchRef) =>
      '${branchRef.agentId}:${branchRef.codEmpresa}:${branchRef.codFilial}';
}

const Object _sentinel = Object();
