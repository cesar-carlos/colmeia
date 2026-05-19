import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:flutter/foundation.dart';

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
    this.metric = AppBrazilStoreSalesMapMetric.revenue,
  });

  final Set<String>? selectedAgentIds;
  final Set<SalesLiveMapBranchRef>? selectedBranchIds;
  final SalesLiveMapPeriodMode periodMode;
  final OverviewDateRange? customDateRange;
  final SalesLiveMapMapDetail detailLevel;
  final SalesLiveMapMarkerVisual markerVisual;
  final AppBrazilStoreSalesMapMetric metric;

  SalesLiveMapFilter copyWith({
    Object? selectedAgentIds = _sentinel,
    Object? selectedBranchIds = _sentinel,
    SalesLiveMapPeriodMode? periodMode,
    Object? customDateRange = _sentinel,
    SalesLiveMapMapDetail? detailLevel,
    SalesLiveMapMarkerVisual? markerVisual,
    AppBrazilStoreSalesMapMetric? metric,
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
          : customDateRange as OverviewDateRange?,
      detailLevel: detailLevel ?? this.detailLevel,
      markerVisual: markerVisual ?? this.markerVisual,
      metric: metric ?? this.metric,
    );
  }

  OverviewDateRange resolveDateRange({DateTime? now}) {
    final current = _day(now ?? DateTime.now());
    return switch (periodMode) {
      SalesLiveMapPeriodMode.today => OverviewDateRange(
        startInclusive: current,
        endInclusive: current,
      ),
      SalesLiveMapPeriodMode.lastSevenDays => OverviewDateRange(
        startInclusive: current.subtract(const Duration(days: 6)),
        endInclusive: current,
      ),
      SalesLiveMapPeriodMode.currentMonth => OverviewDateRange(
        startInclusive: DateTime(current.year, current.month),
        endInclusive: current,
      ),
      SalesLiveMapPeriodMode.customRange =>
        (customDateRange ??
                OverviewDateRange(
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
        _setEquals(other.selectedAgentIds, selectedAgentIds) &&
        _setEquals(other.selectedBranchIds, selectedBranchIds) &&
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
    _orderedStringHash(selectedAgentIds),
    _orderedBranchHash(selectedBranchIds),
  );

  static bool _setEquals<T>(Set<T>? a, Set<T>? b) {
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null) {
      return a == null && b == null;
    }
    if (a.length != b.length) {
      return false;
    }
    for (final value in a) {
      if (!b.contains(value)) {
        return false;
      }
    }
    return true;
  }

  static int? _orderedStringHash(Set<String>? value) {
    if (value == null) {
      return null;
    }
    final sorted = value.toList(growable: false)..sort();
    return Object.hashAll(sorted);
  }

  static int? _orderedBranchHash(Set<SalesLiveMapBranchRef>? value) {
    if (value == null) {
      return null;
    }
    final sorted =
        value
            .map(
              (branchRef) =>
                  '${branchRef.agentId}:${branchRef.codEmpresa}:${branchRef.codFilial}',
            )
            .toList(growable: false)
          ..sort();
    return Object.hashAll(sorted);
  }
}

class SalesLiveMapBranchOption {
  const SalesLiveMapBranchOption({
    required this.id,
    required this.agentId,
    required this.agentName,
    required this.codEmpresa,
    required this.codFilial,
    required this.name,
    required this.city,
    required this.uf,
  });

  final String id;
  final String agentId;
  final String agentName;
  final int codEmpresa;
  final int codFilial;
  final String name;
  final String city;
  final String uf;

  SalesLiveMapBranchRef get branchRef => SalesLiveMapBranchRef(
    agentId: agentId,
    codEmpresa: codEmpresa,
    codFilial: codFilial,
  );

  String get subtitle =>
      '$city/$uf - Agente $agentName - Empresa $codEmpresa - Filial $codFilial';
}

class SalesLiveMapAgentOption {
  const SalesLiveMapAgentOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

const Object _sentinel = Object();
