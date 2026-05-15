import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';

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
  final Set<String>? selectedBranchIds;
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
        : selectedBranchIds as Set<String>?;
    return SalesLiveMapFilter(
      selectedAgentIds: nextSelectedAgentIds == null
          ? null
          : Set<String>.unmodifiable(nextSelectedAgentIds),
      selectedBranchIds: nextSelectedBranchIds == null
          ? null
          : Set<String>.unmodifiable(nextSelectedBranchIds),
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
        .map(_branchRefFromId)
        .whereType<ResumoTotalVendasMunicipioFilialPeriodoBranchRef>()
        .toList(growable: false);
  }

  ResumoTotalVendasMunicipioFilialPeriodoBranchRef? _branchRefFromId(
    String raw,
  ) {
    final value = raw.trim();
    final lastDash = value.lastIndexOf('-');
    if (lastDash <= 0 || lastDash == value.length - 1) {
      return null;
    }
    final secondLastDash = value.lastIndexOf('-', lastDash - 1);
    if (secondLastDash <= 0 || secondLastDash == lastDash - 1) {
      return null;
    }

    final codEmpresa = int.tryParse(
      value.substring(secondLastDash + 1, lastDash),
    );
    final codFilial = int.tryParse(value.substring(lastDash + 1));
    final agentId = value.substring(0, secondLastDash).trim();
    if (agentId.isEmpty || codEmpresa == null || codFilial == null) {
      return null;
    }

    return ResumoTotalVendasMunicipioFilialPeriodoBranchRef(
      agentId: agentId,
      codEmpresa: codEmpresa,
      codFilial: codFilial,
    );
  }

  static DateTime _day(DateTime value) {
    return DateTime(value.year, value.month, value.day);
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
