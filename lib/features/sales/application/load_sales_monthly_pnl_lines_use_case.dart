import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/overview/domain/overview_last_twelve_months_venda_range.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:flutter/foundation.dart';

typedef SalesMonthlyPnlLinesLoadResult = ({
  List<SalesMonthlyPnlPoint> points,
  bool loadFailed,
  String? loadFailureMessage,
});

class LoadSalesMonthlyPnlLinesUseCase {
  LoadSalesMonthlyPnlLinesUseCase(this._loadLucratividadeMensal);

  final LoadResumoProdutoVendaLucratividadeMensalUseCase
  _loadLucratividadeMensal;

  static const int bridgeTimeoutMs = 300000;

  Future<SalesMonthlyPnlLinesLoadResult> call({
    required String userId,
    required String agentId,
    required OverviewYearMonth anchor,
    String? clientToken,
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
    );

    return result.fold(
      (rows) => (
        points: _pointsFromRows(
          rows,
          start: last12.dataVendaInicio,
          end: last12.dataVendaFim,
        ),
        loadFailed: false,
        loadFailureMessage: null,
      ),
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
          loadFailureMessage: failure.userMessage,
        );
      },
    );
  }

  List<SalesMonthlyPnlPoint> _pointsFromRows(
    List<ResumoProdutoVendaLucratividadeMensalRow> rows, {
    required DateTime start,
    required DateTime end,
  }) {
    final totalsByMonth = <_YearMonthKey, _MonthlyPnlTotals>{};
    for (final row in rows) {
      final key = _YearMonthKey(year: row.ano, month: row.mes);
      totalsByMonth.putIfAbsent(key, _MonthlyPnlTotals.new)
        ..venda += row.valorTotalItem
        ..lucro += row.lucro
        ..custoMercadoria += row.custoReposicao;
    }

    final points = <SalesMonthlyPnlPoint>[];
    var year = start.year;
    var month = start.month;
    final endYear = end.year;
    final endMonth = end.month;

    while (year < endYear || (year == endYear && month <= endMonth)) {
      final key = _YearMonthKey(year: year, month: month);
      final totals = totalsByMonth[key];
      final anoMes =
          '${year.toString().padLeft(4, '0')}/'
          '${month.toString().padLeft(2, '0')}';
      points.add(
        SalesMonthlyPnlPoint(
          year: year,
          month: month,
          anoMes: anoMes,
          venda: totals?.venda ?? 0,
          lucro: totals?.lucro ?? 0,
          custoMercadoria: totals?.custoMercadoria ?? 0,
        ),
      );

      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }

    return points;
  }
}

@immutable
final class _YearMonthKey {
  const _YearMonthKey({
    required this.year,
    required this.month,
  });

  final int year;
  final int month;

  @override
  bool operator ==(Object other) =>
      other is _YearMonthKey && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

final class _MonthlyPnlTotals {
  double venda = 0;
  double lucro = 0;
  double custoMercadoria = 0;
}
