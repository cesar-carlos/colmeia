import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:flutter/foundation.dart';

/// Aggregates monthly lucratividade rows into chart points for the last-N-month
/// window (missing months filled with zeros when `rows` is non-empty).
abstract final class SalesMonthlyPnlPointsMapper {
  static List<SalesMonthlyPnlPoint> fromRows(
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
