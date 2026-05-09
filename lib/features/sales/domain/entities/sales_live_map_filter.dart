import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_diario_filter.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';

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

class SalesLiveMapFilter {
  const SalesLiveMapFilter({
    this.selectedAgentIds,
    this.periodMode = SalesLiveMapPeriodMode.today,
    this.customDateRange,
    this.mapPreset = SalesLiveMapMapPreset.standard,
  });

  final Set<String>? selectedAgentIds;
  final SalesLiveMapPeriodMode periodMode;
  final OverviewDateRange? customDateRange;
  final SalesLiveMapMapPreset mapPreset;

  SalesLiveMapFilter copyWith({
    Object? selectedAgentIds = _sentinel,
    SalesLiveMapPeriodMode? periodMode,
    Object? customDateRange = _sentinel,
    SalesLiveMapMapPreset? mapPreset,
  }) {
    final nextSelectedAgentIds = selectedAgentIds == _sentinel
        ? this.selectedAgentIds
        : selectedAgentIds as Set<String>?;
    return SalesLiveMapFilter(
      selectedAgentIds: nextSelectedAgentIds == null
          ? null
          : Set<String>.unmodifiable(nextSelectedAgentIds),
      periodMode: periodMode ?? this.periodMode,
      customDateRange: customDateRange == _sentinel
          ? this.customDateRange
          : customDateRange as OverviewDateRange?,
      mapPreset: mapPreset ?? this.mapPreset,
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

  ResumoTotalVendasMunicipioFilialDiarioFilter toAgentQueryFilter({
    DateTime? now,
  }) {
    final range = resolveDateRange(now: now);
    return ResumoTotalVendasMunicipioFilialDiarioFilter(
      dataVendaInicio: range.startInclusive,
      dataVendaFim: range.endInclusive,
    );
  }

  static DateTime _day(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

const Object _sentinel = Object();
