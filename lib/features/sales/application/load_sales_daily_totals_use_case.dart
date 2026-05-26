import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_complete_period.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';
import 'package:colmeia/shared/data/charts/daily_sales_trend_point_mappers.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';

typedef SalesDailyTotalsLoadResult = ({
  List<DailySalesTrendPoint> points,
  bool loadFailed,
  String? loadFailureMessage,
});

class LoadSalesDailyTotalsUseCase {
  LoadSalesDailyTotalsUseCase(this._loadResumoTotalDiarioVendas);

  final LoadResumoTotalDiarioVendasUseCase _loadResumoTotalDiarioVendas;

  static const int bridgeTimeoutMs = 300000;

  Future<SalesDailyTotalsLoadResult> call({
    required String userId,
    required String agentId,
    required DashboardYearMonth anchor,
    DashboardDateRange? dailySaleDateRange,
    String? clientToken,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final trimmedAgentId = agentId.trim();
    final DateTime start;
    final DateTime end;
    if (dailySaleDateRange != null) {
      final r = dailySaleDateRange;
      start = DateTime(
        r.startInclusive.year,
        r.startInclusive.month,
        r.startInclusive.day,
      );
      end = DateTime(
        r.endInclusive.year,
        r.endInclusive.month,
        r.endInclusive.day,
      );
    } else {
      start = anchor.start;
      end = DateTime(anchor.year, anchor.month + 1, 0);
    }
    final filter = ResumoTotalDiarioVendasFilter(
      dataVendaInicio: start,
      dataVendaFim: end,
    );

    final result = await _loadResumoTotalDiarioVendas(
      userId: userId,
      agentId: trimmedAgentId,
      filter: filter,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      cancelScope: cancelScope,
    );

    return result.fold(
      (rows) {
        final filled = ResumoTotalDiarioVendasCompletePeriod.fill(
          dataVendaInicio: start,
          dataVendaFim: end,
          rows: rows,
        );
        return (
          points: dailySalesTrendPointsFromRows(filled),
          loadFailed: false,
          loadFailureMessage: null,
        );
      },
      (failure) {
        AppLogger.warning(
          'Sales: daily totals query failed',
          context: <String, Object?>{
            'operation': 'LoadSalesDailyTotalsUseCase',
            'failureType': failure.runtimeType.toString(),
          },
          error: failure,
        );
        return (
          points: const <DailySalesTrendPoint>[],
          loadFailed: true,
          loadFailureMessage: failure.userMessage,
        );
      },
    );
  }
}
