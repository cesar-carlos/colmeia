import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/overview/domain/overview_last_twelve_months_venda_range.dart';
import 'package:colmeia/features/sales/application/sales_monthly_pnl_points_mapper.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';

typedef SalesMonthlyPnlLinesLoadResult = ({
  List<SalesMonthlyPnlPoint> points,
  bool loadFailed,
  AppFailure? loadFailure,
});

class LoadSalesMonthlyPnlLinesUseCase {
  LoadSalesMonthlyPnlLinesUseCase(this._loadLucratividadeMensal);

  final LoadResumoProdutoVendaLucratividadeMensalUseCase
  _loadLucratividadeMensal;

  static const int bridgeTimeoutMs = 300000;

  Future<SalesMonthlyPnlLinesLoadResult> call({
    required String userId,
    required String agentId,
    required DashboardYearMonth anchor,
    String? clientToken,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final trimmedAgentId = agentId.trim();
    final last12 = OverviewLast12MonthsVendaRange.fromPeriodEnd(anchor.end);
    final filter = ResumoProdutoVendaLucratividadeMensalFilter(
      dataVendaInicio: last12.dataVendaInicio,
      dataVendaFim: last12.dataVendaFim,
    );

    final result = await _loadLucratividadeMensal(
      userId: userId,
      agentId: trimmedAgentId,
      filter: filter,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      cancelScope: cancelScope,
    );

    return result.fold(
      (rows) {
        if (rows.isEmpty) {
          AppLogger.info(
            'Sales: monthly pnl query returned no rows',
            context: <String, Object?>{
              'operation': 'LoadSalesMonthlyPnlLinesUseCase',
              'agentId': trimmedAgentId,
              'dataVendaInicio': last12.dataVendaInicio.toIso8601String(),
              'dataVendaFim': last12.dataVendaFim.toIso8601String(),
            },
          );
          return (
            points: const <SalesMonthlyPnlPoint>[],
            loadFailed: false,
            loadFailure: null,
          );
        }
        return (
          points: SalesMonthlyPnlPointsMapper.fromRows(
            rows,
            start: last12.dataVendaInicio,
            end: last12.dataVendaFim,
          ),
          loadFailed: false,
          loadFailure: null,
        );
      },
      (failure) {
        AppLogger.warning(
          'Sales: monthly pnl query failed',
          context: <String, Object?>{
            'operation': 'LoadSalesMonthlyPnlLinesUseCase',
            'failureType': failure.runtimeType.toString(),
          },
          error: failure,
        );
        return (
          points: const <SalesMonthlyPnlPoint>[],
          loadFailed: true,
          loadFailure: failure,
        );
      },
    );
  }
}
