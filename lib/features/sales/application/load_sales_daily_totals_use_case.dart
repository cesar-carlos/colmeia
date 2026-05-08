import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_complete_period.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/overview/data/mappers/overview_daily_sales_trend_mapper.dart';
import 'package:colmeia/features/overview/domain/entities/overview_daily_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';

typedef SalesDailyTotalsLoadResult = ({
  List<OverviewDailySalesTrendPoint> points,
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
    required OverviewYearMonth anchor,
    String? clientToken,
  }) async {
    final trimmedAgentId = agentId.trim();
    final start = anchor.start;
    final end = DateTime(anchor.year, anchor.month + 1, 0);
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
    );

    return result.fold(
      (rows) {
        final filled = ResumoTotalDiarioVendasCompletePeriod.fill(
          dataVendaInicio: start,
          dataVendaFim: end,
          rows: rows,
        );
        return (
          points: overviewDailySalesTrendPointsFromRows(filled),
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
          points: const <OverviewDailySalesTrendPoint>[],
          loadFailed: true,
          loadFailureMessage: failure.userMessage,
        );
      },
    );
  }
}
